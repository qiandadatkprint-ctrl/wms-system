import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import pool from '../../database';
import { AuthRequest, authMiddleware } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'wms_jwt_secret_key_2024';

// 登录
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) return fail(res, '用户名和密码不能为空');

    const [rows]: any = await pool.query('SELECT * FROM users WHERE username = ?', [username]);
    if (rows.length === 0) return fail(res, '用户名或密码错误');

    const user = rows[0];
    if (user.status === 0) return fail(res, '账号已被禁用');

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) return fail(res, '用户名或密码错误');

    const token = jwt.sign(
      { id: user.id, username: user.username, real_name: user.real_name, role_type: user.role_type },
      JWT_SECRET,
      { expiresIn: '24h' }
    );

    await pool.query(
      'INSERT INTO operation_logs (user_id, username, action, target_type, detail) VALUES (?, ?, ?, ?, ?)',
      [user.id, user.username, 'login', 'user', JSON.stringify({ msg: '用户登录' })]
    );

    return success(res, {
      token,
      user: { id: user.id, username: user.username, real_name: user.real_name, role_type: user.role_type },
    }, '登录成功');
  } catch (err: any) {
    return fail(res, '登录失败: ' + err.message);
  }
});

// 获取当前用户信息
router.get('/profile', authMiddleware, (req: AuthRequest, res: Response) => {
  return success(res, req.user);
});

// 修改密码
router.put('/password', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { old_password, new_password } = req.body;
    const [rows]: any = await pool.query('SELECT * FROM users WHERE id = ?', [req.user!.id]);
    const user = rows[0];

    const valid = await bcrypt.compare(old_password, user.password_hash);
    if (!valid) return fail(res, '原密码错误');

    const hash = await bcrypt.hash(new_password, 10);
    await pool.query('UPDATE users SET password_hash = ? WHERE id = ?', [hash, req.user!.id]);

    return success(res, null, '密码修改成功');
  } catch (err: any) {
    return fail(res, '修改失败: ' + err.message);
  }
});

// 用户列表（管理员）
router.get('/users', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { page = 1, pageSize = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    const [rows]: any = await pool.query(
      'SELECT id, username, real_name, role_type, phone, status, created_at FROM users ORDER BY id LIMIT ? OFFSET ?',
      [Number(pageSize), offset]
    );
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM users');
    const total = count[0].total;
    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) {
    return fail(res, '查询失败: ' + err.message);
  }
});

// 新增用户
router.post('/users', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { username, real_name, role_type, phone, password } = req.body;
    if (!username || !real_name || !password) return fail(res, '用户名、姓名和密码为必填项');

    const hash = await bcrypt.hash(password, 10);
    await pool.query(
      'INSERT INTO users (username, password_hash, real_name, role_type, phone) VALUES (?, ?, ?, ?, ?)',
      [username, hash, real_name, role_type || 'operator', phone || '']
    );
    return success(res, null, '用户创建成功');
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, '用户名已存在');
    return fail(res, '创建失败: ' + err.message);
  }
});

// 更新用户状态
router.put('/users/:id/status', authMiddleware, async (req: AuthRequest, res: Response) => {
  try {
    const { status } = req.body;
    await pool.query('UPDATE users SET status = ? WHERE id = ?', [status, req.params.id]);
    return success(res, null, status === 1 ? '账号已启用' : '账号已禁用');
  } catch (err: any) {
    return fail(res, '操作失败: ' + err.message);
  }
});

export default router;
