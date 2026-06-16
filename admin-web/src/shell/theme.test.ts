import { describe, it, expect } from 'vitest';
import { themeVars } from './theme';

describe('themeVars', () => {
  it('theme A = dark rail + flush hairline KPI grid', () => {
    const a = themeVars('a');
    expect(a['--rail-bg']).toBe('var(--slate-900)');
    expect(a['--kpi-gap']).toBe('1px');
    expect(a['--kpi-cell-border']).toBe('none');
  });
  it('theme B = light rail + separated KPI cards', () => {
    const b = themeVars('b');
    expect(b['--rail-bg']).toBe('var(--slate-0)');
    expect(b['--kpi-gap']).toBe('14px');
    expect(b['--kpi-cell-shadow']).toBe('var(--shadow-sm)');
  });
  it('density controls row padding', () => {
    expect(themeVars('a', 'comfortable')['--row-py']).toBe('13px');
    expect(themeVars('a', 'compact')['--row-py']).toBe('8px');
  });
});
