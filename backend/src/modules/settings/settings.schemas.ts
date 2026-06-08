import { z } from 'zod';

export const settingsSchema = z.object({
  soundEnabled: z.boolean().optional(),
  vibrationEnabled: z.boolean().optional(),
  focusReminders: z.boolean().optional(),
  silenceNotificationsDuringFocus: z.boolean().optional(),
});
