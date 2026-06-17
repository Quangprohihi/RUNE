import { describe, it, expect } from 'vitest';
import { clientIp } from '../audit.util';

describe('clientIp', () => {
  it('prefers the first x-forwarded-for hop, trimmed', () => {
    expect(clientIp('203.0.113.7, 10.0.0.1', '10.0.0.5')).toBe('203.0.113.7');
    expect(clientIp('  203.0.113.9  ', undefined)).toBe('203.0.113.9');
  });

  it('falls back to req.ip when x-forwarded-for is absent or empty', () => {
    expect(clientIp(undefined, '10.0.0.5')).toBe('10.0.0.5');
    expect(clientIp('', '10.0.0.5')).toBe('10.0.0.5');
    expect(clientIp('   ', '10.0.0.5')).toBe('10.0.0.5');
  });

  it('returns null when neither source has a value', () => {
    expect(clientIp(undefined, undefined)).toBeNull();
    expect(clientIp('', '')).toBeNull();
  });
});
