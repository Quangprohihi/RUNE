import { Request } from 'express';
import { resolveUserIdFromRequest } from '../auth';

function currentUserId(req: Request) {
  return req.header('x-user-id') ?? '';
}

export function requireUser(req: Request) {
  return resolveUserIdFromRequest(
    req.header('authorization') ?? undefined,
    currentUserId(req) || undefined,
  );
}
