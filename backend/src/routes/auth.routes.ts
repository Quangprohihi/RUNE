import { Express } from 'express';

export function registerAuthRoutes(app: Express, deps: any) {
  const {
    authGoogleSchema,
    authLoginSchema,
    authRefreshSchema,
    authRegisterSchema,
    createDefaultsForUser,
    demoLoginSchema,
    hashPassword,
    issueAuthResponse,
    prisma,
    revokeRefreshToken,
    rotateRefreshToken,
    verifyGoogleIdToken,
    verifyPassword,
  } = deps;

  app.post('/auth/register', async (req, res, next) => {
    try {
      const body = authRegisterSchema.parse(req.body);
      const existing = await prisma.user.findUnique({
        where: { email: body.email },
      });
      if (existing) {
        throw Object.assign(new Error('Email is already registered'), {
          status: 409,
        });
      }

      const user = await prisma.user.create({
        data: {
          email: body.email,
          displayName: body.displayName,
          passwordHash: hashPassword(body.password),
          provider: 'password',
        },
      });
      await createDefaultsForUser(user.id);

      res.status(201).json(await issueAuthResponse(user.id));
    } catch (error) {
      next(error);
    }
  });

  app.post('/auth/login', async (req, res, next) => {
    try {
      const body = authLoginSchema.parse(req.body);
      const user = await prisma.user.findUnique({
        where: { email: body.email },
      });
      if (!user || !verifyPassword(body.password, user.passwordHash)) {
        throw Object.assign(new Error('Invalid email or password'), {
          status: 401,
        });
      }

      res.json(await issueAuthResponse(user.id));
    } catch (error) {
      next(error);
    }
  });

  app.post('/auth/google', async (req, res, next) => {
    try {
      const body = authGoogleSchema.parse(req.body);
      const payload = await verifyGoogleIdToken(body.idToken);
      const email = payload.email!.trim().toLowerCase();
      const displayName =
        payload.name?.trim() ||
        email.split('@')[0].replace(/[._-]+/g, ' ') ||
        'Friend';

      let user = await prisma.user.findFirst({
        where: {
          OR: [
            { provider: 'google', providerId: payload.sub },
            { email },
          ],
        },
      });

      if (user) {
        user = await prisma.user.update({
          where: { id: user.id },
          data: {
            provider: 'google',
            providerId: payload.sub,
            displayName: user.displayName || displayName,
            avatarUrl: user.avatarUrl ?? payload.picture ?? null,
          },
        });
      } else {
        user = await prisma.user.create({
          data: {
            email,
            displayName,
            provider: 'google',
            providerId: payload.sub,
            avatarUrl: payload.picture ?? null,
          },
        });
        await createDefaultsForUser(user.id);
      }

      res.json(await issueAuthResponse(user.id));
    } catch (error) {
      next(error);
    }
  });

  app.post('/auth/refresh', async (req, res, next) => {
    try {
      const body = authRefreshSchema.parse(req.body);
      const tokens = await rotateRefreshToken(body.refreshToken);
      res.json(tokens);
    } catch (error) {
      next(error);
    }
  });

  app.post('/auth/logout', async (req, res, next) => {
    try {
      const body = authRefreshSchema.parse(req.body);
      await revokeRefreshToken(body.refreshToken);
      res.json({ ok: true });
    } catch (error) {
      next(error);
    }
  });

  app.post('/auth/demo-login', async (req, res, next) => {
    try {
      const body = demoLoginSchema.parse(req.body);
      const email = (body.email || 'friend@zenzoo.local').trim().toLowerCase();
      const displayName =
        body.displayName?.trim() ||
        email.split('@')[0].replace(/[._-]+/g, ' ') ||
        'Friend';

      const user = await prisma.user.upsert({
        where: { email },
        create: { email, displayName, provider: 'demo' },
        update: { displayName },
      });
      await createDefaultsForUser(user.id);

      const notificationCount = await prisma.notification.count({
        where: { userId: user.id },
      });
      if (notificationCount === 0) {
        await prisma.notification.create({
          data: {
            userId: user.id,
            notificationType: 'welcome',
            title: 'Welcome back',
            message: 'Kiki is ready to focus with you today.',
            icon: '??',
          },
        });
      }

      res.json(await issueAuthResponse(user.id));
    } catch (error) {
      next(error);
    }
  });
}
