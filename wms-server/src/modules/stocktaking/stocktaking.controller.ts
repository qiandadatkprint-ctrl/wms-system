import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware, requireRole } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

function genTaskNo(): string {
  const now = new Date();
  const ts = now.getFullYear().toString() + String(now.getMonth()+1).padStart(2,'0') + String(now.getDate()).padStart(2,'0') + String(now.getHours()).padStart(2,'0') + String(now.getMinutes()).padStart(2,'0');
  return 'ST' + ts;
}

// 盘点任务列表
router.get('/', async (req: AuthRequest, res: any) => {
  try {
    const { page = 1, pageSize = 20, status = '' } = req.query;
    const offset = (Number(page) - 1) * Number(pageSize);
    let sql = `SELECT t.*, w.name as warehouse_name, u.real_name as operator_name
               FROM stocktaking_tasks t JOIN warehouses w ON t.warehouse_id=w.id LEFT JOIN users u ON t.operator_id=u.id WHERE 1=1`;
    const params: any[] = [];
    if (status) { sql += ' AND t.status=?'; params.push(status); }
    sql += ' ORDER BY t.id DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);
    const [rows]: any = await pool.query(sql, params);
    const [count]: any = await pool.query('SELECT COUNT(*) as total FROM stocktaking_tasks');
    const total = count[0].total;
    return success(res, { list: rows, total, page: Number(page), pageSize: Number(pageSize), totalPages: Math.ceil(total / Number(pageSize)) });
  } catch (err: any) { return fail(res, err.message); }
});

// 盘点任务详情
router.get('/:id', async (req: AuthRequest, res: any) => {
  try {
    const [tasks]: any = await pool.query(
      `SELECT t.*, w.name as warehouse_name FROM stocktaking_tasks t JOIN warehouses w ON t.warehouse_id=w.id WHERE t.id=?`, [req.params.id]
    );
    if (tasks.length === 0) return fail(res, '盘点任务不存在');

    const [items]: any = await pool.query(
      `SELECT i.*, p.code as product_code, p.name as product_name, p.unit, l.code as location_code
       FROM stocktaking_items i JOIN products p ON i.product_id=p.id JOIN locations l ON i.location_id=l.id WHERE i.task_id=?`,
      [req.params.id]
    );
    return success(res, { task: tasks[0], items });
  } catch (err: any) { return fail(res, err.message); }
});

// 创建盘点任务
router.post('/', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const { warehouse_id, type, product_ids = [], location_ids = [] } = req.body;
    const taskNo = genTaskNo();

    await conn.query(
      'INSERT INTO stocktaking_tasks (task_no, warehouse_id, type, operator_id) VALUES (?, ?, ?, ?)',
      [taskNo, warehouse_id, type || 'partial', req.user!.id]
    );

    const [taskResult]: any = await conn.query('SELECT id FROM stocktaking_tasks WHERE task_no=?', [taskNo]);
    const taskId = taskResult[0].id;

    // 根据盘点类型生成盘点明细
    let invSql = `SELECT i.* FROM inventory i WHERE i.warehouse_id=? AND i.qty > 0`;
    const invParams: any[] = [warehouse_id];

    if (type === 'partial') {
      if (product_ids.length > 0) {
        invSql += ' AND i.product_id IN (' + product_ids.map(() => '?').join(',') + ')';
        invParams.push(...product_ids);
      }
      if (location_ids.length > 0) {
        invSql += ' AND i.location_id IN (' + location_ids.map(() => '?').join(',') + ')';
        invParams.push(...location_ids);
      }
    } else if (type === 'dynamic') {
      // 动盘：只盘点最近7天有库存变动的物料
      invSql += ` AND i.product_id IN (SELECT DISTINCT product_id FROM inventory_transactions WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY))`;
    }

    const [invRows]: any = await conn.query(invSql, invParams);

    if (invRows.length === 0) {
      await conn.rollback();
      conn.release();
      return fail(res, '指定范围内没有库存数据，无需盘点');
    }

    for (const inv of invRows) {
      await conn.query(
        'INSERT INTO stocktaking_items (task_id, product_id, location_id, batch_no, system_qty) VALUES (?, ?, ?, ?, ?)',
        [taskId, inv.product_id, inv.location_id, inv.batch_no || '', inv.qty]
      );
    }

    await conn.commit();
    conn.release();

    return success(res, { id: taskId, task_no: taskNo, items_count: invRows.length }, '盘点任务创建成功');
  } catch (err: any) {
    await conn.rollback();
    conn.release();
    return fail(res, '创建失败: ' + err.message);
  }
});

// 录入初次盘点数
router.put('/:taskId/items/:itemId/count', requireRole('admin', 'manager', 'operator'), async (req: AuthRequest, res: any) => {
  try {
    const { actual_qty } = req.body;
    await pool.query(
      'UPDATE stocktaking_items SET actual_qty=?, status="first_done" WHERE id=? AND task_id=?',
      [actual_qty, req.params.itemId, req.params.taskId]
    );
    await pool.query('UPDATE stocktaking_tasks SET status="counting" WHERE id=?', [req.params.taskId]);
    return success(res, null, '盘点数已录入');
  } catch (err: any) { return fail(res, '录入失败: ' + err.message); }
});

// 录入复核数
router.put('/:taskId/items/:itemId/review', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  try {
    const { review_qty } = req.body;
    await pool.query(
      'UPDATE stocktaking_items SET review_qty=?, status="reviewed" WHERE id=? AND task_id=?',
      [review_qty, req.params.itemId, req.params.taskId]
    );
    return success(res, null, '复核数已录入');
  } catch (err: any) { return fail(res, '复核失败: ' + err.message); }
});

// 确认盘点差异并调整库存
router.post('/:id/confirm', requireRole('admin', 'manager'), async (req: AuthRequest, res: any) => {
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [tasks]: any = await conn.query('SELECT * FROM stocktaking_tasks WHERE id=?', [req.params.id]);
    if (tasks.length === 0) { await conn.rollback(); conn.release(); return fail(res, '盘点任务不存在'); }
    const task = tasks[0];

    const [items]: any = await conn.query('SELECT * FROM stocktaking_items WHERE task_id=?', [task.id]);

    for (const item of items) {
      // 确定最终数量：优先复核数，其次初次盘点数
      const finalQty = item.review_qty !== null ? item.review_qty : (item.actual_qty !== null ? item.actual_qty : item.system_qty);
      const diff = finalQty - item.system_qty;

      if (diff === 0) {
        await conn.query('UPDATE stocktaking_items SET final_qty=?, status="adjusted" WHERE id=?', [finalQty, item.id]);
        continue;
      }

      if (diff > 0) {
        // 盘盈
        const [inv]: any = await conn.query(
          'SELECT * FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
          [item.product_id, task.warehouse_id, item.location_id, item.batch_no || '']
        );
        if (inv.length > 0) {
          await conn.query('UPDATE inventory SET qty = qty + ? WHERE id=?', [diff, inv[0].id]);
        } else {
          await conn.query(
            'INSERT INTO inventory (product_id, warehouse_id, location_id, qty, batch_no) VALUES (?, ?, ?, ?, ?)',
            [item.product_id, task.warehouse_id, item.location_id, finalQty, item.batch_no || '']
          );
        }

        const [invAfter]: any = await conn.query(
          'SELECT qty FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
          [item.product_id, task.warehouse_id, item.location_id, item.batch_no || '']
        );

        await conn.query(
          `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id, remark)
           VALUES (?, ?, 'gain', ?, ?, ?, 'stocktaking', ?, ?, '盘点盘盈')`,
          [item.product_id, item.location_id, diff, invAfter[0].qty, item.batch_no || '', task.id, req.user!.id]
        );
      } else {
        // 盘亏
        await conn.query(
          'UPDATE inventory SET qty = qty + ? WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
          [diff, item.product_id, task.warehouse_id, item.location_id, item.batch_no || '']
        );
        await conn.query(
          'DELETE FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=? AND qty <= 0',
          [item.product_id, task.warehouse_id, item.location_id, item.batch_no || '']
        );

        const [invAfter]: any = await conn.query(
          'SELECT qty FROM inventory WHERE product_id=? AND warehouse_id=? AND location_id=? AND batch_no=?',
          [item.product_id, task.warehouse_id, item.location_id, item.batch_no || '']
        );
        const balance = invAfter.length > 0 ? invAfter[0].qty : 0;

        await conn.query(
          `INSERT INTO inventory_transactions (product_id, location_id, type, qty_change, balance_qty, batch_no, reference_type, reference_id, operator_id, remark)
           VALUES (?, ?, 'loss', ?, ?, ?, 'stocktaking', ?, ?, '盘点盘亏')`,
          [item.product_id, item.location_id, diff, balance, item.batch_no || '', task.id, req.user!.id]
        );
      }

      await conn.query('UPDATE stocktaking_items SET final_qty=?, status="adjusted" WHERE id=?', [finalQty, item.id]);
    }

    await conn.query('UPDATE stocktaking_tasks SET status="completed" WHERE id=?', [task.id]);
    await conn.commit();
    conn.release();

    return success(res, null, '盘点确认完成，库存已调整');
  } catch (err: any) {
    await conn.rollback();
    conn.release();
    return fail(res, '盘点确认失败: ' + err.message);
  }
});

export default router;
