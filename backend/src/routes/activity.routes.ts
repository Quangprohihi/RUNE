import { Express } from 'express';

export function registerActivityRoutes(app: Express, deps: any) {
  const { prisma, requireUser } = deps;

  app.get('/activity-events', async (req, res, next) => {
    try {
      const userId = requireUser(req);
      const limit = Math.min(Number(req.query.limit ?? 50), 100);
      const events = await prisma.activityEvent.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit,
      });
      const focusSessions = await prisma.focusSession.findMany({
        where: { userId, status: 'completed' },
        orderBy: { completedAt: 'desc' },
        take: 60,
      });
      res.json({ events, focusSessions });
    } catch (error) {
      next(error);
    }
  });
}
