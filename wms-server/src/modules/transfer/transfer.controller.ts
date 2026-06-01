import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

function genTransferNo(): string {
  const now = new Date();
  const ts = now.getFullYear().toString() + String(now.getMonth()+1).padStart(2,'0') + String(now.getDate()).padStart(2,'0') + String(now.getHours()).padStart(2,'0') + String(now.getMinutes()).padStart(2,'0');
  return 'TF' + ts;
}

// 移库单列表
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    const [rows]: any = await pool.query(
      `SELECT t.*, p.name as product_name, p.code as product_code, fl.code as from_location_code, tl.code as to_location_code, u.real_name as operator_name
       FROM transfers t JOIN products p ON t.product_id=p.id JOIN locations fl ON t.from_location_id=fl.id JOIN locations tl ON t.to_location_id=tl.id LEFT JOIN users u ON t.operator_id=u.id
       ORDER BY t.id DESC LIMIT ? OFFSET ?`, [Number(pageSize), offset]
    );
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM transfers');
    const total = count[0].total;
    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 创建移库单
router.post('/', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const { product_id, from_location_id, to_location_id, qty, batch_no, remark } = req.body;
    if (from_location_id === to_location_id) return fail(res, '源库位和目标库位不能相同');

    // 校验源库位库存
    const [inv]: any = await pool.query(
      'SELECT * FROM inventory WHERE product_id=? AND location_id=? AND batch_no=? AND qty >= ?',
      [product_id, from_location_id, batch_no || '', qty]
    );
    if (inv.length === 0) return fail(res, '源库位库存不足');

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const transferNo = genTransferNo();
      await conn.query(
        'INSERT INTO transfers (transfer_no, product_id, from_location_id, to_location_id, qty, batch_no, operator_id, remark, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, "completed")',
        [transferNo, product_id, from_location_id, to_location_id, qty, batch_no || '', req.user!.id, remark || '']
      );

      // 源库位减库存
      await conn.query(
        'UPDATE inventory SET qty = qty - ? WHERE product_id=? AND location_id=? AND batch_no=?',
        [qty, product_id, from_location_id, batch_no || '']
      );
      await conn.query(
        'DELETE FROM inventory WHERE product_id=? AND location_id=? AND batch_no=? AND qty <= 0',
        [product_id, from_location_id, batch_no || '']
      );

      // 获取源库位结存
      const [fromInv]: any = await conn.query('SELECT qty FROM inventory WHERE product_id=? AND location_id=? AND batch_no=?', [product_id, from_location_id, batch_no || '']);
      const fromBalance = fromInv.length > 0 ? fromInv[0].qty : 0;

      // 写流水 - 移出
      await conn.query(
        `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id)
         VALUES (?, ?, 'transfer_out', ?, ?, ?, 'transfer', ?, ?)`,
        [product_id, from_location_id, -qty, fromBalance, batch_no || '', 0, req.user!.id]
      );

      // 目标库位加库存（获取转移单ID用于关联）
      const warehouseId = inv[0].warehouse_id;
      await conn.query(
        `INSERT INTO inventory (product_id, warehouse_id, location_id, qty, batch_no, production_date)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE qty = qty + ?`,
        [product_id, warehouseId, to_location_id, qty, batch_no || '', inv[0].production_date || null, qty]
      );

      // 写流水 - 移入
      const [toInv]: any = await conn.query('SELECT qty FROM inventory WHERE product_id=? AND location_id=? AND batch_no=?', [product_id, to_location_id, batch_no || '']);
      const toBalance = toInv.length > 0 ? toInv[0].qty : qty;
      await conn.query(
        `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id)
         VALUES (?, ?, 'transfer_in', ?, ?, ?, 'transfer', ?, ?)`,
        [product_id, to_location_id, qty, toBalance, batch_no || '', 0, req.user!.id]
      );

      await conn.commit();
      conn.release();

      return success(res, { transfer_no: transferNo }, '移库成功');
    } catch (err) {
      await conn.rollback();
      conn.release();
      throw err;
    }
  } catch (err: any) { return fail(res, '移库失败: ' + err.message); }
});

export default router;
