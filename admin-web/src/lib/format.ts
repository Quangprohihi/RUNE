const vi = (opts?: Intl.NumberFormatOptions) => new Intl.NumberFormat('vi-VN', opts);
const pad2 = (x: number) => String(x).padStart(2, '0');

export function formatInt(n: number): string {
  return vi().format(Math.round(n));
}

export function formatPercent(n: number, maxDigits = 1): string {
  return vi({ maximumFractionDigits: maxDigits }).format(n) + '%';
}

function formatDecimal(n: number, maxDigits = 2): string {
  return vi({ maximumFractionDigits: maxDigits }).format(n);
}

export function formatVndShort(n: number): string {
  if (n >= 1_000_000) return formatDecimal(n / 1_000_000) + ' tr đ';
  if (n >= 1_000) return formatDecimal(n / 1_000) + 'k đ';
  return formatInt(n) + ' đ';
}

function toDate(iso: string | Date | null | undefined): Date | null {
  if (!iso) return null;
  const d = iso instanceof Date ? iso : new Date(iso);
  return isNaN(d.getTime()) ? null : d;
}

export function formatDate(iso: string | Date | null | undefined): string {
  const d = toDate(iso);
  if (!d) return '—';
  return `${pad2(d.getUTCDate())}/${pad2(d.getUTCMonth() + 1)}/${d.getUTCFullYear()}`;
}

export function formatDateTimeUtc(iso: string | Date | null | undefined): string {
  const d = toDate(iso);
  if (!d) return '—';
  return `${pad2(d.getUTCDate())}/${pad2(d.getUTCMonth() + 1)} · ${pad2(d.getUTCHours())}:${pad2(d.getUTCMinutes())}`;
}

export function relativeTime(iso: string | Date, now: number = Date.now()): string {
  const d = toDate(iso);
  if (!d) return '—';
  const sec = Math.max(0, Math.round((now - d.getTime()) / 1000));
  if (sec < 60) return `${sec} giây trước`;
  const min = Math.round(sec / 60);
  if (min < 60) return `${min} phút trước`;
  const hr = Math.round(min / 60);
  if (hr < 24) return `${hr} giờ trước`;
  return `${Math.round(hr / 24)} ngày trước`;
}
