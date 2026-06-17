import 'dotenv/config';

import { prisma } from '../src/prisma';

async function main() {
  const taskTemplates = [
    {
      code: 'daily_login',
      title: 'Daily Login',
      description: 'Log in for 1 day',
      taskType: 'daily_login',
      targetValue: 1,
      rewardTokens: 10,
      rewardDiamonds: 1,
      rewardPoints: 120,
    },
    {
      code: 'sunshine_collector',
      title: 'Complete 1 Pomodoro',
      description: 'Finish one focus block to collect Sunshine',
      taskType: 'pomodoro_count',
      targetValue: 1,
      rewardTokens: 20,
      rewardDiamonds: 2,
      rewardPoints: 220,
    },
    {
      code: 'deep_focus',
      title: 'Deep Focus',
      description: 'Complete a 45-minute focus session',
      taskType: 'deep_focus',
      targetValue: 45,
      rewardTokens: 35,
      rewardDiamonds: 3,
      rewardPoints: 320,
    },
  ];

  for (const template of taskTemplates) {
    await prisma.taskTemplate.upsert({
      where: { code: template.code },
      create: template,
      update: template,
    });
  }

  for (const milestone of [
    { pointsRequired: 120, rewardTokens: 10, rewardDiamonds: 1 },
    { pointsRequired: 340, rewardTokens: 20, rewardDiamonds: 2 },
    { pointsRequired: 660, rewardTokens: 35, rewardDiamonds: 3 },
    { pointsRequired: 1045, rewardTokens: 50, rewardDiamonds: 5 },
  ]) {
    await prisma.dailyMilestone.upsert({
      where: { pointsRequired: milestone.pointsRequired },
      create: milestone,
      update: milestone,
    });
  }

  const shopItems = [
    {
      code: 'energy_potion',
      name: 'Energy Potion',
      emoji: '⚡',
      itemType: 'potion',
      priceTokens: 150,
      effectType: 'energy',
      effectValue: 20,
      isHot: true,
    },
    {
      code: 'mood_booster',
      name: 'Mood Booster',
      emoji: '🌸',
      itemType: 'potion',
      priceTokens: 120,
      effectType: 'mood',
      effectValue: 20,
    },
    {
      code: 'fresh_berries',
      name: 'Fresh Berries',
      emoji: '🍓',
      itemType: 'food',
      priceTokens: 100,
      effectType: 'hunger',
      effectValue: 24,
      isHot: true,
    },
    {
      code: 'cozy_pet',
      name: 'Cozy Pet',
      emoji: '✨',
      itemType: 'potion',
      priceTokens: 90,
      effectType: 'love',
      effectValue: 18,
    },
    {
      code: 'companion_eagle',
      name: 'Eagle',
      emoji: '🦅',
      itemType: 'companion',
      priceTokens: 260,
      effectType: 'love',
      effectValue: 0,
      isHot: true,
    },
    {
      code: 'companion_frog',
      name: 'Frog',
      emoji: '🐸',
      itemType: 'companion',
      priceTokens: 180,
      effectType: 'love',
      effectValue: 0,
    },
    {
      code: 'companion_giraffe',
      name: 'Giraffe',
      emoji: '🦒',
      itemType: 'companion',
      priceTokens: 320,
      effectType: 'love',
      effectValue: 0,
    },
  ];

  for (const item of shopItems) {
    await prisma.shopItem.upsert({
      where: { code: item.code },
      create: item,
      update: item,
    });
  }

  // Demo moderation states so the admin console Users filter (Tạm khóa / Đang xem xét) has data.
  const someUsers = await prisma.user.findMany({ take: 3, orderBy: { createdAt: 'asc' } });
  if (someUsers[0]) await prisma.user.update({ where: { id: someUsers[0].id }, data: { status: 'review' } });
  if (someUsers[1]) await prisma.user.update({ where: { id: someUsers[1].id }, data: { status: 'suspended' } });

  // Subscription packages (admin-editable; mirror the hardcoded fallback in payment.service.ts).
  const packages = [
    { productCode: 'zen_pro_monthly', title: 'Zen Pro Monthly', plan: 'premium', amountVnd: 29000, durationDays: 30 },
    { productCode: 'zen_pro_yearly', title: 'Zen Pro Yearly', plan: 'premium', amountVnd: 279000, durationDays: 365 },
  ];
  for (const p of packages) {
    await prisma.subscriptionPackage.upsert({ where: { productCode: p.productCode }, create: p, update: { title: p.title, plan: p.plan } });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
