function escapeCell(v: unknown): string {
  const s = v == null ? '' : String(v);
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
}

export function toCsv<T>(headers: string[], rows: T[], rowMapper: (row: T) => unknown[]): string {
  const lines = [headers.map(escapeCell).join(',')];
  for (const r of rows) lines.push(rowMapper(r).map(escapeCell).join(','));
  return lines.join('\r\n');
}

export function downloadCsv(filename: string, csv: string): void {
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  a.remove();
  // Revoke after the browser has had a tick to start the download (sync revoke can cancel it).
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
