import { Express } from 'express';

export function registerNotificationRoutes(app: Express, deps: any) {
  const { prisma, requireUser } = deps;

  app.get('/notifications', async (req, res, next) => {
    try {
      const userId = requireUser(req);
      const notifications = await prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 50,
      });
      res.json(notifications);
    } catch (error) {
      next(error);
    }
  });

  app.post('/notifications/mark-all-read', async (req, res, next) => {
    try {
      const userId = requireUser(req);
      await prisma.notification.updateMany({
        where: { userId, isRead: false },
        data: { isRead: true },
      });
      res.json({ ok: true });
    } catch (error) {
      next(error);
    }
  });
}
