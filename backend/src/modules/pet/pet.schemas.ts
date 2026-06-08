import { z } from 'zod';

export const petActionSchema = z.object({
  action: z.enum(['feed', 'play', 'pet']),
  cost: z.number().int().nonnegative().default(0),
});

export const selectPetSkinSchema = z.object({
  skinCode: z.enum(['standard', 'spirit', 'celestial']),
});
