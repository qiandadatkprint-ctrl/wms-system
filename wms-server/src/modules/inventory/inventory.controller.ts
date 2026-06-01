import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// 库存查询（按物料+库位+批次汇总）
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, keyword = '', warehouse_id = '', category = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = `SELECT i.*, p.code as product_code, p.name as product_name, p.category, p.unit, p.spec,
                      l.code as location_code, a.name as area_name, w.name as warehouse_name
               FROM inventory i
               JOIN products p ON i.product_id=p.id
               JOIN locations l ON i.location_id=l.id
               JOIN areas a ON l.area_id=a.id
               JOIN warehouses w ON i.warehouse_id=w.id
               WHERE i.qty > 0`;
    const params: any[] = [];
    if (keyword) { sql += ' AND (p.name LIKE ? OR p.code LIKE ? OR p.barcode LIKE ?)'; params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`); }
    if (warehouse_id) { sql += ' AND i.warehouse_id=?'; params.push(warehouse_id); }
    if (category) { sql += ' AND p.category=?'; params.push(category); }
    sql += ' ORDER BY p.name, i.production_date ASC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);

    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query(
      `SELECT COUNT(*) as total FROM inventory i JOIN products p ON i.product_id=p.id WHERE i.qty > 0
       ${keyword ? "AND (p.name LIKE '%" + keyword + "%' OR p.code LIKE '%" + keyword + "%')" : ""}`
    );
    const total = count[0].total;

    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 按物料汇总库存
router.get('/summary', async (req: AuthRequest, res: any) => {
  try {
    const { warehouse_id = '' } = req.query;
    let sql = `SELECT p.id as product_id, p.code as product_code, p.name as product_name, p.category, p.unit, p.spec, p.safety_stock, p.max_stock,
                      COALESCE(SUM(i.qty), 0) as total_qty, w.name as warehouse_name
               FROM products p
               LEFT JOIN inventory i ON p.id=i.product_id AND i.qty > 0`;
    if (warehouse_id) sql += ` AND i.warehouse_id=${Number(warehouse_id)}`;
    sql += ' JOIN warehouses w ON w.id=' + (warehouse_id ? Number(warehouse_id) : 1);
    sql += ' WHERE p.status=1 GROUP BY p.id ORDER BY p.name';

    const [rows]: any = await pool.query(sql);
    // 标记预警
    const list = rows.map((r: any) => ({
      ...r,
      alert: r.safety_stock > 0 && r.total_qty < r.safety_stock ? 'low' : (r.max_stock > 0 && r.total_qty > r.max_stock ? 'high' : 'normal'),
    }));

    return success(res, list);
  } catch (err: any) { return fail(res, err.message); }
});

// 库存流水（按物料查询）
router.get('/transactions', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, product_id = '', start_date = '', end_date = '', type = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = `SELECT t.*, p.code as product_code, p.name as product_name, l.code as location_code
               FROM inventory_transactions t
               JOIN products p ON t.product_id=p.id
               JOIN locations l ON t.location_id=l.id WHERE 1=1`;
    const params: any[] = [];
    if (product_id) { sql += ' AND t.product_id=?'; params.push(product_id); }
    if (start_date) { sql += ' AND t.created_at >= ?'; params.push(start_date); }
    if (end_date) { sql += ' AND t.created_at <= ?'; params.push(end_date + ' 23:59:59'); }
    if (type) { sql += ' AND t.type=?'; params.push(type); }
    sql += ' ORDER BY t.id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);

    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM inventory_transactions');
    const total = count[0].total;

    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 库存预警列表
router.get('/alerts', async (req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query(
      `SELECT p.id as product_id, p.code as product_code, p.name as product_name, p.safety_stock, p.max_stock, p.unit,
              COALESCE(SUM(i.qty), 0) as total_qty
       FROM products p LEFT JOIN inventory i ON p.id=i.product_id AND i.qty > 0
       WHERE p.status=1 AND p.safety_stock > 0
       GROUP BY p.id HAVING total_qty < p.safety_stock OR (p.max_stock > 0 AND total_qty > p.max_stock)
       ORDER BY total_qty ASC`
    );
    const list = rows.map((r: any) => ({
      ...r,
      alert_type: r.total_qty < r.safety_stock ? '库存过低' : '库存过高',
      gap: r.total_qty < r.safety_stock ? r.safety_stock - r.total_qty : r.total_qty - r.max_stock,
    }));
    return success(res, list);
  } catch (err: any) { return fail(res, err.message); }
});

export default router;
