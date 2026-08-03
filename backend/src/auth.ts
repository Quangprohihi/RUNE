import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import { prisma } from './prisma';

const accessSecret = process.env.JWT_ACCESS_SECRET ?? '';
const refreshSecret = process.env.JWT_REFRESH_SECRET ?? '';
const googleClientId =
  process.env.GOOGLE_WEB_CLIENT_ID ?? process.env.GOOGLE_CLIENT_ID ?? '';

const accessTokenTtlSeconds = Number(process.env.JWT_ACCESS_TTL_SECONDS ?? 900);
const refreshTokenTtlDays = Number(process.env.JWT_REFRESH_TTL_DAYS ?? 30);

const googleClient = googleClientId
  ? new OAuth2Client(googleClientId)
  : null;

export type AccessTokenPayload = {
  userId: string;
};

function assertAuthSecrets() {
  if (!accessSecret || !refreshSecret) {
    throw Object.assign(new Error('JWT secrets are not configured'), {
      status: 500,
    });
  }
}

export function signAccessToken(userId: string) {
  assertAuthSecrets();
  return jwt.sign({ userId } satisfies AccessTokenPayload, accessSecret, {
    expiresIn: accessTokenTtlSeconds,
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  assertAuthSecrets();
  let payload: AccessTokenPayload;
  try {
    payload = jwt.verify(token, accessSecret) as AccessTokenPayload;
  } catch (error) {
    // jsonwebtoken throws plain Errors (TokenExpiredError, JsonWebTokenError)
    // with no status, which the error handler would report as 500. Clients
    // only refresh on 401, so an expired access token has to answer 401 or the
    // session dies until the user signs in again.
    throw Object.assign(error as Error, { status: 401 });
  }
  if (!payload?.userId) {
    throw Object.assign(new Error('Invalid access token'), { status: 401 });
  }
  return payload;
}

export function createRefreshTokenValue() {
  return crypto.randomBytes(48).toString('hex');
}

export function hashRefreshToken(token: string) {
  return crypto.createHmac('sha256', refreshSecret || 'missing-secret').update(token).digest('hex');
}

function refreshTokenExpiresAt() {
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + refreshTokenTtlDays);
  return expiresAt;
}

export async function issueTokenPair(userId: string) {
  assertAuthSecrets();
  const accessToken = signAccessToken(userId);
  const refreshToken = createRefreshTokenValue();

  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash: hashRefreshToken(refreshToken),
      expiresAt: refreshTokenExpiresAt(),
    },
  });

  return { accessToken, refreshToken };
}

export async function rotateRefreshToken(refreshToken: string) {
  assertAuthSecrets();
  const tokenHash = hashRefreshToken(refreshToken);
  const stored = await prisma.refreshToken.findFirst({
    where: {
      tokenHash,
      revokedAt: null,
      expiresAt: { gt: new Date() },
    },
  });

  if (!stored) {
    throw Object.assign(new Error('Invalid or expired refresh token'), {
      status: 401,
    });
  }

  await prisma.refreshToken.update({
    where: { id: stored.id },
    data: { revokedAt: new Date() },
  });

  return issueTokenPair(stored.userId);
}

export async function revokeRefreshToken(refreshToken: string) {
  assertAuthSecrets();
  const tokenHash = hashRefreshToken(refreshToken);
  await prisma.refreshToken.updateMany({
    where: { tokenHash, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function verifyGoogleIdToken(idToken: string) {
  if (!googleClient || !googleClientId) {
    throw Object.assign(new Error('Google auth is not configured'), {
      status: 500,
    });
  }

  const ticket = await googleClient.verifyIdToken({
    idToken,
    audience: googleClientId,
  });

  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw Object.assign(new Error('Invalid Google token'), { status: 401 });
  }

  return payload;
}

export function resolveUserIdFromRequest(authHeader?: string, legacyUserId?: string) {
  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.slice('Bearer '.length).trim();
    if (token) {
      return verifyAccessToken(token).userId;
    }
  }

  if (legacyUserId) {
    return legacyUserId;
  }

  throw Object.assign(new Error('Unauthorized'), { status: 401 });
}
