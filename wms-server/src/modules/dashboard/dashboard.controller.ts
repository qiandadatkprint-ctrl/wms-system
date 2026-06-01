import { Router } from 'express';
import pool from '../../database';
import { AuthRequest, authMiddleware } from '../../middleware/auth';
import { success, fail } from '../../utils/response';

const router = Router();
router.use(authMiddleware);

// 仪表盘统计数据
router.get('/stats', async (_req: AuthRequest, res: any) => {
  try {
    const [[{ productCount }]]: any = await pool.query('SELECT COUNT(*) as productCount FROM products WHERE status=1');
    const [[{ warehouseCount }]]: any = await pool.query('SELECT COUNT(*) as warehouseCount FROM warehouses WHERE status=1');
    const [[{ locationCount }]]: any = await pool.query('SELECT COUNT(*) as locationCount FROM locations WHERE status=1');
    const [[{ totalQty }]]: any = await pool.query('SELECT COALESCE(SUM(qty), 0) as totalQty FROM inventory');
    const [[{ pendingInbound }]]: any = await pool.query("SELECT COUNT(*) as pendingInbound FROM inbound_orders WHERE status IN ('draft','receiving')");
    const [[{ pendingOutbound }]]: any = await pool.query("SELECT COUNT(*) as pendingOutbound FROM outbound_orders WHERE status IN ('draft','picking')");
    const [[{ alertCount }]]: any = await pool.query(
      `SELECT COUNT(*) as alertCount FROM products p WHERE p.status=1 AND p.safety_stock > 0
       AND COALESCE((SELECT SUM(qty) FROM inventory WHERE product_id=p.id), 0) < p.safety_stock`
    );

    return success(res, {
      productCount,
      warehouseCount,
      locationCount,
      totalQty,
      pendingInbound,
      pendingOutbound,
      alertCount,
    });
  } catch (err: any) { return fail(res, err.message); }
});

// 最近7天出入库趋势
router.get('/trend', async (_req: AuthRequest, res: any) => {
  try {
    const [inboundTrend]: any = await pool.query(
      `SELECT DATE(t.created_at) as date, COUNT(*) as count, COALESCE(SUM(ABS(i.actual_qty)), 0) as total_qty
       FROM inventory_transactions t
       JOIN inbound_order_items i ON t.reference_id = i.inbound_order_id AND t.reference_type='inbound'
       WHERE t.type='in' AND t.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
       GROUP BY DATE(t.created_at) ORDER BY date`
    );
    const [outboundTrend]: any = await pool.query(
      `SELECT DATE(t.created_at) as date, COUNT(*) as count, COALESCE(SUM(ABS(t.qty_change)), 0) as total_qty
       FROM inventory_transactions t
       WHERE t.type='out' AND t.created_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
       GROUP BY DATE(t.created_at) ORDER BY date`
    );

    // 合并为统一趋势
    const days: any[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      const ib = inboundTrend.find((r: any) => { const rd = new Date(r.date); return rd.toISOString().split('T')[0] === dateStr; }) || { count: 0, total_qty: 0 };
      const ob = outboundTrend.find((r: any) => { const rd = new Date(r.date); return rd.toISOString().split('T')[0] === dateStr; }) || { count: 0, total_qty: 0 };
      days.push({ date: dateStr, inbound_count: ib.count, inbound_qty: ib.total_qty, outbound_count: ob.count, outbound_qty: ob.total_qty });
    }

    return success(res, days);
  } catch (err: any) { return fail(res, err.message); }
});

export default router;
