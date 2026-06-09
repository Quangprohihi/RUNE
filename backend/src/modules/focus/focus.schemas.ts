import { z } from 'zod';

export const startFocusSchema = z.object({
  label: z.string().min(1).default('Study'),
  plannedMinutes: z.number().int().positive().default(25),
  companionCode: z.string().trim().optional(),
});

export const completeFocusSchema = z.object({
  actualSeconds: z.number().int().nonnegative().default(0),
});

export const focusPlanAnalyzeSchema = z.object({
  goal: z.string().trim().min(1),
  selectedMinutes: z.number().int().positive().optional(),
  selectedTask: z.string().optional(),
});

export const focusRecapSchema = z.object({
  label: z.string().trim().default('Focus'),
  minutes: z.number().int().nonnegative().default(0),
  currentStreak: z.number().int().nonnegative().default(0),
  todayFocusMinutes: z.number().int().nonnegative().default(0),
  dailyGoalMinutes: z.number().int().positive().default(60),
  dailyGoalCompleted: z.boolean().default(false),
});
