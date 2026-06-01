import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

function genOutboundNo(): string {
  const now = new Date();
  const ts = now.getFullYear().toString() +
    String(now.getMonth() + 1).padStart(2, '0') +
    String(now.getDate()).padStart(2, '0') +
    String(now.getHours()).padStart(2, '0') +
    String(now.getMinutes()).padStart(2, '0') +
    String(now.getSeconds()).padStart(2, '0');
  return 'OUT' + ts;
}

// 出库单列表
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, status = '', type = '', keyword = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = `SELECT o.*, c.name as customer_name, w.name as warehouse_name, u.real_name as operator_name
               FROM outbound_orders o
               LEFT JOIN customers c ON o.customer_id=c.id
               LEFT JOIN warehouses w ON o.warehouse_id=w.id
               LEFT JOIN users u ON o.operator_id=u.id WHERE 1=1`;
    const params: any[] = [];
    if (status) { sql += ' AND o.status=?'; params.push(status); }
    if (type) { sql += ' AND o.type=?'; params.push(type); }
    if (keyword) { sql += ' AND o.order_no LIKE ?'; params.push(`%${keyword}%`); }
    sql += ' ORDER BY o.id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);
    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM outbound_orders');
    const total = count[0].total;
    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 出库单详情
router.get('/:id', async (req: AuthRequest, res: any) => {
  try {
    const [orders]: any = await pool.query(
      `SELECT o.*, c.name as customer_name, w.name as warehouse_name, u.real_name as operator_name
       FROM outbound_orders o LEFT JOIN customers c ON o.customer_id=c.id
       LEFT JOIN warehouses w ON o.warehouse_id=w.id LEFT JOIN users u ON o.operator_id=u.id WHERE o.id=?`,
      [req.params.id]
    );
    if (orders.length === 0) return fail(res, '出库单不存在');

    const [items]: any = await pool.query(
      `SELECT i.*, p.code as product_code, p.name as product_name, p.barcode, p.unit, l.code as location_code
       FROM outbound_order_items i JOIN products p ON i.product_id=p.id LEFT JOIN locations l ON i.picked_location_id=l.id WHERE i.outbound_order_id=?`,
      [req.params.id]
    );
    return success(res, { order: orders[0], items });
  } catch (err: any) { return fail(res, err.message); }
});

// 创建出库单
router.post('/', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const { type, customer_id, warehouse_id, items, remark, expected_at } = req.body;
    if (!warehouse_id || !items || items.length === 0) return fail(res, '仓库和出库明细为必填');

    const orderNo = genOutboundNo();
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      await conn.query(
        'INSERT INTO outbound_orders (order_no, type, customer_id, warehouse_id, expected_at, operator_id, remark) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [orderNo, type || 'sale', customer_id || null, warehouse_id, expected_at || null, req.user!.id, remark || '']
      );

      const [orderResult]: any = await conn.query('SELECT id FROM outbound_orders WHERE order_no=?', [orderNo]);
      const orderId = orderResult[0].id;

      for (const item of items) {
        await conn.query(
          'INSERT INTO outbound_order_items (outbound_order_id, product_id, ordered_qty) VALUES (?, ?, ?)',
          [orderId, item.product_id, item.ordered_qty || 0]
        );
      }

      await conn.commit();
      conn.release();

      await pool.query(
        'INSERT INTO operation_logs (user_id, username, action, target_type, target_id, detail) VALUES (?, ?, ?, ?, ?, ?)',
        [req.user!.id, req.user!.username, 'create_outbound', 'outbound_order', orderId, JSON.stringify({ order_no: orderNo })]
      );

      return success(res, { id: orderId, order_no: orderNo }, '出库单创建成功');
    } catch (err) {
      await conn.rollback();
      conn.release();
      throw err;
    }
  } catch (err: any) { return fail(res, '创建失败: ' + err.message); }
});

// FIFO自动分配拣货方案
router.post('/:id/fifo-allocate', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const [orders]: any = await pool.query('SELECT * FROM outbound_orders WHERE id=?', [req.params.id]);
    if (orders.length === 0) return fail(res, '出库单不存在');
    const order = orders[0];
    if (order.status !== 'draft') return fail(res, '仅草稿状态可分配');

    const [items]: any = await pool.query('SELECT * FROM outbound_order_items WHERE outbound_order_id=?', [order.id]);
    const allocations: any[] = [];
    const errors: string[] = [];

    for (const item of items) {
      let remaining = item.ordered_qty;

      // 按生产日期升序获取库存（FIFO：先生产的先出）
      const [inventoryRows]: any = await pool.query(
        `SELECT * FROM inventory WHERE product_id=? AND warehouse_id=? AND qty > 0 ORDER BY COALESCE(production_date, '2099-12-31') ASC LIMIT 10`,
        [item.product_id, order.warehouse_id]
      );

      for (const inv of inventoryRows) {
        if (remaining <= 0) break;
        const pickQty = Math.min(remaining, inv.qty);
        allocations.push({
          item_id: item.id,
          product_id: item.product_id,
          location_id: inv.location_id,
          batch_no: inv.batch_no,
          pick_qty: pickQty,
        });
        remaining -= pickQty;
      }

      if (remaining > 0) {
        const [prod]: any = await pool.query('SELECT name FROM products WHERE id=?', [item.product_id]);
        const pname = prod.length > 0 ? prod[0].name : `ID:${item.product_id}`;
        errors.push(`物料"${pname}"库存不足，缺${remaining}`);
      }
    }

    if (errors.length > 0) return fail(res, '库存不足：' + errors.join('；'));

    // 写入拣货库位和批次
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      for (const alloc of allocations) {
        await conn.query(
          'UPDATE outbound_order_items SET picked_location_id=?, batch_no=? WHERE id=? AND outbound_order_id=?',
          [alloc.location_id, alloc.batch_no, alloc.item_id, order.id]
        );
      }
      await conn.query('UPDATE outbound_orders SET status="picking" WHERE id=?', [order.id]);
      await conn.commit();
      conn.release();
    } catch (err) {
      await conn.rollback();
      conn.release();
      throw err;
    }

    return success(res, { allocations }, 'FIFO分配成功');
  } catch (err: any) { return fail(res, '分配失败: ' + err.message); }
});

// 确认出库（扣减库存 + 写流水）
router.post('/:id/confirm', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [orders]: any = await conn.query('SELECT * FROM outbound_orders WHERE id=?', [req.params.id]);
    if (orders.length === 0) { await conn.rollback(); conn.release(); return fail(res, '出库单不存在'); }
    const order = orders[0];
    if (order.status !== 'picking') { await conn.rollback(); conn.release(); return fail(res, '请先执行FIFO分配'); }

    const [items]: any = await conn.query('SELECT * FROM outbound_order_items WHERE outbound_order_id=?', [order.id]);

    for (const item of items) {
      const actualQty = item.actual_qty > 0 ? item.actual_qty : item.ordered_qty;
      if (!item.picked_location_id) { await conn.rollback(); conn.release(); return fail(res, `物料ID${item.product_id}未分配拣货库位`); }

      // 扣减库存
      await conn.query(
        'UPDATE inventory SET qty = qty - ? WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
        [actualQty, item.product_id, order.warehouse_id, item.picked_location_id, item.batch_no || '']
      );

      // 清理零库存记录
      await conn.query(
        'DELETE FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=? AND qty <= 0',
        [item.product_id, order.warehouse_id, item.picked_location_id, item.batch_no || '']
      );

      // 获取结存（可能已删除，默认为0）
      const [invs]: any = await conn.query(
        'SELECT qty FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
        [item.product_id, order.warehouse_id, item.picked_location_id, item.batch_no || '']
      );
      const balanceQty = invs.length > 0 ? invs[0].qty : 0;

      // 写库存流水
      await conn.query(
        `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id)
         VALUES (?, ?, 'out', ?, ?, ?, 'outbound', ?, ?)`,
        [item.product_id, item.picked_location_id, -actualQty, balanceQty, item.batch_no || '', order.id, req.user!.id]
      );

      // 更新实发数量
      await conn.query('UPDATE outbound_order_items SET actual_qty=? WHERE id=?', [actualQty, item.id]);
    }

    await conn.query('UPDATE outbound_orders SET status="completed" WHERE id=?', [order.id]);
    await conn.commit();
    conn.release();

    // 检查安全库存预警
    for (const item of items) {
      const [prods]: any = await pool.query('SELECT safety_stock, name FROM products WHERE id=? AND safety_stock > 0', [item.product_id]);
      if (prods.length > 0) {
        const [total]: any = await pool.query('SELECT COALESCE(SUM(qty),0) as total FROM inventory WHERE product_id=? AND warehouse_id=?', [item.product_id, order.warehouse_id]);
        if (total[0].total < prods[0].safety_stock) {
          console.log(`[库存预警] 物料"${prods[0].name}"当前库存${total[0].total}，低于安全库存${prods[0].safety_stock}`);
        }
      }
    }

    return success(res, null, '出库确认成功，库存已更新');
  } catch (err: any) {
    await conn.rollback();
    conn.release();
    return fail(res, '出库确认失败: ' + err.message);
  }
});

// 取消出库单
router.put('/:id/cancel', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const [orders]: any = await pool.query('SELECT * FROM outbound_orders WHERE id=?', [req.params.id]);
    if (orders.length === 0) return fail(res, '出库单不存在');
    if (orders[0].status === 'completed') return fail(res, '已完成的出库单不可取消');
    await pool.query('UPDATE outbound_orders SET status="cancelled" WHERE id=?', [req.params.id]);
    return success(res, null, '出库单已取消');
  } catch (err: any) { return fail(res, '取消失败: ' + err.message); }
});

export default router;
