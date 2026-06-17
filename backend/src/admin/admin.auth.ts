import jwt from 'jsonwebtoken';
import { Request } from 'express';

/**
 * Admin authentication — intentionally SEPARATE from the end-user auth.
 *
 * The end-user JWT only carries { userId } and the User table has no role
 * column, so admins are their own population (configured via env, with safe
 * demo defaults so it runs out-of-the-box). Admin routes verify THIS token
 * only — they never honor the legacy `x-user-id` header, which closes the
 * impersonation hole for privileged endpoints.
 */

const ADMIN_SECRET =
  process.env.ADMIN_JWT_SECRET ||
  process.env.JWT_ACCESS_SECRET ||
  'dev-admin-secret-change-me';
const ADMIN_TTL_SECONDS = Number(process.env.ADMIN_JWT_TTL_SECONDS ?? 60 * 60 * 8);

export type AdminRole = 'support' | 'moderator' | 'super-admin';

export type AdminPayload = {
  adminId: string;
  email: string;
  name: string;
  role: AdminRole;
  kind: 'admin';
};

type AdminAccount = {
  id: string;
  email: string;
  password: string;
  name: string;
  role: AdminRole;
};

function loadAdminAccounts(): AdminAccount[] {
  // Optional: a JSON array in ADMIN_ACCOUNTS overrides everything.
  const raw = process.env.ADMIN_ACCOUNTS;
  if (raw) {
    try {
      const parsed = JSON.parse(raw) as AdminAccount[];
      if (Array.isArray(parsed) && parsed.length) return parsed;
    } catch {
      // fall through to defaults
    }
  }

  const email = process.env.ADMIN_EMAIL || 'admin@zenzoo.app';
  const password = process.env.ADMIN_PASSWORD || 'zenzoo-admin';
  return [
    { id: 'adm_super', email, password, name: 'Super Admin', role: 'super-admin' },
    { id: 'adm_support', email: 'support@zenzoo.app', password: 'zenzoo-support', name: 'Support Agent', role: 'support' },
    { id: 'adm_mod', email: 'mod@zenzoo.app', password: 'zenzoo-mod', name: 'Moderator', role: 'moderator' },
  ];
}

export function authenticateAdmin(email: unknown, password: unknown) {
  const account = loadAdminAccounts().find(
    (a) =>
      a.email.toLowerCase() === String(email ?? '').trim().toLowerCase() &&
      a.password === String(password ?? ''),
  );
  if (!account) {
    throw Object.assign(new Error('Sai email hoặc mật khẩu quản trị'), { status: 401 });
  }
  const token = jwt.sign(
    {
      adminId: account.id,
      email: account.email,
      name: account.name,
      role: account.role,
      kind: 'admin',
    } satisfies AdminPayload,
    ADMIN_SECRET,
    { expiresIn: ADMIN_TTL_SECONDS },
  );
  return {
    token,
    admin: { id: account.id, email: account.email, name: account.name, role: account.role },
  };
}

export function verifyAdminToken(token: string): AdminPayload {
  const payload = jwt.verify(token, ADMIN_SECRET) as AdminPayload;
  if (payload?.kind !== 'admin' || !payload.adminId) {
    throw Object.assign(new Error('Token quản trị không hợp lệ'), { status: 401 });
  }
  return payload;
}

const ROLE_RANK: Record<AdminRole, number> = {
  support: 1,
  moderator: 2,
  'super-admin': 3,
};

/**
 * Gate an admin route. Reads ONLY the Authorization: Bearer header (no
 * x-user-id fallback). `minRole` enforces a least-privilege floor.
 */
export function requireAdmin(req: Request, minRole: AdminRole = 'support'): AdminPayload {
  const header = req.header('authorization') ?? '';
  if (!header.startsWith('Bearer ')) {
    throw Object.assign(new Error('Cần đăng nhập quản trị'), { status: 401 });
  }
  const payload = verifyAdminToken(header.slice('Bearer '.length).trim());
  if (ROLE_RANK[payload.role] < ROLE_RANK[minRole]) {
    throw Object.assign(new Error('Tài khoản không đủ quyền cho thao tác này'), { status: 403 });
  }
  return payload;
}
