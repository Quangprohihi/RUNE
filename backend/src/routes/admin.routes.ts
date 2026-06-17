import { authenticateAdmin, requireAdmin } from '../admin/admin.auth';
import {
  windowFor, bucketEdges, bucketCounts, bucketSums, deltaPct, round1, sparkBucketCount, RangeKey,
} from '../admin/admin.metrics';
import { computeMrr, refundRate, arpu, bucketLatestPaidByUser } from '../admin/billing.metrics';
import { adminConfirmOrder } from '../services/payment.service';
import { extendExpiry } from '../admin/subscription.util';

/**
 * Admin API — read-mostly operations console over the existing data.
 * All routes are gated by requireAdmin (Bearer admin-token only).
 * Mounted under /admin/api/* so it never collides with end-user routes.
 *
 * deps: { prisma }
 */
export function registerAdminRoutes(app: any, deps: any) {
  const { prisma } = deps;

  // ---- auth ----
  app.post('/admin/api/auth/login', (req: any, res: any, next: any) => {
    try {
      const { email, password } = req.body ?? {};
      res.json(authenticateAdmin(email, password));
    } catch (error) {
      next(error);
    }
  });

  app.get('/admin/api/auth/me', (req: any, res: any, next: any) => {
    try {
      const admin = requireAdmin(req);
      res.json({ id: admin.adminId, email: admin.email, name: admin.name, role: admin.role });
    } catch (error) {
      next(error);
    }
  });

  // ---- overview / KPIs (ranged, with delta + sparkline) ----
  app.get('/admin/api/overview', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const range = (['today', '7d', '30d', 'quarter'].includes(String(req.query.range))
        ? String(req.query.range)
        : 'today') as RangeKey;
      const now = new Date();
      const { curStart, prevStart, prevEnd, end } = windowFor(range, now);
      const mauStart = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
      const quarterStart = windowFor('quarter', now).curStart;
      const edges = bucketEdges(curStart, end, sparkBucketCount(range));

      const [
        totalUsers,
        premiumUsers,
        sessionsCur, sessionsPrev, sessionRows,
        minutesCur, minutesPrev, minuteRows,
        revenueCur, revenuePrev, paymentRows,
        avgStreakAgg,
        dauFocus, dauEvents, mauFocus, mauEvents,
        recent,
        revenueQuarterAgg,
      ] = await Promise.all([
        prisma.user.count(),
        prisma.subscription.count({ where: { plan: { not: 'free' }, status: 'active' } }),
        prisma.focusSession.count({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.count({ where: { status: 'completed', startedAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.focusSession.findMany({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } }, select: { startedAt: true, plannedMinutes: true } }),
        prisma.focusSession.aggregate({ _sum: { plannedMinutes: true }, where: { status: 'completed', startedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.aggregate({ _sum: { plannedMinutes: true }, where: { status: 'completed', startedAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.focusSession.findMany({ where: { status: 'completed', startedAt: { gte: curStart, lte: end } }, select: { startedAt: true, plannedMinutes: true } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.paymentOrder.findMany({ where: { status: 'paid', paidAt: { gte: curStart, lte: end } }, select: { paidAt: true, amountVnd: true } }),
        prisma.userStreak.aggregate({ _avg: { currentStreak: true } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: curStart, lte: end } }, select: { userId: true, startedAt: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: curStart, lte: end } }, select: { userId: true, createdAt: true } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: mauStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: mauStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ take: 7, orderBy: { createdAt: 'desc' }, include: { user: { select: { displayName: true } } } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: quarterStart, lte: end } } }),
      ]);

      const dau = new Set<string>([...dauFocus.map((r: any) => r.userId), ...dauEvents.map((r: any) => r.userId)]).size;
      const mau = new Set<string>([...mauFocus.map((r: any) => r.userId), ...mauEvents.map((r: any) => r.userId)]).size;
      const stickiness = mau ? round1((dau / mau) * 100) : 0;
      const avgStreak = round1(avgStreakAgg._avg.currentStreak ?? 0);
      const conversion = totalUsers ? round1((premiumUsers / totalUsers) * 100) : 0;
      const focusMinutes = minutesCur._sum.plannedMinutes ?? 0;
      const focusMinutesPrev = minutesPrev._sum.plannedMinutes ?? 0;
      const revenue = revenueCur._sum.amountVnd ?? 0;
      const revenuePrevVal = revenuePrev._sum.amountVnd ?? 0;

      const dauSpark = bucketCounts(
        [
          ...dauFocus.map((r: any) => new Date(r.startedAt)),
          ...dauEvents.map((r: any) => new Date(r.createdAt)),
        ],
        edges,
      );
      const sessionSpark = bucketCounts(sessionRows.map((r: any) => new Date(r.startedAt)), edges);
      const minuteSpark = bucketSums(minuteRows.map((r: any) => ({ at: new Date(r.startedAt), value: r.plannedMinutes })), edges);
      const revenueSpark = bucketSums(paymentRows.map((r: any) => ({ at: new Date(r.paidAt), value: r.amountVnd })), edges);

      const point = (value: number) => ({ value, deltaPct: null as number | null, spark: [] as number[] });

      res.json({
        range,
        kpis: {
          dau: { value: dau, deltaPct: null, spark: dauSpark },
          stickiness: point(stickiness),
          focusMinutes: { value: focusMinutes, deltaPct: deltaPct(focusMinutes, focusMinutesPrev), spark: minuteSpark },
          focusSessions: { value: sessionsCur, deltaPct: deltaPct(sessionsCur, sessionsPrev), spark: sessionSpark },
          premiumUsers: point(premiumUsers),
          revenue: { value: revenue, deltaPct: deltaPct(revenue, revenuePrevVal), spark: revenueSpark },
          avgStreak: point(avgStreak),
          conversion: point(conversion),
        },
        goals: [
          { label: 'Doanh thu quý', value: Math.round(((revenueQuarterAgg._sum.amountVnd ?? 0) / Math.max(1, Number(process.env.QUARTER_REVENUE_TARGET ?? 100000000))) * 100), max: 100, unit: '%' },
          { label: 'Zen Pro · mục tiêu ' + Number(process.env.QUARTER_PRO_TARGET ?? 400), value: premiumUsers, max: Number(process.env.QUARTER_PRO_TARGET ?? 400) },
          { label: 'Tỉ lệ chuyển đổi', value: conversion, max: Number(process.env.CONVERSION_TARGET ?? 8), unit: '%' },
        ],
        recent: recent.map((e: any) => ({
          eventType: e.eventType,
          title: e.title,
          subtitle: e.subtitle,
          actor: e.user?.displayName ?? '—',
          at: e.createdAt,
        })),
      });
    } catch (error) {
      next(error);
    }
  });

  // ---- service health (for the overview "Tình trạng hệ thống" card) ----
  app.get('/admin/api/health', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const t0 = Date.now();
      let db: 'ok' | 'down' = 'ok';
      try {
        await prisma.$queryRaw`SELECT 1`;
      } catch {
        db = 'down';
      }
      const apiLatencyMs = Date.now() - t0;
      res.json({
        db,
        vnpay: Boolean(process.env.VNPAY_TMN_CODE || process.env.VNP_TMN_CODE),
        gemini: Boolean(process.env.GEMINI_API_KEY || process.env.GOOGLE_API_KEY),
        apiLatencyMs,
      });
    } catch (error) {
      next(error);
    }
  });

  // ---- users list (search + plan/status filters) ----
  app.get('/admin/api/users', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const q = String(req.query.q ?? '').trim();
      const plan = String(req.query.plan ?? '').trim();     // 'free' | 'premium'
      const status = String(req.query.status ?? '').trim();  // 'active' | 'suspended' | 'review'
      const page = Math.max(1, Number(req.query.page ?? 1));
      const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize ?? 25)));

      // Compose filters with AND so search (q) and the plan OR-filter don't collide.
      const and: any[] = [];
      if (q) {
        and.push({
          OR: [
            { email: { contains: q, mode: 'insensitive' } },
            { displayName: { contains: q, mode: 'insensitive' } },
          ],
        });
      }
      if (status === 'active' || status === 'suspended' || status === 'review') {
        and.push({ status });
      }
      if (plan === 'premium') {
        // Has a paid subscription.
        and.push({ subscription: { plan: { not: 'free' } } });
      } else if (plan === 'free') {
        // No subscription, or an explicit free subscription.
        and.push({ OR: [{ subscription: { is: null } }, { subscription: { plan: 'free' } }] });
      }
      const where: any = and.length ? { AND: and } : {};

      const [total, users] = await Promise.all([
        prisma.user.count({ where }),
        prisma.user.findMany({
          where,
          skip: (page - 1) * pageSize,
          take: pageSize,
          orderBy: { createdAt: 'desc' },
          include: {
            subscription: true,
            pet: { select: { level: true } },
            streak: { select: { currentStreak: true } },
          },
        }),
      ]);

      res.json({
        total,
        page,
        pageSize,
        items: users.map((u: any) => ({
          id: u.id,
          email: u.email,
          displayName: u.displayName,
          provider: u.provider,
          createdAt: u.createdAt,
          plan: u.subscription && u.subscription.plan !== 'free' ? u.subscription.plan : 'free',
          status: u.status ?? 'active',
          level: u.pet?.level ?? 1,
          streak: u.streak?.currentStreak ?? 0,
          lastLoginAt: u.lastLoginAt ?? null,
        })),
      });
    } catch (error) {
      next(error);
    }
  });

  // ---- user detail ----
  app.get('/admin/api/users/:id', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const user = await prisma.user.findUnique({
        where: { id: req.params.id },
        include: {
          subscription: true,
          pet: true,
          wallet: true,
          streak: true,
          focusSessions: { take: 5, orderBy: { startedAt: 'desc' } },
          activityEvents: { take: 8, orderBy: { createdAt: 'desc' } },
          _count: { select: { refreshTokens: true } },
        },
      });
      if (!user) {
        throw Object.assign(new Error('Không tìm thấy người dùng'), { status: 404 });
      }
      res.json(user);
    } catch (error) {
      next(error);
    }
  });

  // ---- force-logout (real action via RefreshToken, no schema change) ----
  app.post('/admin/api/users/:id/force-logout', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req, 'moderator');
      const result = await prisma.refreshToken.updateMany({
        where: { userId: req.params.id, revokedAt: null },
        data: { revokedAt: new Date() },
      });
      res.json({ ok: true, revoked: result.count });
    } catch (error) {
      next(error);
    }
  });

  // ---- manage a user's subscription (cancel / extend) ----
  app.post('/admin/api/users/:id/subscription', async (req: any, res: any, next: any) => {
    try {
      const admin = requireAdmin(req, 'moderator');
      const userId = String(req.params.id);
      const action = String(req.body?.action ?? '');
      const now = new Date();
      let data: any;
      if (action === 'cancel') {
        data = { plan: 'free', status: 'expired', expiresAt: now };
      } else if (action === 'extend') {
        const days = Number(req.body?.days);
        if (!Number.isFinite(days) || days < 1 || days > 730) {
          throw Object.assign(new Error('Số ngày gia hạn không hợp lệ (1–730)'), { status: 400 });
        }
        const existing = await prisma.subscription.findUnique({ where: { userId } });
        data = { plan: 'premium', status: 'active', expiresAt: extendExpiry(existing?.expiresAt ?? null, days, now) };
      } else {
        throw Object.assign(new Error('Hành động không hợp lệ'), { status: 400 });
      }
      const sub = await prisma.subscription.upsert({
        where: { userId },
        create: { userId, ...data },
        update: data,
      });
      await prisma.activityEvent.create({
        data: {
          userId,
          eventType: 'subscription_admin',
          title: action === 'cancel' ? 'Subscription bị hủy (admin)' : 'Subscription gia hạn (admin)',
          subtitle: action === 'extend' ? `+${req.body?.days} ngày` : 'Hạ về Free',
          icon: '🛠️',
          metadata: { action, days: req.body?.days ?? null, by: admin.adminId },
        },
      });
      res.json(sub);
    } catch (error) {
      next(error);
    }
  });

  // ---- payments / transactions (paginated, date + status filter) ----
  app.get('/admin/api/payments', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const status = String(req.query.status ?? '').trim();
      const allowed = ['pending', 'paid', 'failed', 'review', 'refunded'];
      const page = Math.max(1, Number(req.query.page ?? 1));
      const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize ?? 25)));
      const from = String(req.query.from ?? '').trim();
      const to = String(req.query.to ?? '').trim();

      const where: any = {};
      if (allowed.includes(status)) where.status = status;
      const createdAt: any = {};
      if (from) { const d = new Date(from); if (!isNaN(d.getTime())) createdAt.gte = d; }
      if (to) { const d = new Date(to); if (!isNaN(d.getTime())) { d.setUTCHours(23, 59, 59, 999); createdAt.lte = d; } }
      if (createdAt.gte || createdAt.lte) where.createdAt = createdAt;

      const [total, orders] = await Promise.all([
        prisma.paymentOrder.count({ where }),
        prisma.paymentOrder.findMany({
          where,
          skip: (page - 1) * pageSize,
          take: pageSize,
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { displayName: true } } },
        }),
      ]);

      res.json({
        total,
        page,
        pageSize,
        items: orders.map((o: any) => ({
          id: o.id,
          vnpTxnRef: o.vnpTxnRef,
          user: o.user?.displayName ?? '—',
          productCode: o.productCode,
          amountVnd: o.amountVnd,
          status: o.status,
          bankCode: o.bankCode,
          payDate: o.payDate,
          paidAt: o.paidAt,
          createdAt: o.createdAt,
        })),
      });
    } catch (error) {
      next(error);
    }
  });

  // ---- billing summary (read-only KPIs + package breakdown) ----
  app.get('/admin/api/billing/summary', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const range = (['today', '7d', '30d', 'quarter'].includes(String(req.query.range))
        ? String(req.query.range)
        : '30d') as RangeKey;
      const now = new Date();
      const { curStart, prevStart, prevEnd, end } = windowFor(range, now);

      const [
        revenueCurAgg, revenuePrevAgg, paidCount, refundedCount,
        dauFocus, dauEvents, totalUsers, premiumSubs, paidSubOrders,
      ] = await Promise.all([
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.paymentOrder.count({ where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.count({ where: { status: 'refunded', updatedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: curStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: curStart, lte: end } }, select: { userId: true } }),
        prisma.user.count(),
        prisma.subscription.findMany({ where: { plan: { not: 'free' }, status: 'active' }, select: { userId: true } }),
        prisma.paymentOrder.findMany({ where: { status: 'paid', productType: 'subscription' }, orderBy: { paidAt: 'desc' }, select: { userId: true, productCode: true, paidAt: true } }),
      ]);

      const revenue = revenueCurAgg._sum.amountVnd ?? 0;
      const revenuePrev = revenuePrevAgg._sum.amountVnd ?? 0;
      const activeUsers = new Set<string>([...dauFocus.map((r: any) => r.userId), ...dauEvents.map((r: any) => r.userId)]).size;
      const premiumIds = new Set<string>(premiumSubs.map((s: any) => s.userId));
      const { monthly, yearly } = bucketLatestPaidByUser(paidSubOrders as any, premiumIds);
      const freeCount = Math.max(0, totalUsers - premiumIds.size);

      res.json({
        range,
        kpis: {
          revenue: { value: revenue, deltaPct: deltaPct(revenue, revenuePrev) },
          mrr: { value: computeMrr(monthly, yearly) },
          arpu: { value: arpu(revenue, activeUsers) },
          refundRate: { value: refundRate(refundedCount, paidCount) },
        },
        packages: [
          { code: 'free', label: 'Free', priceVnd: 0, subscribers: freeCount },
          { code: 'zen_pro_monthly', label: 'Zen Pro · Monthly', priceVnd: 29000, subscribers: monthly },
          { code: 'zen_pro_yearly', label: 'Zen Pro · Yearly', priceVnd: 279000, subscribers: yearly },
        ],
      });
    } catch (error) {
      next(error);
    }
  });

  // ---- manual-confirm a stuck (pending/review) order ----
  app.post('/admin/api/payments/:id/confirm', async (req: any, res: any, next: any) => {
    try {
      const admin = requireAdmin(req, 'moderator');
      const order = await adminConfirmOrder(req.params.id, admin.adminId);
      res.json(order);
    } catch (error) {
      next(error);
    }
  });

  // ---- shop catalog (list + edit) ----
  app.get('/admin/api/shop-items', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const items = await prisma.shopItem.findMany({ orderBy: { itemType: 'asc' } });
      res.json({ items });
    } catch (error) {
      next(error);
    }
  });

  app.put('/admin/api/shop-items/:id', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req, 'moderator');
      const { priceTokens, isActive, isHot } = req.body ?? {};
      const data: any = {};
      if (priceTokens !== undefined) data.priceTokens = Number(priceTokens);
      if (isActive !== undefined) data.isActive = Boolean(isActive);
      if (isHot !== undefined) data.isHot = Boolean(isHot);
      const item = await prisma.shopItem.update({ where: { id: req.params.id }, data });
      res.json(item);
    } catch (error) {
      next(error);
    }
  });

  // ---- task templates (read) ----
  app.get('/admin/api/tasks', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const items = await prisma.taskTemplate.findMany({ orderBy: { rewardTokens: 'asc' } });
      res.json({ items });
    } catch (error) {
      next(error);
    }
  });

  // ---- audit-ish feed derived from WalletTransaction (read-only) ----
  app.get('/admin/api/audit', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const tx = await prisma.walletTransaction.findMany({
        take: 25,
        orderBy: { createdAt: 'desc' },
        include: { user: { select: { displayName: true } } },
      });
      res.json({
        items: tx.map((t: any) => ({
          at: t.createdAt,
          actor: t.user?.displayName ?? '—',
          action: t.reason,
          entity: `${t.amount} ${t.currency}`,
          ref: t.refType ?? '',
        })),
      });
    } catch (error) {
      next(error);
    }
  });
}
