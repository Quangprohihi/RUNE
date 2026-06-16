import { describe, it, expect } from 'vitest';
import { toCsv } from './csv';

describe('toCsv', () => {
  it('builds a header + rows and quotes values containing commas/quotes', () => {
    const csv = toCsv(
      ['name', 'email'],
      [{ name: 'Lê, Lan', email: 'a@b.c' }, { name: 'Quote "x"', email: 'd@e.f' }],
      (r) => [r.name, r.email],
    );
    expect(csv).toBe('name,email\r\n"Lê, Lan",a@b.c\r\n"Quote ""x""",d@e.f');
  });
});
