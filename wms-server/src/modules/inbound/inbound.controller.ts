import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// 生成入库单号
function genInboundNo(): string {
  const now = new Date();
  const ts = now.getFullYear().toString() +
    String(now.getMonth() + 1).padStart(2, '0') +
    String(now.getDate()).padStart(2, '0') +
    String(now.getHours()).padStart(2, '0') +
    String(now.getMinutes()).padStart(2, '0') +
    String(now.getSeconds()).padStart(2, '0');
  return 'IN' + ts;
}

// 入库单列表
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, status = '', type = '', keyword = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = `SELECT o.*, s.name as supplier_name, w.name as warehouse_name, u.real_name as operator_name
               FROM inbound_orders o
               LEFT JOIN suppliers s ON o.supplier_id=s.id
               LEFT JOIN warehouses w ON o.warehouse_id=w.id
               LEFT JOIN users u ON o.operator_id=u.id WHERE 1=1`;
    const params: any[] = [];
    if (status) { sql += ' AND o.status=?'; params.push(status); }
    if (type) { sql += ' AND o.type=?'; params.push(type); }
    if (keyword) { sql += ' AND o.order_no LIKE ?'; params.push(`%${keyword}%`); }
    sql += ' ORDER BY o.id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);

    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM inbound_orders');
    const total = count[0].total;

    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 入库单详情
router.get('/:id', async (req: AuthRequest, res: any) => {
  try {
    const [orders]: any = await pool.query(
      `SELECT o.*, s.name as supplier_name, w.name as warehouse_name, u.real_name as operator_name
       FROM inbound_orders o LEFT JOIN suppliers s ON o.supplier_id=s.id
       LEFT JOIN warehouses w ON o.warehouse_id=w.id LEFT JOIN users u ON o.operator_id=u.id WHERE o.id=?`,
      [req.params.id]
    );
    if (orders.length === 0) return fail(res, '入库单不存在');

    const [items]: any = await pool.query(
      `SELECT i.*, p.code as product_code, p.name as product_name, p.barcode, p.unit, l.code as location_code
       FROM inbound_order_items i JOIN products p ON i.product_id=p.id LEFT JOIN locations l ON i.location_id=l.id WHERE i.inbound_order_id=?`,
      [req.params.id]
    );

    return success(res, { order: orders[0], items });
  } catch (err: any) { return fail(res, err.message); }
});

// 创建入库单
router.post('/', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const { type, supplier_id, warehouse_id, items, remark, expected_at } = req.body;
    if (!warehouse_id || !items || items.length === 0) return fail(res, '仓库和入库明细为必填');

    const orderNo = genInboundNo();
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      // 入库单主表
      await conn.query(
        'INSERT INTO inbound_orders (order_no, type, supplier_id, warehouse_id, expected_at, operator_id, remark) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [orderNo, type || 'purchase', supplier_id || null, warehouse_id, expected_at || null, req.user!.id, remark || '']
      );

      const [orderResult]: any = await conn.query('SELECT id FROM inbound_orders WHERE order_no=?', [orderNo]);
      const orderId = orderResult[0].id;

      // 入库明细
      for (const item of items) {
        await conn.query(
          'INSERT INTO inbound_order_items (inbound_order_id, product_id, location_id, expected_qty, batch_no, production_date, expiry_date) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [orderId, item.product_id, item.location_id || null, item.expected_qty || 0, item.batch_no || '', item.production_date || null, item.expiry_date || null]
        );
      }

      await conn.commit();
      conn.release();

      // 写操作日志
      await pool.query(
        'INSERT INTO operation_logs (user_id, username, action, target_type, target_id, detail) VALUES (?, ?, ?, ?, ?, ?)',
        [req.user!.id, req.user!.username, 'create_inbound', 'inbound_order', orderId, JSON.stringify({ order_no: orderNo, items_count: items.length })]
      );

      return success(res, { id: orderId, order_no: orderNo }, '入库单创建成功');
    } catch (err) {
      await conn.rollback();
      conn.release();
      throw err;
    }
  } catch (err: any) { return fail(res, '创建失败: ' + err.message); }
});

// 更新入库明细（收货确认 - 录入实收数量+上架库位+批次）
router.put('/:orderId/items/:itemId', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const { actual_qty, location_id, batch_no, production_date, expiry_date } = req.body;
    await pool.query(
      'UPDATE inbound_order_items SET actual_qty=?, location_id=?, batch_no=?, production_date=?, expiry_date=? WHERE id=? AND inbound_order_id=?',
      [actual_qty, location_id, batch_no || '', production_date || null, expiry_date || null, req.params.itemId, req.params.orderId]
    );
    return success(res, null, '明细更新成功');
  } catch (err: any) { return fail(res, '更新失败: ' + err.message); }
});

// 确认入库（更新库存 + 写流水 + 改状态）
router.post('/:id/confirm', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [orders]: any = await conn.query('SELECT * FROM inbound_orders WHERE id=?', [req.params.id]);
    if (orders.length === 0) { await conn.rollback(); conn.release(); return fail(res, '入库单不存在'); }

    const order = orders[0];
    if (order.status !== 'draft' && order.status !== 'receiving') {
      await conn.rollback(); conn.release(); return fail(res, '当前状态不可确认');
    }

    // 先更新为收货中
    await conn.query('UPDATE inbound_orders SET status="receiving" WHERE id=?', [order.id]);

    // 获取所有明细
    const [items]: any = await conn.query('SELECT * FROM inbound_order_items WHERE inbound_order_id=?', [order.id]);

    for (const item of items) {
      if (!item.actual_qty || item.actual_qty <= 0) continue;
      if (!item.location_id) { await conn.rollback(); conn.release(); return fail(res, `物料ID${item.product_id}未分配上架库位`); }

      const qty = item.actual_qty;

      // 更新库存快照（upsert: 按 product+warehouse+location+batch 唯一键）
      await conn.query(
        `INSERT INTO inventory (product_id, warehouse_id, location_id, qty, batch_no, production_date)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE qty = qty + ?`,
        [item.product_id, order.warehouse_id, item.location_id, qty, item.batch_no || '', item.production_date || null, qty]
      );

      // 获取更新后的库存结存
      const [invs]: any = await conn.query(
        'SELECT qty FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
        [item.product_id, order.warehouse_id, item.location_id, item.batch_no || '']
      );
      const balanceQty = invs.length > 0 ? invs[0].qty : qty;

      // 写库存流水
      await conn.query(
        `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id)
         VALUES (?, ?, 'in', ?, ?, ?, 'inbound', ?, ?)`,
        [item.product_id, item.location_id, qty, balanceQty, item.batch_no || '', order.id, req.user!.id]
      );
    }

    // 更新入库单状态为已完成
    await conn.query('UPDATE inbound_orders SET status="completed" WHERE id=?', [order.id]);

    await conn.commit();
    conn.release();

    // 写操作日志
    await pool.query(
      'INSERT INTO operation_logs (user_id, username, action, target_type, target_id, detail) VALUES (?, ?, ?, ?, ?, ?)',
      [req.user!.id, req.user!.username, 'confirm_inbound', 'inbound_order', order.id, JSON.stringify({ order_no: order.order_no })]
    );

    return success(res, null, '入库确认成功，库存已更新');
  } catch (err: any) {
    await conn.rollback();
    conn.release();
    return fail(res, '入库确认失败: ' + err.message);
  }
});

// 取消入库单
router.put('/:id/cancel', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const [orders]: any = await pool.query('SELECT * FROM inbound_orders WHERE id=?', [req.params.id]);
    if (orders.length === 0) return fail(res, '入库单不存在');
    if (orders[0].status === 'completed') return fail(res, '已完成的入库单不可取消');

    await pool.query('UPDATE inbound_orders SET status="cancelled" WHERE id=?', [req.params.id]);
    return success(res, null, '入库单已取消');
  } catch (err: any) { return fail(res, '取消失败: ' + err.message); }
});

export default router;
