import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'wms_jwt_secret_key_2024';

export interface AuthRequest extends Request {
  user?: { id: number; username: string; real_name: string; role_type: string };
}

// 验证JWT令牌
export function authMiddleware(req: AuthRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ code: 401, msg: '未登录或令牌已过期', data: null });
  }
  const token = authHeader.substring(7);
  try {
    const payload = jwt.verify(token, JWT_SECRET) as any;
    req.user = { id: payload.id, username: payload.username, real_name: payload.real_name, role_type: payload.role_type };
    next();
  } catch {
    return res.status(401).json({ code: 401, msg: '令牌无效或已过期', data: null });
  }
}

// 角色权限校验
export function requireRole(...roles: string[]) {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) return res.status(401).json({ code: 401, msg: '未登录', data: null });
    if (!roles.includes(req.user.role_type)) {
      return res.status(403).json({ code: 403, msg: '权限不足', data: null });
    }
    next();
  };
}
