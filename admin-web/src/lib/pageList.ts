/**
 * Page numbers to render in a pager, with ellipses bridging gaps.
 * Always exposes first, last, and current ± 1 (each clickable), so any page is
 * reachable by stepping or jumping. Returns plain 1..n when total is small.
 */
export function pageList(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const wanted = [1, total, current, current - 1, current + 1].filter((n) => n >= 1 && n <= total);
  const sorted = Array.from(new Set(wanted)).sort((a, b) => a - b);
  const out: (number | '…')[] = [];
  let prev = 0;
  for (const n of sorted) {
    if (prev && n - prev > 1) out.push('…');
    out.push(n);
    prev = n;
  }
  return out;
}
