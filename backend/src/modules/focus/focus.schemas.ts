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
