import { useEffect, useRef, useState } from 'react';

export interface RangeValue { range: string; granularity: string; compare: boolean; from?: string; to?: string; }

const PRESETS = [
  { key: 'today', label: 'Hôm nay' }, { key: 'week', label: 'Tuần này' }, { key: 'month', label: 'Tháng này' },
  { key: 'quarter', label: 'Quý này' }, { key: 'year', label: 'Năm nay' }, { key: 'custom', label: 'Tùy chỉnh…' },
];
const GRANS = [
  { key: 'day', label: 'Ngày' }, { key: 'week', label: 'Tuần' }, { key: 'month', label: 'Tháng' }, { key: 'quarter', label: 'Quý' },
];
const iso = (y: number, m: number, d: number) => `${y}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;
const navBtn: React.CSSProperties = { width: 28, height: 28, border: '1px solid var(--border-default)', background: 'var(--surface-card)', borderRadius: 6, cursor: 'pointer', color: 'var(--text-body)' };
const ftBtn: React.CSSProperties = { height: 32, padding: '0 14px', border: 'none', borderRadius: 'var(--radius-md)', cursor: 'pointer', font: 'var(--fw-semibold) 13px/1 var(--font-sans)' };

export function RangePicker({ label, value, onApply }: { label: string; value: RangeValue; onApply: (v: RangeValue) => void }) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const [draft, setDraft] = useState<RangeValue>(value);
  const now = new Date();
  const [calY, setCalY] = useState(now.getUTCFullYear());
  const [calM, setCalM] = useState(now.getUTCMonth());

  useEffect(() => {
    if (!open) return;
    setDraft(value);
    const onDoc = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); };
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', onDoc);
    document.addEventListener('keydown', onKey);
    return () => { document.removeEventListener('mousedown', onDoc); document.removeEventListener('keydown', onKey); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  function pickPreset(key: string) {
    setDraft((d) => ({ ...d, range: key, ...(key !== 'custom' ? { from: undefined, to: undefined } : {}) }));
  }
  function pickDay(dayIso: string) {
    setDraft((d) => {
      if (!d.from || (d.from && d.to)) return { ...d, range: 'custom', from: dayIso, to: undefined };
      if (dayIso < d.from) return { ...d, from: dayIso, to: d.from };
      return { ...d, to: dayIso };
    });
  }

  const dim = new Date(Date.UTC(calY, calM + 1, 0)).getUTCDate();
  const first = new Date(Date.UTC(calY, calM, 1)).getUTCDay();
  const offset = (first + 6) % 7;
  const head = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  const cells: (number | null)[] = [...Array(offset).fill(null), ...Array.from({ length: dim }, (_, i) => i + 1)];

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button type="button" onClick={() => setOpen((o) => !o)} style={{ display: 'inline-flex', alignItems: 'center', gap: 8, height: 34, padding: '0 13px', borderRadius: 'var(--radius-md)', border: '1px solid var(--border-default)', background: 'var(--surface-card)', color: 'var(--text-strong)', font: 'var(--fw-semibold) 13px/1 var(--font-sans)', cursor: 'pointer' }}>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" /><path d="M3 10h18M8 2v4M16 2v4" /></svg>
        {label}
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="var(--text-faint)" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round"><path d="m6 9 6 6 6-6" /></svg>
      </button>
      {open && (
        <div style={{ position: 'absolute', left: 0, top: 'calc(100% + 8px)', zIndex: 400, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-lg)', display: 'flex', maxWidth: 'min(520px, 88vw)' }}>
          <div style={{ width: 200, padding: 12, borderRight: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column', gap: 2 }}>
            {PRESETS.map((p) => (
              <button key={p.key} type="button" onClick={() => pickPreset(p.key)} style={{ display: 'flex', alignItems: 'center', width: '100%', padding: '8px 12px', border: 'none', borderRadius: 'var(--radius-md)', cursor: 'pointer', background: draft.range === p.key ? 'var(--surface-brand-soft)' : 'transparent', color: draft.range === p.key ? 'var(--blue-700)' : 'var(--text-body)', font: `${draft.range === p.key ? 600 : 500} 13px/1 var(--font-sans)`, textAlign: 'left' }}>{p.label}</button>
            ))}
            <div style={{ height: 1, background: 'var(--border-subtle)', margin: '8px 0' }} />
            <label style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 8px', font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)', cursor: 'pointer' }}>
              So sánh kỳ trước
              <input type="checkbox" checked={draft.compare} onChange={(e) => setDraft((d) => ({ ...d, compare: e.target.checked }))} style={{ width: 15, height: 15, accentColor: 'var(--green-500)' }} />
            </label>
            <div style={{ font: 'var(--fw-semibold) 11px/1 var(--font-sans)', color: 'var(--text-faint)', textTransform: 'uppercase', letterSpacing: '.06em', padding: '8px 8px 4px' }}>Độ chi tiết</div>
            <div className="zz-seg zz-seg--lite" style={{ flexWrap: 'wrap' }}>
              {GRANS.map((g) => <button key={g.key} type="button" className={`zz-seg__opt${draft.granularity === g.key ? ' zz-seg__opt--on' : ''}`} onClick={() => setDraft((d) => ({ ...d, granularity: g.key }))}>{g.label}</button>)}
            </div>
          </div>
          <div style={{ width: 280, padding: 12 }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
              <button type="button" aria-label="Tháng trước" onClick={() => { let m = calM - 1, y = calY; if (m < 0) { m = 11; y--; } setCalM(m); setCalY(y); }} style={navBtn}>‹</button>
              <span style={{ font: 'var(--fw-semibold) 13px/1 var(--font-sans)', color: 'var(--text-strong)' }}>Tháng {calM + 1} {calY}</span>
              <button type="button" aria-label="Tháng sau" onClick={() => { let m = calM + 1, y = calY; if (m > 11) { m = 0; y++; } setCalM(m); setCalY(y); }} style={navBtn}>›</button>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 2, marginBottom: 4 }}>
              {head.map((h) => <span key={h} style={{ textAlign: 'center', font: 'var(--fw-semibold) 10px/1 var(--font-sans)', color: 'var(--text-faint)', padding: '4px 0' }}>{h}</span>)}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 2 }}>
              {cells.map((d, i) => {
                if (d === null) return <span key={`b${i}`} />;
                const dIso = iso(calY, calM, d);
                const sel = dIso === draft.from || dIso === draft.to;
                const inR = !!draft.from && !!draft.to && dIso > draft.from && dIso < draft.to;
                return <button key={d} type="button" onClick={() => pickDay(dIso)} style={{ height: 30, border: 'none', cursor: 'pointer', borderRadius: 6, fontFamily: 'var(--font-mono)', fontSize: 12, background: sel ? 'var(--brand)' : inR ? 'var(--surface-brand-soft)' : 'transparent', color: sel ? '#fff' : inR ? 'var(--blue-700)' : 'var(--text-body)', fontWeight: sel ? 600 : 400 }}>{d}</button>;
              })}
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8, marginTop: 12 }}>
              <button type="button" onClick={() => setOpen(false)} style={{ ...ftBtn, background: 'transparent', color: 'var(--text-body)' }}>Hủy</button>
              <button type="button" onClick={() => { onApply(draft); setOpen(false); }} style={{ ...ftBtn, background: 'var(--brand)', color: '#fff' }}>Áp dụng</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
