import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// ===== 仓库管理 =====
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT * FROM warehouses ORDER BY id');
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

router.post('/', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { name, code, address } = req.body;
    await pool.query('INSERT INTO warehouses (name, code, address) VALUES (?, ?, ?)', [name, code, address || '']);
    return success(res, null, '仓库创建成功');
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, '仓库编码已存在');
    return fail(res, err.message);
  }
});

router.put('/:id', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { name, address } = req.body;
    await pool.query('UPDATE warehouses SET name=?, address=? WHERE id=?', [name, address || '', req.params.id]);
    return success(res, null, '仓库更新成功');
  } catch (err: any) { return fail(res, err.message); }
});

// ===== 库区管理 =====
router.get('/:warehouseId/areas', async (req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT a.*, w.name as warehouse_name FROM areas a JOIN warehouses w ON a.warehouse_id=w.id WHERE a.warehouse_id=? ORDER BY a.id', [req.params.warehouseId]);
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

router.post('/areas', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { warehouse_id, name, type } = req.body;
    await pool.query('INSERT INTO areas (warehouse_id, name, type) VALUES (?, ?, ?)', [warehouse_id, name, type || 'storage']);
    return success(res, null, '库区创建成功');
  } catch (err: any) { return fail(res, err.message); }
});

router.put('/areas/:id', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { name, type } = req.body;
    await pool.query('UPDATE areas SET name=?, type=? WHERE id=?', [name, type, req.params.id]);
    return success(res, null, '库区更新成功');
  } catch (err: any) { return fail(res, err.message); }
});

// ===== 库位管理 =====
router.get('/areas/:areaId/locations', async (req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query('SELECT l.*, a.name as area_name FROM locations l JOIN areas a ON l.area_id=a.id WHERE l.area_id=? ORDER BY l.id', [req.params.areaId]);
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

router.post('/locations', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { area_id, code, capacity } = req.body;
    await pool.query('INSERT INTO locations (area_id, code, capacity) VALUES (?, ?, ?)', [area_id, code, capacity || 0]);
    return success(res, null, '库位创建成功');
  } catch (err: any) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, '库位编号已存在');
    return fail(res, err.message);
  }
});

router.put('/locations/:id', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { code, capacity } = req.body;
    await pool.query('UPDATE locations SET code=?, capacity=? WHERE id=?', [code, capacity || 0, req.params.id]);
    return success(res, null, '库位更新成功');
  } catch (err: any) { return fail(res, err.message); }
});

// 获取所有库位（下拉选择用）
router.get('/all-locations', async (req: AuthRequest, res: any) => {
  try {
    const [rows]: any = await pool.query(
      'SELECT l.*, a.name as area_name, w.name as warehouse_name FROM locations l JOIN areas a ON l.area_id=a.id JOIN warehouses w ON a.warehouse_id=w.id WHERE l.status=1 ORDER BY l.code'
    );
    return success(res, rows);
  } catch (err: any) { return fail(res, err.message); }
});

export default router;
