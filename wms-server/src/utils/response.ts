import { Response } from 'express';

export function success(res: Response, data: any = null, msg = '操作成功') {
  return res.json({ code: 0, msg, data });
}

export function fail(res: Response, msg = '操作失败', code = 1, status = 200) {
  return res.status(status).json({ code, msg, data: null });
}

export function paginate(res: Response, list: any[], total: number, page: number, pageSize: number) {
  return res.json({
    code: 0,
    msg: '查询成功',
    data: { list, total, page, pageSize, totalPages: Math.ceil(total / pageSize) },
  });
}
