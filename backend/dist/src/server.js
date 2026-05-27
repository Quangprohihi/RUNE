"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const express_1 = __importDefault(require("express"));
const zod_1 = require("zod");
const prisma_1 = require("./prisma");
dotenv_1.default.config();
const app = (0, express_1.default)();
const port = Number(process.env.PORT ?? 3000);
app.use((0, cors_1.default)({ origin: process.env.CORS_ORIGIN ?? '*' }));
app.use(express_1.default.json());
const demoLoginSchema = zod_1.z.object({
    email: zod_1.z.string().email().optional().or(zod_1.z.literal('')),
    displayName: zod_1.z.string().optional(),
});
const startFocusSchema = zod_1.z.object({
    label: zod_1.z.string().min(1).default('Study'),
    plannedMinutes: zod_1.z.number().int().positive().default(25),
});
const completeFocusSchema = zod_1.z.object({
    actualSeconds: zod_1.z.number().int().nonnegative().default(0),
});
const petActionSchema = zod_1.z.object({
    action: zod_1.z.enum(['feed', 'play', 'pet']),
    cost: zod_1.z.number().int().nonnegative().default(0),
});
function currentUserId(req) {
    return req.header('x-user-id') ?? '';
}
function todayDate() {
    const now = new Date();
    return new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
}
function clampStat(value) {
    return Math.max(0, Math.min(100, value));
}
function plannedMinutesFromSeconds(seconds) {
    return Math.max(1, Math.round(seconds / 60));
}
function pomodoroCountForMinutes(minutes) {
    return minutes <= 25 ? 1 : 2;
}
function focusCategoryForLabel(label) {
    const value = label.toLowerCase();
    if (['english', 'vocabulary', 'ielts', 'toeic', 'listening', 'speaking'].some((keyword) => value.includes(keyword))) {
        return 'English';
    }
    if (['code', 'coding', 'flutter', 'programming', 'debug', 'api'].some((keyword) => value.includes(keyword))) {
        return 'Code';
    }
    if (['write', 'viết', 'report', 'essay', 'draft'].some((keyword) => value.includes(keyword))) {
        return 'Write';
    }
    if (['ôn', 'học', 'study', 'review', 'prm', 'exam', 'quiz'].some((keyword) => value.includes(keyword))) {
        return 'Review';
    }
    return 'Focus';
}
async function createDefaultsForUser(userId) {
    await prisma_1.prisma.pet.upsert({
        where: { userId },
        create: {
            userId,
            name: 'Kiki',
            species: 'Red Fox',
            level: 3,
            exp: 400,
            expToNext: 500,
            hunger: 72,
            energy: 80,
            mood: 76,
            love: 68,
        },
        update: {},
    });
    await prisma_1.prisma.wallet.upsert({
        where: { userId },
        create: { userId, tokens: 1234, energy: 5000, diamonds: 20 },
        update: {},
    });
    await prisma_1.prisma.userStreak.upsert({
        where: { userId },
        create: { userId, currentStreak: 0, bestStreak: 0 },
        update: {},
    });
}
async function createEventAndNotification(tx, userId, data) {
    await tx.activityEvent.create({
        data: {
            userId,
            eventType: data.eventType,
            title: data.title,
            subtitle: data.subtitle,
            icon: data.icon,
            metadata: data.metadata ?? {},
        },
    });
    if (data.notificationMessage) {
        await tx.notification.create({
            data: {
                userId,
                notificationType: data.notificationType ?? data.eventType,
                title: data.title,
                message: data.notificationMessage,
                icon: data.icon,
                metadata: data.metadata ?? {},
            },
        });
    }
}
async function ensureTodayTasks(userId) {
    const taskDate = todayDate();
    const templates = await prisma_1.prisma.taskTemplate.findMany({
        where: { isActive: true },
        orderBy: { code: 'asc' },
    });
    for (const template of templates) {
        const initialProgress = template.taskType === 'daily_login' ? 1 : 0;
        const dailyTask = await prisma_1.prisma.userDailyTask.upsert({
            where: {
                userId_templateId_taskDate: {
                    userId,
                    templateId: template.id,
                    taskDate,
                },
            },
            create: {
                userId,
                templateId: template.id,
                taskDate,
                progressValue: initialProgress,
                targetValue: template.targetValue,
                status: initialProgress >= template.targetValue ? 'completed' : 'active',
            },
            update: { targetValue: template.targetValue },
        });
        const nextProgress = Math.min(dailyTask.progressValue, template.targetValue);
        const nextStatus = dailyTask.status === 'claimed'
            ? 'claimed'
            : nextProgress >= template.targetValue
                ? 'completed'
                : 'active';
        if (nextProgress !== dailyTask.progressValue || nextStatus !== dailyTask.status) {
            await prisma_1.prisma.userDailyTask.update({
                where: { id: dailyTask.id },
                data: { progressValue: nextProgress, status: nextStatus },
            });
        }
    }
    return prisma_1.prisma.userDailyTask.findMany({
        where: { userId, taskDate },
        include: { template: true },
        orderBy: { template: { code: 'asc' } },
    });
}
async function updateTaskProgressForFocus(tx, userId, minutes, pomodoroCount) {
    const taskDate = todayDate();
    const tasks = await tx.userDailyTask.findMany({
        where: { userId, taskDate, status: { not: 'claimed' } },
        include: { template: true },
    });
    for (const task of tasks) {
        let increment = 0;
        if (task.template.taskType === 'focus_minutes')
            increment = minutes;
        if (task.template.taskType === 'pomodoro_count')
            increment = pomodoroCount;
        if (task.template.taskType === 'deep_focus' && minutes >= task.targetValue) {
            increment = task.targetValue;
        }
        if (increment <= 0)
            continue;
        const nextProgress = Math.min(task.targetValue, task.progressValue + increment);
        await tx.userDailyTask.update({
            where: { id: task.id },
            data: {
                progressValue: nextProgress,
                status: nextProgress >= task.targetValue ? 'completed' : 'active',
            },
        });
    }
}
async function updateStreakForToday(tx, userId) {
    const today = todayDate();
    const yesterday = new Date(today);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const streak = await tx.userStreak.upsert({
        where: { userId },
        create: {
            userId,
            currentStreak: 1,
            bestStreak: 1,
            lastFocusDate: today,
        },
        update: {},
    });
    if (streak.lastFocusDate?.getTime() === today.getTime())
        return streak;
    const nextStreak = streak.lastFocusDate?.getTime() === yesterday.getTime()
        ? streak.currentStreak + 1
        : 1;
    return tx.userStreak.update({
        where: { userId },
        data: {
            currentStreak: nextStreak,
            bestStreak: Math.max(streak.bestStreak, nextStreak),
            lastFocusDate: today,
        },
    });
}
async function bootstrap(userId) {
    await createDefaultsForUser(userId);
    await ensureTodayTasks(userId);
    const [user, pet, wallet, streak] = await Promise.all([
        prisma_1.prisma.user.findUniqueOrThrow({ where: { id: userId } }),
        prisma_1.prisma.pet.findUniqueOrThrow({ where: { userId } }),
        prisma_1.prisma.wallet.findUniqueOrThrow({ where: { userId } }),
        prisma_1.prisma.userStreak.findUniqueOrThrow({ where: { userId } }),
    ]);
    return { user, pet, wallet, streak };
}
function requireUser(req) {
    const userId = currentUserId(req);
    if (!userId) {
        const error = new Error('Missing x-user-id header');
        error.status = 401;
        throw error;
    }
    return userId;
}
app.get('/health', (_req, res) => {
    res.json({ ok: true });
});
app.post('/auth/demo-login', async (req, res, next) => {
    try {
        const body = demoLoginSchema.parse(req.body);
        const email = (body.email || 'friend@zenzoo.local').trim().toLowerCase();
        const displayName = body.displayName?.trim() ||
            email.split('@')[0].replace(/[._-]+/g, ' ') ||
            'Friend';
        const user = await prisma_1.prisma.user.upsert({
            where: { email },
            create: { email, displayName, provider: 'demo' },
            update: { displayName },
        });
        await createDefaultsForUser(user.id);
        const notificationCount = await prisma_1.prisma.notification.count({
            where: { userId: user.id },
        });
        if (notificationCount === 0) {
            await prisma_1.prisma.notification.create({
                data: {
                    userId: user.id,
                    notificationType: 'welcome',
                    title: 'Welcome back',
                    message: 'Kiki is ready to focus with you today.',
                    icon: '🦊',
                },
            });
        }
        res.json(await bootstrap(user.id));
    }
    catch (error) {
        next(error);
    }
});
app.get('/me/bootstrap', async (req, res, next) => {
    try {
        res.json(await bootstrap(requireUser(req)));
    }
    catch (error) {
        next(error);
    }
});
app.get('/daily-tasks/today', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const tasks = await ensureTodayTasks(userId);
        const milestones = await prisma_1.prisma.dailyMilestone.findMany({
            where: { isActive: true },
            orderBy: { pointsRequired: 'asc' },
        });
        const totalPoints = tasks
            .filter((task) => task.status === 'completed' || task.status === 'claimed')
            .reduce((sum, task) => sum + task.template.rewardPoints, 0);
        res.json({ tasks, milestones, totalPoints });
    }
    catch (error) {
        next(error);
    }
});
app.post('/daily-tasks/:id/claim', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const taskId = req.params.id;
        const result = await prisma_1.prisma.$transaction(async (tx) => {
            const task = await tx.userDailyTask.findFirstOrThrow({
                where: { id: taskId, userId },
                include: { template: true },
            });
            if (task.status === 'claimed')
                return { task, alreadyClaimed: true };
            if (task.progressValue < task.targetValue) {
                throw Object.assign(new Error('Task is not complete yet'), { status: 400 });
            }
            const claimed = await tx.userDailyTask.update({
                where: { id: task.id },
                data: { status: 'claimed', claimedAt: new Date() },
                include: { template: true },
            });
            const wallet = await tx.wallet.update({
                where: { userId },
                data: {
                    tokens: { increment: task.template.rewardTokens },
                    diamonds: { increment: task.template.rewardDiamonds },
                },
            });
            await tx.walletTransaction.create({
                data: {
                    userId,
                    currency: 'tokens',
                    amount: task.template.rewardTokens,
                    reason: `Daily task claimed: ${task.template.title}`,
                    refType: 'daily_task',
                    refId: task.id,
                },
            });
            await createEventAndNotification(tx, userId, {
                eventType: 'daily_task_claimed',
                title: `${task.template.title} claimed`,
                subtitle: `+${task.template.rewardTokens} tokens · +${task.template.rewardDiamonds} diamonds`,
                icon: '✅',
                notificationMessage: `Quest accomplished: ${task.template.title}. Reward claimed!`,
                metadata: { taskId: task.id },
            });
            return { task: claimed, wallet, alreadyClaimed: false };
        });
        res.json(result);
    }
    catch (error) {
        next(error);
    }
});
app.post('/focus-sessions/start', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const body = startFocusSchema.parse(req.body);
        const session = await prisma_1.prisma.focusSession.create({
            data: {
                userId,
                label: body.label,
                plannedMinutes: body.plannedMinutes,
                status: 'running',
            },
        });
        res.json(session);
    }
    catch (error) {
        next(error);
    }
});
app.post('/focus-sessions/:id/complete', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const body = completeFocusSchema.parse(req.body);
        const result = await prisma_1.prisma.$transaction(async (tx) => {
            const session = await tx.focusSession.findFirstOrThrow({
                where: { id: req.params.id, userId },
            });
            const minutes = session.plannedMinutes || plannedMinutesFromSeconds(body.actualSeconds);
            const pomodoroCount = pomodoroCountForMinutes(minutes);
            const category = focusCategoryForLabel(session.label);
            const rewardTokens = 20 + minutes;
            const rewardExp = 50;
            const updatedSession = await tx.focusSession.update({
                where: { id: session.id },
                data: {
                    actualSeconds: body.actualSeconds,
                    status: 'completed',
                    completedAt: new Date(),
                    claimedAt: new Date(),
                },
            });
            await updateTaskProgressForFocus(tx, userId, minutes, pomodoroCount);
            const streak = await updateStreakForToday(tx, userId);
            let pet = await tx.pet.findUniqueOrThrow({ where: { userId } });
            const totalExp = pet.exp + rewardExp;
            const leveledUp = totalExp >= pet.expToNext;
            pet = await tx.pet.update({
                where: { userId },
                data: {
                    level: leveledUp ? pet.level + 1 : pet.level,
                    exp: leveledUp ? totalExp - pet.expToNext : totalExp,
                    expToNext: leveledUp ? pet.expToNext + 100 : pet.expToNext,
                    mood: clampStat(pet.mood + 4),
                    love: clampStat(pet.love + 4),
                    energy: clampStat(pet.energy - Math.floor(minutes / 5)),
                    lastUpdatedAt: new Date(),
                },
            });
            const wallet = await tx.wallet.update({
                where: { userId },
                data: { tokens: { increment: rewardTokens } },
            });
            await tx.walletTransaction.create({
                data: {
                    userId,
                    currency: 'tokens',
                    amount: rewardTokens,
                    reason: `Focus reward: ${session.label}`,
                    refType: 'focus_session',
                    refId: session.id,
                },
            });
            await createEventAndNotification(tx, userId, {
                eventType: 'focus_completed',
                title: 'Focus session completed',
                subtitle: `${session.label} · ${minutes} minutes · +${rewardTokens} tokens · +${rewardExp} EXP`,
                icon: '⚡',
                notificationMessage: `Great focus session! You earned ${rewardTokens} tokens and Kiki gained EXP.`,
                metadata: {
                    focusSessionId: session.id,
                    goalLabel: session.label,
                    plannedMinutes: minutes,
                    pomodoroCount,
                    category,
                    rewardTokens,
                    rewardExp,
                },
            });
            return { session: updatedSession, pet, wallet, streak };
        });
        res.json(result);
    }
    catch (error) {
        next(error);
    }
});
app.get('/activity-events', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const limit = Math.min(Number(req.query.limit ?? 50), 100);
        const events = await prisma_1.prisma.activityEvent.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: limit,
        });
        const focusSessions = await prisma_1.prisma.focusSession.findMany({
            where: { userId, status: 'completed' },
            orderBy: { completedAt: 'desc' },
            take: 60,
        });
        res.json({ events, focusSessions });
    }
    catch (error) {
        next(error);
    }
});
app.get('/notifications', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const notifications = await prisma_1.prisma.notification.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            take: 50,
        });
        res.json(notifications);
    }
    catch (error) {
        next(error);
    }
});
app.post('/notifications/mark-all-read', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        await prisma_1.prisma.notification.updateMany({
            where: { userId, isRead: false },
            data: { isRead: true },
        });
        res.json({ ok: true });
    }
    catch (error) {
        next(error);
    }
});
app.get('/shop/items', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const [items, inventory] = await Promise.all([
            prisma_1.prisma.shopItem.findMany({
                where: { isActive: true },
                orderBy: { name: 'asc' },
            }),
            prisma_1.prisma.userInventory.findMany({ where: { userId } }),
        ]);
        res.json({ items, inventory });
    }
    catch (error) {
        next(error);
    }
});
app.post('/shop/items/:id/buy', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const itemId = req.params.id;
        const result = await prisma_1.prisma.$transaction(async (tx) => {
            const item = await tx.shopItem.findUniqueOrThrow({ where: { id: itemId } });
            const wallet = await tx.wallet.findUniqueOrThrow({ where: { userId } });
            if (wallet.tokens < item.priceTokens) {
                throw Object.assign(new Error('Not enough tokens'), { status: 400 });
            }
            const updatedWallet = await tx.wallet.update({
                where: { userId },
                data: { tokens: { decrement: item.priceTokens } },
            });
            await tx.walletTransaction.create({
                data: {
                    userId,
                    currency: 'tokens',
                    amount: -item.priceTokens,
                    reason: `Shop purchase: ${item.name}`,
                    refType: 'shop_item',
                    refId: item.id,
                },
            });
            await tx.userInventory.upsert({
                where: { userId_shopItemId: { userId, shopItemId: item.id } },
                create: { userId, shopItemId: item.id, quantity: 1 },
                update: { quantity: { increment: 1 } },
            });
            const currentPet = await tx.pet.findUniqueOrThrow({ where: { userId } });
            const pet = await tx.pet.update({
                where: { userId },
                data: {
                    [item.effectType]: clampStat(Number(currentPet[item.effectType]) +
                        item.effectValue),
                    lastUpdatedAt: new Date(),
                },
            });
            await createEventAndNotification(tx, userId, {
                eventType: 'shop_purchase',
                title: 'Shop purchase',
                subtitle: `${item.name} · ${item.priceTokens} tokens spent`,
                icon: item.emoji,
                notificationMessage: `${item.name} was applied to Kiki.`,
                metadata: { itemId: item.id },
            });
            return { item, wallet: updatedWallet, pet };
        });
        res.json(result);
    }
    catch (error) {
        next(error);
    }
});
app.post('/pet/actions', async (req, res, next) => {
    try {
        const userId = requireUser(req);
        const body = petActionSchema.parse(req.body);
        const config = {
            feed: { field: 'hunger', value: 20, title: 'Kiki was fed', icon: '🍎' },
            play: { field: 'mood', value: 18, title: 'Kiki played', icon: '⚽' },
            pet: { field: 'love', value: 16, title: 'Kiki was petted', icon: '❤️' },
        }[body.action];
        const result = await prisma_1.prisma.$transaction(async (tx) => {
            const wallet = await tx.wallet.findUniqueOrThrow({ where: { userId } });
            if (wallet.tokens < body.cost) {
                throw Object.assign(new Error('Not enough tokens'), { status: 400 });
            }
            const updatedWallet = await tx.wallet.update({
                where: { userId },
                data: { tokens: { decrement: body.cost } },
            });
            const currentPet = await tx.pet.findUniqueOrThrow({ where: { userId } });
            const pet = await tx.pet.update({
                where: { userId },
                data: {
                    [config.field]: clampStat(Number(currentPet[config.field]) +
                        config.value),
                    lastUpdatedAt: new Date(),
                },
            });
            if (body.cost > 0) {
                await tx.walletTransaction.create({
                    data: {
                        userId,
                        currency: 'tokens',
                        amount: -body.cost,
                        reason: `Pet action: ${body.action}`,
                    },
                });
            }
            await createEventAndNotification(tx, userId, {
                eventType: `pet_${body.action}`,
                title: config.title,
                subtitle: `${config.field} +${config.value}`,
                icon: config.icon,
                notificationMessage: `Kiki feels better: ${config.field} +${config.value}.`,
                metadata: { action: body.action },
            });
            return { pet, wallet: updatedWallet };
        });
        res.json(result);
    }
    catch (error) {
        next(error);
    }
});
app.use((error, _req, res, _next) => {
    const status = error.status ?? 500;
    if (status >= 500)
        console.error(error);
    res.status(status).json({ message: error.message || 'Server error' });
});
app.listen(port, () => {
    console.log(`ZenZoo API listening on port ${port}`);
});
