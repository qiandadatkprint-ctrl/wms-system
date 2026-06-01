import { Request, Response, NextFunction } from 'express';

export function errorHandler(err: Error, _req: Request, res: Response, _next: NextFunction) {
  console.error('[Error]', err.message, err.stack);
  res.status(500).json({ code: 500, msg: '服务器内部错误', data: null });
}
