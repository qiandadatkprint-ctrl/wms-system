import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// 操作日志列表
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 30, action = '', user_id = '', start_date = '', end_date = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = 'SELECT * FROM operation_logs WHERE 1=1';
    const params: any[] = [];
    if (action) { sql += ' AND action=?'; params.push(action); }
    if (user_id) { sql += ' AND user_id=?'; params.push(user_id); }
    if (start_date) { sql += ' AND created_at >= ?'; params.push(start_date); }
    if (end_date) { sql += ' AND created_at <= ?'; params.push(end_date + ' 23:59:59'); }
    sql += ' ORDER BY id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);

    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM operation_logs');
    const total = count[0].total;

    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 操作类型统计（用于筛选下拉）
router.get('/actions', async (_req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT DISTINCT action FROM operation_logs ORDER BY action');
    return success(res, rows.map((r: any) => r.action));
  } catch (err: any) { return fail(res, err.message); }
});

export default router;
