import cors from 'cors';
import crypto from 'crypto';
import express from 'express';
import { Prisma } from '@prisma/client';
import {
  revokeRefreshToken,
  rotateRefreshToken,
  verifyGoogleIdToken,
} from './auth';
import { prisma } from './prisma';
import { requireUser } from './middleware/auth.middleware';
import { errorHandler } from './middleware/error.middleware';
import {
  authGoogleSchema,
  authLoginSchema,
  authRefreshSchema,
  authRegisterSchema,
  demoLoginSchema,
} from './modules/auth/auth.schemas';
import {
  completeFocusSchema,
  focusPlanAnalyzeSchema,
  startFocusSchema,
} from './modules/focus/focus.schemas';
import { petActionSchema, selectPetSkinSchema } from './modules/pet/pet.schemas';
import { settingsSchema } from './modules/settings/settings.schemas';
import { registerActivityRoutes } from './routes/activity.routes';
import { registerAuthRoutes } from './routes/auth.routes';
import { registerHealthRoutes } from './routes/health.routes';
import { registerNotificationRoutes } from './routes/notifications.routes';
import { registerPaymentRoutes } from './routes/payments.routes';
import { issueAuthResponse as issueAuthServiceResponse } from './services/auth.service';


const productivePartnerAchievement = {
  code: 'productive_partner_i',
  title: 'Most Productive Partner I',
  rewardTokens: 100,
  rewardExp: 100,
  dailyGoalMinutes: 60,
  totalMinutesTarget: 300,
  streakTarget: 3,
};

const companionSkills = {
  kiki: {
    code: 'kiki',
    name: 'Kiki',
    skillName: 'Fast Learner',
    skillDescription: '+5% EXP',
  },
  companion_eagle: {
    code: 'companion_eagle',
    name: 'Eagle',
    skillName: 'Sharp Vision',
    skillDescription: '+10% tokens',
  },
  companion_frog: {
    code: 'companion_frog',
    name: 'Frog',
    skillName: 'Calm Mind',
    skillDescription: '20% less energy loss',
  },
  companion_giraffe: {
    code: 'companion_giraffe',
    name: 'Giraffe',
    skillName: 'Long Focus',
    skillDescription: '+10 tokens for 45+ min',
  },
} as const;

type CompanionCode = keyof typeof companionSkills;

const petEvolutionSkins = {
  standard: {
    code: 'standard',
    title: 'Standard',
    unlockLevel: 1,
    levelRange: 'Lv 1 - Lv 9',
  },
  spirit: {
    code: 'spirit',
    title: 'Spirit Form',
    unlockLevel: 10,
    levelRange: 'Lv 10 - Lv 29',
  },
  celestial: {
    code: 'celestial',
    title: 'Celestial Form',
    unlockLevel: 30,
    levelRange: 'Lv 30+',
  },
} as const;

type PetSkinCode = keyof typeof petEvolutionSkins;

const petDecayIntervalMs = 30 * 60 * 1000;
const maxPetDecayTicks = 24;

function todayDate() {
  const now = new Date();
  return new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
}

function clampStat(value: number) {
  return Math.max(0, Math.min(100, value));
}

function hashPassword(password: string) {
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = crypto.scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

function verifyPassword(password: string, storedHash?: string | null) {
  if (!storedHash) return false;
  const [salt, hash] = storedHash.split(':');
  if (!salt || !hash) return false;
  const candidate = crypto.scryptSync(password, salt, 64);
  const expected = Buffer.from(hash, 'hex');
  return (
    candidate.length === expected.length &&
    crypto.timingSafeEqual(candidate, expected)
  );
}

async function applyPetDecay(tx: Prisma.TransactionClient, userId: string) {
  const pet = await tx.pet.findUniqueOrThrow({ where: { userId } });
  const elapsedMs = Date.now() - pet.lastUpdatedAt.getTime();
  const ticks = Math.min(
    maxPetDecayTicks,
    Math.floor(elapsedMs / petDecayIntervalMs),
  );
  if (ticks <= 0) return pet;

  return tx.pet.update({
    where: { userId },
    data: {
      hunger: clampStat(pet.hunger - ticks * 2),
      mood: clampStat(pet.mood - ticks),
      love: clampStat(pet.love - ticks),
      lastUpdatedAt: new Date(),
    },
  });
}

function plannedMinutesFromSeconds(seconds: number) {
  return Math.max(1, Math.round(seconds / 60));
}

function pomodoroCountForMinutes(minutes: number) {
  return minutes <= 25 ? 1 : 2;
}

function normalizeCompanionCode(value?: string | null): CompanionCode {
  return value && value in companionSkills ? (value as CompanionCode) : 'kiki';
}

function normalizePetSkinCode(value?: string | null): PetSkinCode {
  return value && value in petEvolutionSkins
    ? (value as PetSkinCode)
    : 'standard';
}

function isPetSkinUnlocked(petLevel: number, skinCode: PetSkinCode) {
  return petLevel >= petEvolutionSkins[skinCode].unlockLevel;
}

async function resolveCompanionForFocus(
  tx: Prisma.TransactionClient,
  userId: string,
  requestedCode?: string | null,
) {
  const code = normalizeCompanionCode(requestedCode);
  if (code === 'kiki') return companionSkills.kiki;

  const owned = await tx.userInventory.findFirst({
    where: {
      userId,
      quantity: { gt: 0 },
      shopItem: {
        code,
        itemType: 'companion',
      },
    },
  });
  return owned ? companionSkills[code] : companionSkills.kiki;
}

function buildCompanionReward(
  companion: (typeof companionSkills)[CompanionCode],
  minutes: number,
  baseTokens: number,
  baseExp: number,
  baseEnergyLoss: number,
) {
  let bonusTokens = 0;
  let bonusExp = 0;
  let energySaved = 0;

  if (companion.code === 'kiki') {
    bonusExp = Math.ceil(baseExp * 0.05);
  } else if (companion.code === 'companion_eagle') {
    bonusTokens = Math.ceil(baseTokens * 0.1);
  } else if (companion.code === 'companion_frog') {
    energySaved = Math.ceil(baseEnergyLoss * 0.2);
  } else if (companion.code === 'companion_giraffe' && minutes >= 45) {
    bonusTokens = 10;
  }

  return {
    baseTokens,
    bonusTokens,
    rewardTokens: baseTokens + bonusTokens,
    baseExp,
    bonusExp,
    rewardExp: baseExp + bonusExp,
    baseEnergyLoss,
    energySaved,
    energyLoss: Math.max(0, baseEnergyLoss - energySaved),
  };
}

function normalizedText(value: string) {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/-?/g, 'd');
}

function containsAny(value: string, keywords: string[]) {
  const normalized = normalizedText(value);
  return keywords.some((keyword) => {
    const normalizedKeyword = normalizedText(keyword);
    if (normalizedKeyword.length <= 3) {
      const escaped = normalizedKeyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      return new RegExp(`(^|\\W)${escaped}(\\W|$)`).test(normalized);
    }
    return normalized.includes(normalizedKeyword);
  });
}

function focusCategoryForLabel(label: string) {
  if (containsAny(label, ['english', 'ti?+ng anh', 'tieng anh', 'vocabulary', 'ielts', 'toeic', 'listening', 'speaking'])) {
    return 'English';
  }
  if (containsAny(label, ['to+?n', 'toan', 'math', '-???o h+?m', 'dao ham', 'h+?nh h?+?c', 'dai so', '-???i s?+?'])) {
    return 'Math';
  }
  if (containsAny(label, ['ng?+? v-?n', 'ngu van', 'v-?n', 'literature', 'essay', '-??+?c hi?+?u', 'doc hieu'])) {
    return 'Literature';
  }
  if (containsAny(label, ['code', 'coding', 'flutter', 'programming', 'debug', 'api'])) {
    return 'Code';
  }
  if (containsAny(label, ['write', 'vi?+t', 'viet', 'report', 'essay', 'draft'])) {
    return 'Write';
  }
  if (containsAny(label, ['+?n', 'h?+?c', 'hoc', 'study', 'review', 'prm', 'exam', 'quiz', 'luy?+?n -??+?', 'luyen de'])) {
    return 'Review';
  }
  return 'Focus';
}

function detectSubjects(goal: string) {
  const subjects: string[] = [];
  const entries = [
    { name: 'Math', keywords: ['to+?n', 'toan', 'math', '-???o h+?m', 'dao ham', 'h+?nh h?+?c', 'hinh hoc', '-???i s?+?', 'dai so'] },
    { name: 'English', keywords: ['english', 'ti?+ng anh', 'tieng anh', 'ielts', 'toeic', 'vocabulary', 'speaking', 'listening'] },
    { name: 'Literature', keywords: ['ng?+? v-?n', 'ngu van', 'v-?n', 'literature', 'essay', '-??+?c hi?+?u', 'doc hieu'] },
    { name: 'Code', keywords: ['code', 'coding', 'flutter', 'programming', 'debug', 'api'] },
  ];
  for (const entry of entries) {
    if (containsAny(goal, entry.keywords)) subjects.push(entry.name);
  }
  return subjects.length > 0 ? subjects : ['General'];
}

function detectAction(goal: string) {
  if (containsAny(goal, ['l+?m', 'lam', 'b+?i', 'bai', 'practice', 'luy?+?n', 'luyen'])) return 'practice';
  if (containsAny(goal, ['+?n', 'review', 'ki?+?m tra', 'kiem tra'])) return 'review';
  if (containsAny(goal, ['thi', 'exam', 'quiz', 'luy?+?n -??+?', 'luyen de'])) return 'exam';
  if (containsAny(goal, ['vi?+t', 'viet', 'write', 'essay', 'draft'])) return 'write';
  if (containsAny(goal, ['-??+?c', 'doc', 'read'])) return 'read';
  return 'study';
}

function detectDuration(goal: string) {
  const normalized = normalizedText(goal);
  const minuteMatch = normalized.match(/(\d+)\s*(phut|p|min|minute|minutes)\b/);
  if (minuteMatch) return Number(minuteMatch[1]);
  const hourMatch = normalized.match(/(\d+)\s*(tieng|gio|h|hour|hours)\b/);
  if (hourMatch) return Number(hourMatch[1]) * 60;
  return null;
}

function detectQuantity(goal: string) {
  const normalized = normalizedText(goal);
  const match = normalized.match(/(\d+)\s*(bai|tu|de|chuong|topic|question|questions)\b/);
  return match ? { value: Number(match[1]), unit: match[2] } : null;
}

function detectTopic(goal: string, subjects: string[]) {
  const normalized = normalizedText(goal);
  const topicKeywords = ['chuong', 'phan', 'dao ham', 'hinh hoc', 'dai so', 'vocabulary', 'speaking', 'listening', 'doc hieu'];
  const found = topicKeywords.find((keyword) => normalized.includes(keyword));
  if (found) return found.replace(/\b\w/g, (char) => char.toUpperCase());
  return subjects[0] === 'General' ? 'Focus Goal' : subjects[0];
}

function detectClarity(goal: string, duration: number | null, quantity: { value: number; unit: string } | null, subjects: string[]) {
  const normalized = normalizedText(goal);
  const hasSpecificTopic = ['chuong', 'phan', 'dao ham', 'hinh hoc', 'dai so', 'speaking', 'listening', 'vocabulary'].some((keyword) =>
    normalized.includes(keyword),
  );
  if (duration || quantity) return 'detailed';
  if (hasSpecificTopic || subjects.length > 1) return 'medium';
  return 'vague';
}

function focusModeFor(action: string, clarityLevel: string, subjects: string[]) {
  if (action === 'review' || action === 'exam') return 'Review + Practice';
  if (action === 'practice') return 'Practice Focus';
  if (action === 'write' || subjects.includes('Code')) return 'Deep Focus';
  if (clarityLevel === 'vague') return 'Practice Focus';
  return 'Focused Study';
}

function recommendedMinutesFor(duration: number | null, clarityLevel: string, action: string) {
  if (duration) return Math.max(10, Math.min(duration, 120));
  if (clarityLevel === 'detailed') return 50;
  if (action === 'review') return 25;
  return 45;
}

function buildFocusPlan(goal: string, selectedMinutes?: number, selectedTask?: string) {
  const subjects = detectSubjects(goal);
  const action = detectAction(goal || selectedTask || '');
  const duration = detectDuration(goal);
  const quantity = detectQuantity(goal);
  const clarityLevel = detectClarity(goal, duration, quantity, subjects);
  const recommendedMinutes = recommendedMinutesFor(duration ?? selectedMinutes ?? null, clarityLevel, action);
  const focusMode = focusModeFor(action, clarityLevel, subjects);
  const subject = subjects.join(' + ');
  const topic = detectTopic(goal, subjects);
  const normalizedLabel = subject === 'General' ? goal.trim() : `${subject} - ${focusMode}`;
  const warnings: string[] = [];
  if (clarityLevel === 'vague') {
    warnings.push('Goal is broad. Pick one small topic before starting to avoid multitasking.');
  }
  if (subjects.length > 1) {
    warnings.push('Multiple subjects detected. Use this session for the first priority, then start another session.');
  }

  const prepMinutes = clarityLevel === 'vague' ? 5 : 3;
  const reviewMinutes = recommendedMinutes >= 45 ? 10 : 5;
  const workMinutes = Math.max(10, recommendedMinutes - prepMinutes - reviewMinutes);
  const quantityText = quantity ? ` Aim for ${quantity.value} ${quantity.unit}.` : '';
  const steps = [
    `${prepMinutes} min: choose one clear ${topic} target and remove distractions.`,
    `${workMinutes} min: stay on one ${focusMode.toLowerCase()} block.${quantityText}`,
    `${reviewMinutes} min: mark what worked, what felt hard, and the next focus step.`,
  ];

  return {
    normalizedLabel,
    subject,
    subjects,
    action,
    topic,
    clarityLevel,
    focusMode,
    recommendedMinutes,
    pomodoroCount: pomodoroCountForMinutes(recommendedMinutes),
    advice:
      clarityLevel === 'vague'
        ? 'Start with a small practice block instead of trying to master the whole subject at once.'
        : 'Use the timer to protect one clear learning block and review mistakes before stopping.',
    steps,
    warnings,
  };
}

async function createDefaultsForUser(userId: string) {
  await prisma.pet.upsert({
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

  await prisma.wallet.upsert({
    where: { userId },
    create: { userId, tokens: 1234, energy: 5000, diamonds: 20 },
    update: {},
  });

  await prisma.userStreak.upsert({
    where: { userId },
    create: { userId, currentStreak: 0, bestStreak: 0 },
    update: {},
  });

  await prisma.userSettings.upsert({
    where: { userId },
    create: { userId },
    update: {},
  });

  await prisma.subscription.upsert({
    where: { userId },
    create: { userId },
    update: {},
  });
}

async function createEventAndNotification(
  tx: Prisma.TransactionClient,
  userId: string,
  data: {
    eventType: string;
    title: string;
    subtitle: string;
    icon: string;
    notificationType?: string;
    notificationMessage?: string;
    metadata?: Prisma.InputJsonValue;
  },
) {
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

async function buildProductivePartnerAchievement(
  tx: Prisma.TransactionClient,
  userId: string,
) {
  const [sessions, streak, claimed] = await Promise.all([
    tx.focusSession.findMany({
      where: { userId, status: 'completed' },
      select: { plannedMinutes: true, completedAt: true },
    }),
    tx.userStreak.findUnique({ where: { userId } }),
    tx.userAchievement.findUnique({
      where: {
        userId_code: {
          userId,
          code: productivePartnerAchievement.code,
        },
      },
    }),
  ]);

  const sessionsCompleted = sessions.length;
  const totalFocusMinutes = sessions.reduce(
    (sum, session) => sum + session.plannedMinutes,
    0,
  );
  const focusMinutesByDay = new Map<string, number>();
  for (const session of sessions) {
    const day = (session.completedAt ?? new Date()).toISOString().slice(0, 10);
    focusMinutesByDay.set(
      day,
      (focusMinutesByDay.get(day) ?? 0) + session.plannedMinutes,
    );
  }
  const dailyGoalCompletedCount = Array.from(focusMinutesByDay.values()).filter(
    (minutes) => minutes >= productivePartnerAchievement.dailyGoalMinutes,
  ).length;
  const currentStreak = streak?.currentStreak ?? 0;

  const finalTaskCompleted =
    totalFocusMinutes >= productivePartnerAchievement.totalMinutesTarget ||
    currentStreak >= productivePartnerAchievement.streakTarget;
  const tasks = [
    {
      code: 'first_focus_session',
      title: 'Complete 1 focus session',
      current: Math.min(sessionsCompleted, 1),
      target: 1,
      completed: sessionsCompleted >= 1,
    },
    {
      code: 'sixty_focus_minutes',
      title: 'Reach 60 total focus minutes',
      current: Math.min(totalFocusMinutes, 60),
      target: 60,
      completed: totalFocusMinutes >= 60,
    },
    {
      code: 'three_focus_sessions',
      title: 'Complete 3 focus sessions',
      current: Math.min(sessionsCompleted, 3),
      target: 3,
      completed: sessionsCompleted >= 3,
    },
    {
      code: 'daily_goal_once',
      title: "Complete today's goal once",
      current: Math.min(dailyGoalCompletedCount, 1),
      target: 1,
      completed: dailyGoalCompletedCount >= 1,
    },
    {
      code: 'productive_partner_target',
      title: 'Reach 300 total minutes or 3-day streak',
      current: finalTaskCompleted
        ? productivePartnerAchievement.totalMinutesTarget
        : Math.min(totalFocusMinutes, productivePartnerAchievement.totalMinutesTarget),
      target: productivePartnerAchievement.totalMinutesTarget,
      completed: finalTaskCompleted,
    },
  ];
  const stars = tasks.filter((task) => task.completed).length;

  return {
    code: productivePartnerAchievement.code,
    title: productivePartnerAchievement.title,
    tier: 1,
    stars,
    maxStars: tasks.length,
    isComplete: stars >= tasks.length,
    isClaimed: Boolean(claimed),
    claimedAt: claimed?.claimedAt ?? null,
    rewardTokens: productivePartnerAchievement.rewardTokens,
    rewardExp: productivePartnerAchievement.rewardExp,
    stats: {
      sessionsCompleted,
      totalFocusMinutes,
      dailyGoalCompletedCount,
      currentStreak,
    },
    tasks,
  };
}

async function addExpToPet(
  tx: Prisma.TransactionClient,
  userId: string,
  exp: number,
) {
  let pet = await tx.pet.findUniqueOrThrow({ where: { userId } });
  const totalExp = pet.exp + exp;
  const leveledUp = totalExp >= pet.expToNext;
  pet = await tx.pet.update({
    where: { userId },
    data: {
      level: leveledUp ? pet.level + 1 : pet.level,
      exp: leveledUp ? totalExp - pet.expToNext : totalExp,
      expToNext: leveledUp ? pet.expToNext + 100 : pet.expToNext,
      mood: clampStat(pet.mood + 4),
      love: clampStat(pet.love + 4),
      lastUpdatedAt: new Date(),
    },
  });
  return pet;
}

async function ensureTodayTasks(userId: string) {
  const taskDate = todayDate();
  const templates = await prisma.taskTemplate.findMany({
    where: { isActive: true },
    orderBy: { code: 'asc' },
  });

  for (const template of templates) {
    const initialProgress = template.taskType === 'daily_login' ? 1 : 0;
    const dailyTask = await prisma.userDailyTask.upsert({
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
    const nextStatus =
      dailyTask.status === 'claimed'
        ? 'claimed'
        : nextProgress >= template.targetValue
          ? 'completed'
          : 'active';
    if (nextProgress !== dailyTask.progressValue || nextStatus !== dailyTask.status) {
      await prisma.userDailyTask.update({
        where: { id: dailyTask.id },
        data: { progressValue: nextProgress, status: nextStatus },
      });
    }
  }

  return prisma.userDailyTask.findMany({
    where: { userId, taskDate },
    include: { template: true },
    orderBy: { template: { code: 'asc' } },
  });
}

async function updateTaskProgressForFocus(
  tx: Prisma.TransactionClient,
  userId: string,
  minutes: number,
  pomodoroCount: number,
) {
  const taskDate = todayDate();
  const tasks = await tx.userDailyTask.findMany({
    where: { userId, taskDate, status: { not: 'claimed' } },
    include: { template: true },
  });

  for (const task of tasks) {
    let increment = 0;
    if (task.template.taskType === 'focus_minutes') increment = minutes;
    if (task.template.taskType === 'pomodoro_count') increment = pomodoroCount;
    if (task.template.taskType === 'deep_focus' && minutes >= task.targetValue) {
      increment = task.targetValue;
    }
    if (increment <= 0) continue;

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

async function updateStreakForToday(tx: Prisma.TransactionClient, userId: string) {
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

  if (streak.lastFocusDate?.getTime() === today.getTime()) return streak;

  const nextStreak =
    streak.lastFocusDate?.getTime() === yesterday.getTime()
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

function totalDailyTaskPoints(tasks: Awaited<ReturnType<typeof ensureTodayTasks>>) {
  return tasks
    .filter((task) => task.status === 'claimed')
    .reduce((sum, task) => sum + task.template.rewardPoints, 0);
}

async function bootstrap(userId: string) {
  await createDefaultsForUser(userId);
  await ensureTodayTasks(userId);
  await prisma.$transaction((tx) => applyPetDecay(tx, userId));

  const [user, pet, wallet, streak] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: userId } }),
    prisma.pet.findUniqueOrThrow({ where: { userId } }),
    prisma.wallet.findUniqueOrThrow({ where: { userId } }),
    prisma.userStreak.findUniqueOrThrow({ where: { userId } }),
  ]);

  return { user, pet, wallet, streak };
}

async function issueAuthResponse(userId: string) {
  return issueAuthServiceResponse(userId, bootstrap);
}


export function createApp() {
  const app = express();

  app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }));
  app.use(express.json());

  registerHealthRoutes(app);
  registerAuthRoutes(app, {
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
  });
  registerPaymentRoutes(app, { requireUser });
app.get('/me/bootstrap', async (req, res, next) => {
  try {
    res.json(await bootstrap(requireUser(req)));
  } catch (error) {
    next(error);
  }
});

app.get('/me/settings', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    await createDefaultsForUser(userId);
    const [settings, user, subscription] = await Promise.all([
      prisma.userSettings.findUniqueOrThrow({ where: { userId } }),
      prisma.user.findUniqueOrThrow({ where: { id: userId } }),
      prisma.subscription.findUniqueOrThrow({ where: { userId } }),
    ]);
    res.json({ settings, user, subscription });
  } catch (error) {
    next(error);
  }
});

app.patch('/me/settings', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const body = settingsSchema.parse(req.body);
    await createDefaultsForUser(userId);
    const settings = await prisma.userSettings.update({
      where: { userId },
      data: body,
    });
    res.json(settings);
  } catch (error) {
    next(error);
  }
});

app.get('/me/subscription', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    await createDefaultsForUser(userId);
    res.json(await prisma.subscription.findUniqueOrThrow({ where: { userId } }));
  } catch (error) {
    next(error);
  }
});

app.post('/me/subscription/demo-upgrade', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    await createDefaultsForUser(userId);
    const expiresAt = new Date();
    expiresAt.setUTCDate(expiresAt.getUTCDate() + 30);
    const subscription = await prisma.subscription.update({
      where: { userId },
      data: { plan: 'premium', status: 'active', expiresAt },
    });
    res.json(subscription);
  } catch (error) {
    next(error);
  }
});

app.get('/analytics/summary', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const now = new Date();
    const today = todayDate();
    const tomorrow = new Date(today);
    tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
    const sevenDaysAgo = new Date(today);
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 6);

    const [sessions, events, streak] = await Promise.all([
      prisma.focusSession.findMany({
        where: { userId, status: 'completed', completedAt: { gte: sevenDaysAgo } },
        orderBy: { completedAt: 'asc' },
      }),
      prisma.activityEvent.findMany({
        where: {
          userId,
          eventType: 'focus_completed',
          createdAt: { gte: sevenDaysAgo },
        },
        orderBy: { createdAt: 'desc' },
      }),
      prisma.userStreak.findUnique({ where: { userId } }),
    ]);

    const allSessions = await prisma.focusSession.findMany({
      where: { userId, status: 'completed' },
      select: { plannedMinutes: true, completedAt: true },
    });
    const totalFocusMinutes = allSessions.reduce((sum, session) => sum + session.plannedMinutes, 0);
    const sessionsToday = allSessions.filter((session) => {
      const completedAt = session.completedAt ?? now;
      return completedAt >= today && completedAt < tomorrow;
    }).length;
    const pomodorosToday = sessions
      .filter((session) => {
        const completedAt = session.completedAt ?? now;
        return completedAt >= today && completedAt < tomorrow;
      })
      .reduce((sum, session) => sum + pomodoroCountForMinutes(session.plannedMinutes), 0);
    const pomodorosThisWeek = sessions.reduce(
      (sum, session) => sum + pomodoroCountForMinutes(session.plannedMinutes),
      0,
    );

    const focusByDay = Array.from({ length: 7 }, (_, index) => {
      const day = new Date(sevenDaysAgo);
      day.setUTCDate(sevenDaysAgo.getUTCDate() + index);
      const nextDay = new Date(day);
      nextDay.setUTCDate(day.getUTCDate() + 1);
      const minutes = sessions
        .filter((session) => {
          const completedAt = session.completedAt ?? now;
          return completedAt >= day && completedAt < nextDay;
        })
        .reduce((sum, session) => sum + session.plannedMinutes, 0);
      return { date: day.toISOString().slice(0, 10), minutes };
    });

    const categoryTotals = new Map<string, number>();
    for (const event of events) {
      const metadata = event.metadata as { category?: string; plannedMinutes?: number };
      const category = metadata.category ?? 'Focus';
      categoryTotals.set(category, (categoryTotals.get(category) ?? 0) + (metadata.plannedMinutes ?? 0));
    }
    const categoryBreakdown = Array.from(categoryTotals.entries()).map(([category, minutes]) => ({
      category,
      minutes,
    }));

    res.json({
      totalFocusMinutes,
      sessionsToday,
      pomodorosToday,
      pomodorosThisWeek,
      currentStreak: streak?.currentStreak ?? 0,
      bestStreak: streak?.bestStreak ?? 0,
      focusByDay,
      categoryBreakdown,
    });
  } catch (error) {
    next(error);
  }
});

app.get('/achievements', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    await createDefaultsForUser(userId);
    const productivePartner = await prisma.$transaction((tx) =>
      buildProductivePartnerAchievement(tx, userId),
    );
    res.json({ achievements: [productivePartner] });
  } catch (error) {
    next(error);
  }
});

app.post('/achievements/:code/claim', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const code = req.params.code;
    if (code !== productivePartnerAchievement.code) {
      throw Object.assign(new Error('Unknown achievement'), { status: 404 });
    }

    const result = await prisma.$transaction(async (tx) => {
      const progress = await buildProductivePartnerAchievement(tx, userId);
      const existingClaim = await tx.userAchievement.findUnique({
        where: {
          userId_code: {
            userId,
            code,
          },
        },
      });
      if (existingClaim) {
        const [wallet, pet] = await Promise.all([
          tx.wallet.findUniqueOrThrow({ where: { userId } }),
          tx.pet.findUniqueOrThrow({ where: { userId } }),
        ]);
        return {
          achievement: { ...progress, isClaimed: true, claimedAt: existingClaim.claimedAt },
          wallet,
          pet,
          alreadyClaimed: true,
        };
      }
      if (!progress.isComplete) {
        throw Object.assign(new Error('Achievement is not complete yet'), {
          status: 400,
        });
      }

      const claimed = await tx.userAchievement.create({
        data: { userId, code },
      });
      const wallet = await tx.wallet.update({
        where: { userId },
        data: { tokens: { increment: productivePartnerAchievement.rewardTokens } },
      });
      const pet = await addExpToPet(
        tx,
        userId,
        productivePartnerAchievement.rewardExp,
      );
      await tx.walletTransaction.create({
        data: {
          userId,
          currency: 'tokens',
          amount: productivePartnerAchievement.rewardTokens,
          reason: `Achievement claimed: ${productivePartnerAchievement.title}`,
          refType: 'achievement',
          refId: claimed.id,
        },
      });
      await createEventAndNotification(tx, userId, {
        eventType: 'achievement_claimed',
        title: `${productivePartnerAchievement.title} unlocked`,
        subtitle: `+${productivePartnerAchievement.rewardTokens} tokens -+ +${productivePartnerAchievement.rewardExp} EXP`,
        icon: '=???',
        notificationMessage: `${productivePartnerAchievement.title} unlocked! Kiki earned a new badge.`,
        metadata: {
          achievementCode: code,
          rewardTokens: productivePartnerAchievement.rewardTokens,
          rewardExp: productivePartnerAchievement.rewardExp,
        },
      });

      return {
        achievement: { ...progress, isClaimed: true, claimedAt: claimed.claimedAt },
        wallet,
        pet,
        alreadyClaimed: false,
      };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/focus-plans/analyze', async (req, res, next) => {
  try {
    requireUser(req);
    const body = focusPlanAnalyzeSchema.parse(req.body);
    res.json(buildFocusPlan(body.goal, body.selectedMinutes, body.selectedTask));
  } catch (error) {
    next(error);
  }
});

app.get('/daily-tasks/today', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const taskDate = todayDate();
    const tasks = await ensureTodayTasks(userId);
    const [milestones, claimedMilestones] = await Promise.all([
      prisma.dailyMilestone.findMany({
        where: { isActive: true },
        orderBy: { pointsRequired: 'asc' },
      }),
      prisma.userDailyMilestone.findMany({
        where: { userId, taskDate },
      }),
    ]);
    const claimedByMilestoneId = new Map(
      claimedMilestones.map((claim) => [claim.milestoneId, claim]),
    );
    const totalPoints = totalDailyTaskPoints(tasks);
    const milestonesWithClaimState = milestones.map((milestone) => {
      const claim = claimedByMilestoneId.get(milestone.id);
      return {
        ...milestone,
        isClaimed: Boolean(claim?.claimedAt),
        claimedAt: claim?.claimedAt ?? null,
      };
    });
    res.json({ tasks, milestones: milestonesWithClaimState, totalPoints });
  } catch (error) {
    next(error);
  }
});

app.post('/daily-tasks/:id/claim', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const taskId = req.params.id;

    const result = await prisma.$transaction(async (tx) => {
      const task = await tx.userDailyTask.findFirstOrThrow({
        where: { id: taskId, userId },
        include: { template: true },
      });
      if (task.status === 'claimed') return { task, alreadyClaimed: true };
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
        subtitle: `+${task.template.rewardTokens} tokens -+ +${task.template.rewardDiamonds} diamonds`,
        icon: 'G??',
        notificationMessage: `Quest accomplished: ${task.template.title}. Reward claimed!`,
        metadata: { taskId: task.id },
      });
      return { task: claimed, wallet, alreadyClaimed: false };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/daily-milestones/:id/claim', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const milestoneId = req.params.id;
    const taskDate = todayDate();

    const result = await prisma.$transaction(async (tx) => {
      const [milestone, tasks] = await Promise.all([
        tx.dailyMilestone.findFirstOrThrow({
          where: { id: milestoneId, isActive: true },
        }),
        tx.userDailyTask.findMany({
          where: { userId, taskDate },
          include: { template: true },
        }),
      ]);
      const totalPoints = tasks
        .filter((task) => task.status === 'claimed')
        .reduce((sum, task) => sum + task.template.rewardPoints, 0);
      if (totalPoints < milestone.pointsRequired) {
        throw Object.assign(new Error('Not enough daily points yet'), {
          status: 400,
        });
      }

      const existingClaim = await tx.userDailyMilestone.findUnique({
        where: {
          userId_milestoneId_taskDate: { userId, milestoneId, taskDate },
        },
      });
      if (existingClaim?.claimedAt) {
        const wallet = await tx.wallet.findUniqueOrThrow({ where: { userId } });
        return {
          milestone: { ...milestone, isClaimed: true, claimedAt: existingClaim.claimedAt },
          wallet,
          totalPoints,
          alreadyClaimed: true,
        };
      }

      const claim = await tx.userDailyMilestone.upsert({
        where: {
          userId_milestoneId_taskDate: { userId, milestoneId, taskDate },
        },
        create: { userId, milestoneId, taskDate, claimedAt: new Date() },
        update: { claimedAt: new Date() },
      });
      const wallet = await tx.wallet.update({
        where: { userId },
        data: {
          tokens: { increment: milestone.rewardTokens },
          diamonds: { increment: milestone.rewardDiamonds },
        },
      });
      if (milestone.rewardTokens > 0) {
        await tx.walletTransaction.create({
          data: {
            userId,
            currency: 'tokens',
            amount: milestone.rewardTokens,
            reason: `Daily milestone claimed: ${milestone.pointsRequired} pts`,
            refType: 'daily_milestone',
            refId: milestone.id,
          },
        });
      }
      if (milestone.rewardDiamonds > 0) {
        await tx.walletTransaction.create({
          data: {
            userId,
            currency: 'diamonds',
            amount: milestone.rewardDiamonds,
            reason: `Daily milestone claimed: ${milestone.pointsRequired} pts`,
            refType: 'daily_milestone',
            refId: milestone.id,
          },
        });
      }
      await createEventAndNotification(tx, userId, {
        eventType: 'daily_milestone_claimed',
        title: `${milestone.pointsRequired} pts reward claimed`,
        subtitle: `+${milestone.rewardTokens} tokens -+ +${milestone.rewardDiamonds} diamonds`,
        icon: '=???',
        notificationMessage: `Daily milestone reached: ${milestone.pointsRequired} pts reward claimed!`,
        metadata: { milestoneId: milestone.id, pointsRequired: milestone.pointsRequired },
      });
      return {
        milestone: { ...milestone, isClaimed: true, claimedAt: claim.claimedAt },
        wallet,
        totalPoints,
        alreadyClaimed: false,
      };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/focus-sessions/start', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const body = startFocusSchema.parse(req.body);
    const session = await prisma.focusSession.create({
      data: {
        userId,
        label: body.label,
        plannedMinutes: body.plannedMinutes,
        companionCode: normalizeCompanionCode(body.companionCode),
        status: 'running',
      },
    });
    res.json(session);
  } catch (error) {
    next(error);
  }
});

app.post('/focus-sessions/:id/complete', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const body = completeFocusSchema.parse(req.body);

    const result = await prisma.$transaction(async (tx) => {
      const session = await tx.focusSession.findFirstOrThrow({
        where: { id: req.params.id, userId },
      });
      const minutes = session.plannedMinutes || plannedMinutesFromSeconds(body.actualSeconds);
      const pomodoroCount = pomodoroCountForMinutes(minutes);
      const category = focusCategoryForLabel(session.label);
      const companion = await resolveCompanionForFocus(
        tx,
        userId,
        session.companionCode,
      );
      const rewardBreakdown = buildCompanionReward(
        companion,
        minutes,
        20 + minutes,
        50,
        Math.floor(minutes / 5),
      );
      const rewardTokens = rewardBreakdown.rewardTokens;
      const rewardExp = rewardBreakdown.rewardExp;

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

      let pet = await applyPetDecay(tx, userId);
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
          energy: clampStat(pet.energy - rewardBreakdown.energyLoss),
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
        subtitle: `${session.label} -+ ${minutes} minutes -+ +${rewardTokens} tokens -+ +${rewardExp} EXP`,
        icon: 'G??',
        notificationMessage: `Great focus session! ${companion.name}'s ${companion.skillName} helped your reward.`,
        metadata: {
          focusSessionId: session.id,
          goalLabel: session.label,
          plannedMinutes: minutes,
          pomodoroCount,
          category,
          rewardTokens,
          rewardExp,
          companionCode: companion.code,
          companionName: companion.name,
          skillName: companion.skillName,
          skillDescription: companion.skillDescription,
          bonusTokens: rewardBreakdown.bonusTokens,
          bonusExp: rewardBreakdown.bonusExp,
          energySaved: rewardBreakdown.energySaved,
        },
      });

      return {
        session: updatedSession,
        pet,
        wallet,
        streak,
        rewardTokens,
        rewardExp,
        baseRewardTokens: rewardBreakdown.baseTokens,
        bonusTokens: rewardBreakdown.bonusTokens,
        baseRewardExp: rewardBreakdown.baseExp,
        bonusExp: rewardBreakdown.bonusExp,
        baseEnergyLoss: rewardBreakdown.baseEnergyLoss,
        energySaved: rewardBreakdown.energySaved,
        companionCode: companion.code,
        companionName: companion.name,
        skillName: companion.skillName,
        skillDescription: companion.skillDescription,
        rewardBreakdown,
        category,
        pomodoroCount,
      };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

  registerActivityRoutes(app, { prisma, requireUser });
  registerNotificationRoutes(app, { prisma, requireUser });
app.get('/shop/items', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const [items, inventory] = await Promise.all([
      prisma.shopItem.findMany({
        where: { isActive: true },
        orderBy: { name: 'asc' },
      }),
      prisma.userInventory.findMany({ where: { userId } }),
    ]);
    res.json({ items, inventory });
  } catch (error) {
    next(error);
  }
});

app.post('/shop/items/:id/buy', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const itemId = req.params.id;

    const result = await prisma.$transaction(async (tx) => {
      const item = await tx.shopItem.findUniqueOrThrow({ where: { id: itemId } });
      const existingInventory = await tx.userInventory.findUnique({
        where: { userId_shopItemId: { userId, shopItemId: item.id } },
      });
      if (item.itemType === 'companion' && existingInventory) {
        const [wallet, pet, inventory] = await Promise.all([
          tx.wallet.findUniqueOrThrow({ where: { userId } }),
          tx.pet.findUniqueOrThrow({ where: { userId } }),
          tx.userInventory.findMany({ where: { userId } }),
        ]);
        return { item, wallet, pet, inventory };
      }

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
      const pet = await tx.pet.findUniqueOrThrow({ where: { userId } });
      await createEventAndNotification(tx, userId, {
        eventType: 'shop_purchase',
        title: 'Shop purchase',
        subtitle: `${item.name} -+ ${item.priceTokens} tokens spent`,
        icon: item.emoji,
        notificationMessage:
          item.itemType === 'companion'
            ? `${item.name} joined your habitat.`
            : `${item.name} was added to your inventory.`,
        metadata: { itemId: item.id },
      });
      const inventory = await tx.userInventory.findMany({ where: { userId } });
      return { item, wallet: updatedWallet, pet, inventory };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/shop/items/:id/use', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const itemId = req.params.id;

    const result = await prisma.$transaction(async (tx) => {
      const item = await tx.shopItem.findUniqueOrThrow({ where: { id: itemId } });
      if (item.itemType === 'companion' || item.effectValue <= 0) {
        throw Object.assign(new Error('This item cannot be used here'), {
          status: 400,
        });
      }

      const inventory = await tx.userInventory.findUnique({
        where: { userId_shopItemId: { userId, shopItemId: item.id } },
      });
      if (!inventory || inventory.quantity <= 0) {
        throw Object.assign(new Error('You do not own this item'), {
          status: 400,
        });
      }

      const currentPet = await applyPetDecay(tx, userId);
      const currentValue = Number(
        currentPet[item.effectType as keyof typeof currentPet],
      );
      if (currentValue >= 100) {
        throw Object.assign(new Error(`${item.effectType} is already full`), {
          status: 400,
        });
      }

      const pet = await tx.pet.update({
        where: { userId },
        data: {
          [item.effectType]: clampStat(currentValue + item.effectValue),
          lastUpdatedAt: new Date(),
        },
      });
      if (inventory.quantity <= 1) {
        await tx.userInventory.delete({ where: { id: inventory.id } });
      } else {
        await tx.userInventory.update({
          where: { id: inventory.id },
          data: { quantity: { decrement: 1 } },
        });
      }

      await createEventAndNotification(tx, userId, {
        eventType: 'shop_item_used',
        title: `${item.name} used`,
        subtitle: `${item.effectType} +${item.effectValue}`,
        icon: item.emoji,
        notificationMessage: `Kiki used ${item.name}: ${item.effectType} +${item.effectValue}.`,
        metadata: { itemId: item.id, effectType: item.effectType },
      });

      const nextInventory = await tx.userInventory.findMany({ where: { userId } });
      return { item, pet, inventory: nextInventory };
    });

    res.json(result);
  } catch (error) {
    next(error);
  }
});

app.post('/pet/actions', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const body = petActionSchema.parse(req.body);
    const config = {
      feed: { field: 'hunger', value: 20, title: 'Kiki was fed', icon: '=???' },
      play: { field: 'mood', value: 18, title: 'Kiki played', icon: 'G?+' },
      pet: { field: 'love', value: 16, title: 'Kiki was petted', icon: 'G??n+?' },
    }[body.action];

    const result = await prisma.$transaction(async (tx) => {
      const wallet = await tx.wallet.findUniqueOrThrow({ where: { userId } });
      if (wallet.tokens < body.cost) {
        throw Object.assign(new Error('Not enough tokens'), { status: 400 });
      }
      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: { tokens: { decrement: body.cost } },
      });
      const currentPet = await applyPetDecay(tx, userId);
      const pet = await tx.pet.update({
        where: { userId },
        data: {
          [config.field]: clampStat(
            Number(currentPet[config.field as keyof typeof currentPet]) +
              config.value,
          ),
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
  } catch (error) {
    next(error);
  }
});

app.post('/pet/evolution/select', async (req, res, next) => {
  try {
    const userId = requireUser(req);
    const body = selectPetSkinSchema.parse(req.body);
    const skinCode = normalizePetSkinCode(body.skinCode);
    const currentPet = await prisma.$transaction((tx) =>
      applyPetDecay(tx, userId),
    );
    if (!isPetSkinUnlocked(currentPet.level, skinCode)) {
      throw Object.assign(
        new Error(
          `Reach level ${petEvolutionSkins[skinCode].unlockLevel} to unlock ${petEvolutionSkins[skinCode].title}`,
        ),
        { status: 400 },
      );
    }

    const pet = await prisma.pet.update({
      where: { userId },
      data: { selectedSkinCode: skinCode },
    });
    res.json({ pet, selectedSkin: petEvolutionSkins[skinCode] });
  } catch (error) {
    next(error);
  }
});

app.use(errorHandler);

  return app;
}

