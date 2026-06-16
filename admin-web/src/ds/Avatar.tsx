const HUES = [
  { bg: 'var(--blue-100)', fg: 'var(--blue-700)' },
  { bg: 'var(--teal-100)', fg: 'var(--teal-700)' },
  { bg: 'var(--violet-100)', fg: 'var(--violet-700)' },
  { bg: 'var(--amber-100)', fg: 'var(--amber-700)' },
  { bg: 'var(--green-100)', fg: 'var(--green-700)' },
];

export function initialsOf(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0]!.toUpperCase();
  return (parts[parts.length - 2][0]! + parts[parts.length - 1][0]!).toUpperCase();
}

export function hueIndexOf(name: string): number {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) % 100000;
  return h % HUES.length;
}

export function Avatar({ name, size = 36 }: { name: string; size?: number }) {
  const hue = HUES[hueIndexOf(name)];
  return (
    <span
      style={{
        width: size, height: size, flex: 'none', borderRadius: '50%',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        font: `var(--fw-semibold) ${Math.round(size * 0.36)}px/1 var(--font-sans)`,
        background: hue.bg, color: hue.fg,
        border: `1px solid color-mix(in srgb, ${hue.fg} 14%, transparent)`,
      }}
    >
      {initialsOf(name)}
    </span>
  );
}
