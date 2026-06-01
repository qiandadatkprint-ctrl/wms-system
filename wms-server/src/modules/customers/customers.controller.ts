import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, keyword = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = 'SELECT * FROM customers WHERE 1=1';
    const params: any[] = [];
    if (keyword) { sql += ' AND (name LIKE ? OR code LIKE ?)'; params.push(`%${keyword}%`, `%${keyword}%`); }
    sql += ' ORDER BY id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);
    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM customers');
    const total = count[0].total;
    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

router.get('/all', async (_req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT id, code, name FROM customers WHERE status=1 ORDER BY name');
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

router.post('/', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { code, name, contact_name, phone, address } = req.body;
    await pool.query('INSERT INTO customers (code, name, contact_name, phone, address) VALUES (?, ?, ?, ?, ?)', [code, name, contact_name || '', phone || '', address || '']);
    return success(res, null, '客户创建成功');
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, '客户编码已存在');
    return fail(res, err.message);
  }
});

router.put('/:id', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { name, contact_name, phone, address } = req.body;
    await pool.query('UPDATE customers SET name=?, contact_name=?, phone=?, address=? WHERE id=?', [name, contact_name || '', phone || '', address || '', req.params.id]);
    return success(res, null, '客户更新成功');
  } catch (err: any) { return fail(res, err.message); }
});

router.put('/:id/status', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  await pool.query('UPDATE customers SET status=? WHERE id=?', [req.body.status, req.params.id]);
  return success(res, null, req.body.status === 1 ? '已启用' : '已禁用');
});

export default router;
