import express from 'express';
import cors from 'cors';
import { errorHandler } from './middleware/error';

// 导入所有路由
import authRouter from './modules/auth/auth.controller';
import warehouseRouter from './modules/warehouse/warehouse.controller';
import productRouter from './modules/products/products.controller';
import supplierRouter from './modules/suppliers/suppliers.controller';
import customerRouter from './modules/customers/customers.controller';
import inboundRouter from './modules/inbound/inbound.controller';
import outboundRouter from './modules/outbound/outbound.controller';
import inventoryRouter from './modules/inventory/inventory.controller';
import transferRouter from './modules/transfer/transfer.controller';
import stocktakingRouter from './modules/stocktaking/stocktaking.controller';
import logRouter from './modules/logs/logs.controller';
import dashboardRouter from './modules/dashboard/dashboard.controller';

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// 注册路由
app.use('/api/auth', authRouter);
app.use('/api/warehouses', warehouseRouter);
app.use('/api/products', productRouter);
app.use('/api/suppliers', supplierRouter);
app.use('/api/customers', customerRouter);
app.use('/api/inbound', inboundRouter);
app.use('/api/outbound', outboundRouter);
app.use('/api/inventory', inventoryRouter);
app.use('/api/transfers', transferRouter);
app.use('/api/stocktaking', stocktakingRouter);
app.use('/api/logs', logRouter);
app.use('/api/dashboard', dashboardRouter);

// 健康检查
app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.use(errorHandler);

export default app;
