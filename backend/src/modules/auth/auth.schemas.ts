import { z } from 'zod';

export const demoLoginSchema = z.object({
  email: z.string().email().optional().or(z.literal('')),
  displayName: z.string().optional(),
});

export const authRegisterSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  displayName: z.string().trim().min(2).max(40),
  password: z.string().min(6).max(72),
});

export const authLoginSchema = z.object({
  email: z.string().trim().toLowerCase().email(),
  password: z.string().min(1),
});

export const authGoogleSchema = z.object({
  idToken: z.string().min(1),
});

export const authRefreshSchema = z.object({
  refreshToken: z.string().min(1),
});
