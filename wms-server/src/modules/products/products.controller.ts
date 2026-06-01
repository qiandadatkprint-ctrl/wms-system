import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// 物料列表（分页+搜索）
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, keyword = '', category = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = 'SELECT * FROM products WHERE 1=1';
    const params: any[] = [];

    if (keyword) { sql += ' AND (name LIKE ? OR code LIKE ? OR barcode LIKE ?)'; params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`); }
    if (category) { sql += ' AND category = ?'; params.push(category); }

    sql += ' ORDER BY id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);

    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM products');
    const total = count[0].total;

    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 全部物料（下拉选择用）
router.get('/all', async (_req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT id, code, name, barcode, unit FROM products WHERE status=1 ORDER BY name');
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

// 创建物料
router.post('/', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { code, name, barcode, category, spec, unit, safety_stock, max_stock, retail_price } = req.body;
    await pool.query(
      `INSERT INTO products (code, name, barcode, category, spec, unit, safety_stock, max_stock, retail_price)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [code, name, barcode || '', category || '', spec || '', unit || '个', safety_stock || 0, max_stock || 0, retail_price || 0]
    );
    return success(res, null, '物料创建成功');
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, 'SKU编码或条码已存在');
    return fail(res, err.message);
  }
});

// 更新物料
router.put('/:id', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { name, barcode, category, spec, unit, safety_stock, max_stock, retail_price } = req.body;
    await pool.query(
      'UPDATE products SET name=?, barcode=?, category=?, spec=?, unit=?, safety_stock=?, max_stock=?, retail_price=? WHERE id=?',
      [name, barcode || '', category || '', spec || '', unit || '个', safety_stock || 0, max_stock || 0, retail_price || 0, req.params.id]
    );
    return success(res, null, '物料更新成功');
  } catch (err: any) { return fail(res, err.message); }
});

// 切换状态
router.put('/:id/status', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { status } = req.body;
    await pool.query('UPDATE products SET status=? WHERE id=?', [status, req.params.id]);
    return success(res, null, status === 1 ? '已启用' : '已禁用');
  } catch (err: any) { return fail(res, err.message); }
});

export default router;
