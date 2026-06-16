import { describe, it, expect } from 'vitest';
import { initialsOf, hueIndexOf } from './Avatar';

describe('Avatar helpers', () => {
  it('builds up-to-2 uppercase initials from a name', () => {
    expect(initialsOf('Nguyễn Thị Hương')).toBe('TH');
    expect(initialsOf('Lan')).toBe('L');
    expect(initialsOf('')).toBe('?');
  });
  it('derives a deterministic hue bucket', () => {
    expect(hueIndexOf('Lan')).toBe(hueIndexOf('Lan'));
    expect(hueIndexOf('Lan')).toBeGreaterThanOrEqual(0);
    expect(hueIndexOf('Lan')).toBeLessThan(5);
  });
});
