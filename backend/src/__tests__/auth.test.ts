import jwt from 'jsonwebtoken';
import { describe, expect, it } from 'vitest';

import { resolveUserIdFromRequest, signAccessToken, verifyAccessToken } from '../auth';

const secret = process.env.JWT_ACCESS_SECRET ?? '';

function statusOf(error: unknown) {
  return (error as { status?: number }).status;
}

describe('verifyAccessToken', () => {
  it('returns the payload for a valid token', () => {
    expect(verifyAccessToken(signAccessToken('user-1')).userId).toBe('user-1');
  });

  it('rejects an expired token as 401 so clients refresh instead of erroring', () => {
    const expired = jwt.sign({ userId: 'user-1' }, secret, { expiresIn: -10 });

    try {
      verifyAccessToken(expired);
      throw new Error('expected verifyAccessToken to throw');
    } catch (error) {
      expect((error as Error).message).toBe('jwt expired');
      expect(statusOf(error)).toBe(401);
    }
  });

  it('rejects a token signed with the wrong secret as 401', () => {
    const forged = jwt.sign({ userId: 'user-1' }, `${secret}-nope`);

    try {
      verifyAccessToken(forged);
      throw new Error('expected verifyAccessToken to throw');
    } catch (error) {
      expect(statusOf(error)).toBe(401);
    }
  });
});

describe('resolveUserIdFromRequest', () => {
  it('surfaces an expired bearer token as 401', () => {
    const expired = jwt.sign({ userId: 'user-1' }, secret, { expiresIn: -10 });

    try {
      resolveUserIdFromRequest(`Bearer ${expired}`);
      throw new Error('expected resolveUserIdFromRequest to throw');
    } catch (error) {
      expect(statusOf(error)).toBe(401);
    }
  });
});
