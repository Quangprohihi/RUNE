import { useEffect, useMemo, useState } from 'react';
import type { CSSProperties, ReactNode } from 'react';
import { Card, Button, Input, Avatar, SegmentedControl, Icon, icons } from '../ds';
import { Stars } from '../components/Stars';
import { DonutChart } from '../components/DonutChart';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatPercent, formatDate } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import type { ReviewsResponse, AppReview, ThemeStat, ReviewTone } from '../lib/types';

type RatingFilter = 'all' | '5' | '4' | '3' | 'low';

const RATING_OPTS: { value: RatingFilter; label: string }[] = [
  { value: 'all', label: 'Tất cả' }, { value: '5', label: '5★' },
  { value: '4', label: '4★' }, { value: '3', label: '3★' }, { value: 'low', label: '1–2★' },
];

// Sắc thái đi theo ý nghĩa, không theo thứ hạng: khen xanh lá, mong muốn xanh dương, chê đỏ.
const TONE_META: Record<ReviewTone, { label: string; color: string; bg: string; fg: string }> = {
  praise: { label: 'khen', color: 'var(--green-500)', bg: 'var(--green-50)', fg: 'var(--green-700)' },
  request: { label: 'mong muốn', color: 'var(--blue-500)', bg: 'var(--blue-50)', fg: 'var(--blue-700)' },
  issue: { label: 'lỗi / chê', color: 'var(--red-500)', bg: 'var(--red-50)', fg: 'var(--red-700)' },
};
const TONE_ORDER: ReviewTone[] = ['praise', 'request', 'issue'];

const CELL: CSSProperties = {
  background: 'var(--kpi-cell-bg, var(--surface-card))', border: 'var(--kpi-cell-border, none)',
  borderRadius: 'var(--kpi-cell-radius, 0px)', boxShadow: 'var(--kpi-cell-shadow, none)',
  padding: '15px 16px 14px', display: 'flex', flexDirection: 'column', minHeight: 118,
};

function StatCell({ label, value, suffix, note, children }: {
  label: string; value: string; suffix?: string; note?: string; children?: ReactNode;
}) {
  return (
    <div style={CELL}>
      <span style={{ font: 'var(--fw-semibold) 11px/1.3 var(--font-sans)', letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--text-muted)' }}>{label}</span>
      <div style={{ font: 'var(--fw-extra) 30px/1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', marginTop: 12, fontVariantNumeric: 'tabular-nums' }}>
        {value}{suffix && <span style={{ fontSize: 16, color: 'var(--text-muted)', fontWeight: 600 }}>{suffix}</span>}
      </div>
      <div style={{ marginTop: 9, display: 'flex', alignItems: 'center', gap: 7, minHeight: 16 }}>
        {children}
        {note && <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-faint)' }}>{note}</span>}
      </div>
    </div>
  );
}

function TonePill({ tone, label }: { tone: ReviewTone; label: string }) {
  const m = TONE_META[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5, padding: '3px 9px', borderRadius: 999,
      background: m.bg, color: m.fg, font: 'var(--fw-medium) 11.5px/1.4 var(--font-sans)',
      border: `1px solid color-mix(in srgb, ${m.color} 22%, transparent)`,
    }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%', background: m.color, flex: 'none' }} />
      {label} · {m.label}
    </span>
  );
}

/** Một dòng chủ đề: độ dài thanh = số review nhắc tới, phần trong thanh = tỉ lệ sắc thái. */
function ThemeRow({ stat, max }: { stat: ThemeStat; max: number }) {
  const toneTotal = stat.praise + stat.request + stat.issue;
  const width = max > 0 ? (stat.mentions / max) * 100 : 0;
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '152px minmax(0,1fr) 34px', alignItems: 'center', gap: 12 }}>
      <span style={{ font: 'var(--fw-medium) 12.5px/1.3 var(--font-sans)', color: 'var(--text-body)' }}>{stat.label}</span>
      <div style={{ height: 10, borderRadius: 'var(--radius-pill)', background: 'var(--surface-sunken)', overflow: 'hidden' }}>
        <div style={{ display: 'flex', height: '100%', width: `${width}%`, borderRadius: 'var(--radius-pill)', overflow: 'hidden' }}>
          {TONE_ORDER.map((t) => {
            const n = stat[t];
            return n > 0 ? <span key={t} title={`${n} ${TONE_META[t].label}`} style={{ width: `${(n / toneTotal) * 100}%`, background: TONE_META[t].color }} /> : null;
          })}
        </div>
      </div>
      <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-mono)', color: 'var(--text-strong)', textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{stat.mentions}</span>
    </div>
  );
}

function ReviewCard({ r, themeLabel }: { r: AppReview; themeLabel: (k: string) => string }) {
  return (
    <article style={{
      display: 'flex', flexDirection: 'column', gap: 10, padding: '15px 16px',
      background: 'var(--surface-card)', border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-sm)',
    }}>
      <header style={{ display: 'flex', alignItems: 'center', gap: 11 }}>
        <Avatar name={r.author} size={34} />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ font: 'var(--fw-semibold) 13.5px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{r.author}</div>
          <div style={{ font: 'var(--fw-regular) 11.5px/1.4 var(--font-sans)', color: 'var(--text-faint)' }}>
            {formatDate(r.at)} · {r.platform} · v{r.appVersion}
          </div>
        </div>
        <span style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
          <Stars value={r.rating} size={15} />
          <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-mono)', color: 'var(--text-muted)' }}>{r.rating}.0</span>
        </span>
      </header>
      <p style={{ margin: 0, font: 'var(--fw-regular) 13.5px/1.6 var(--font-sans)', color: 'var(--text-body)' }}>{r.text}</p>
      {r.tags.length > 0 && (
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
          {r.tags.map((t, i) => <TonePill key={i} tone={t.tone} label={themeLabel(t.theme)} />)}
        </div>
      )}
    </article>
  );
}

export function ReviewsPage() {
  const [data, setData] = useState<ReviewsResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [rating, setRating] = useState<RatingFilter>('all');
  const [theme, setTheme] = useState('');
  const [q, setQ] = useState('');

  function load() {
    setLoading(true);
    setError(null);
    api.reviews().then(setData).catch((e) => setError(friendlyError(e))).finally(() => setLoading(false));
  }
  useEffect(load, []);

  const themeLabel = useMemo(() => {
    const map = new Map((data?.themes ?? []).map((t) => [t.key, t.label]));
    return (k: string) => map.get(k) ?? k;
  }, [data]);

  const filtered = useMemo(() => {
    const items = data?.items ?? [];
    const needle = q.trim().toLowerCase();
    return items.filter((r) => {
      if (rating === 'low' ? r.rating > 2 : rating !== 'all' && r.rating !== Number(rating)) return false;
      if (theme && !r.tags.some((t) => t.theme === theme)) return false;
      if (needle && !`${r.text} ${r.author}`.toLowerCase().includes(needle)) return false;
      return true;
    });
  }, [data, rating, theme, q]);

  function exportCsv() {
    const csv = toCsv(
      ['Ngày', 'Người dùng', 'Số sao', 'Nền tảng', 'Phiên bản', 'Nội dung', 'Chủ đề'],
      filtered,
      (r) => [
        formatDate(r.at), r.author, String(r.rating), r.platform, r.appVersion, r.text,
        r.tags.map((t) => `${themeLabel(t.theme)} (${TONE_META[t.tone].label})`).join(' · '),
      ],
    );
    downloadCsv('zenzoo-danh-gia-nguoi-dung.csv', csv);
  }

  if (error) {
    return <section style={{ padding: '24px 32px 90px' }}><ErrorState message={error} onRetry={load} /></section>;
  }

  if (loading || !data) {
    return (
      <section style={{ padding: '24px 32px 90px', display: 'flex', flexDirection: 'column', gap: 20 }}>
        <Skeleton height={118} radius={12} />
        <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)', gap: 20 }}>
          <Skeleton height={230} radius={12} /><Skeleton height={230} radius={12} />
        </div>
        <Skeleton height={260} radius={12} />
      </section>
    );
  }

  const s = data.summary;
  const maxMentions = Math.max(1, ...s.themes.map((t) => t.mentions));
  const dates = data.items.map((r) => new Date(r.at).getTime());
  const period = data.items.length > 0 ? `${formatDate(new Date(Math.min(...dates)).toISOString())} – ${formatDate(new Date(Math.max(...dates)).toISOString())}` : '—';

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 18, flexWrap: 'wrap' }}>
        <span style={{ font: 'var(--fw-regular) 12.5px/1.5 var(--font-sans)', color: 'var(--text-muted)' }}>
          Khảo sát người dùng thử ZenZoo · <b style={{ color: 'var(--text-body)', fontWeight: 600 }}>{formatInt(s.total)}</b> đánh giá · {period}
        </span>
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
      </div>

      <div style={{
        display: 'grid', gridTemplateColumns: 'repeat(5,minmax(0,1fr))', gap: 'var(--kpi-gap, 1px)',
        background: 'var(--kpi-wrap-bg, var(--border-subtle))', border: 'var(--kpi-wrap-border, 1px solid var(--border-subtle))',
        borderRadius: 'var(--kpi-wrap-radius, var(--radius-lg))', overflow: 'var(--kpi-wrap-overflow, hidden)', marginBottom: 22,
      }}>
        <StatCell label="Điểm trung bình" value={s.average.toLocaleString('vi-VN')} suffix="/5">
          <Stars value={s.average} size={15} />
        </StatCell>
        <StatCell label="Tổng lượt đánh giá" value={formatInt(s.total)} note="Android · v1.0.0" />
        <StatCell label="Tỉ lệ hài lòng" value={formatPercent(s.satisfactionPct)} note={`${s.sentiment.positive} đánh giá từ 4★`} />
        <StatCell label="Yêu cầu tính năng" value={formatInt(s.requestCount)} note="đánh giá nêu mong muốn" />
        <StatCell label="Lỗi & điểm chê" value={formatInt(s.issueCount)} note="đánh giá báo vấn đề" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)', gap: 20, alignItems: 'start', marginBottom: 22 }}>
        <Card title="Phân bố số sao" subtitle={`Điểm trung bình ${s.average.toLocaleString('vi-VN')}/5 · ${formatInt(s.total)} lượt`} padding="md">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 11, paddingTop: 2 }}>
            {s.distribution.map((b) => (
              <div key={b.stars} style={{ display: 'grid', gridTemplateColumns: '30px minmax(0,1fr) 26px 46px', alignItems: 'center', gap: 10 }}>
                <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-mono)', color: 'var(--text-body)' }}>{b.stars}★</span>
                <div style={{ height: 10, borderRadius: 'var(--radius-pill)', background: 'var(--surface-sunken)', overflow: 'hidden' }}>
                  <div style={{ width: `${b.pct}%`, height: '100%', borderRadius: 'var(--radius-pill)', background: 'var(--amber-500)' }} />
                </div>
                <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-mono)', color: 'var(--text-strong)', textAlign: 'right', fontVariantNumeric: 'tabular-nums' }}>{b.count}</span>
                <span style={{ font: 'var(--fw-regular) 11.5px/1 var(--font-mono)', color: 'var(--text-faint)', textAlign: 'right' }}>{formatPercent(b.pct)}</span>
              </div>
            ))}
          </div>
        </Card>

        <Card title="Sắc thái đánh giá" subtitle="Tích cực ≥ 4★ · Trung tính 3★ · Tiêu cực ≤ 2★" padding="md">
          <DonutChart
            centerLabel="đánh giá"
            slices={[
              { label: 'Tích cực', value: s.sentiment.positive, color: 'var(--green-500)' },
              { label: 'Trung tính', value: s.sentiment.neutral, color: 'var(--amber-500)' },
              { label: 'Tiêu cực', value: s.sentiment.negative, color: 'var(--red-500)' },
            ]}
          />
        </Card>
      </div>

      <Card
        title="Chủ đề người dùng nhắc tới"
        subtitle="Độ dài thanh = số đánh giá nhắc tới · màu = sắc thái"
        padding="md"
        style={{ marginBottom: 22 }}
        actions={
          <div style={{ display: 'flex', gap: 14, flexWrap: 'wrap' }}>
            {TONE_ORDER.map((t) => (
              <span key={t} style={{ display: 'inline-flex', alignItems: 'center', gap: 6, font: 'var(--fw-medium) 11.5px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
                <span style={{ width: 9, height: 9, borderRadius: 3, background: TONE_META[t].color }} />{TONE_META[t].label}
              </span>
            ))}
          </div>
        }
      >
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,minmax(0,1fr))', gap: '13px 34px', paddingTop: 2 }}>
          {s.themes.map((t) => <ThemeRow key={t.key} stat={t} max={maxMentions} />)}
        </div>
      </Card>

      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14, flexWrap: 'wrap' }}>
        <SegmentedControl<RatingFilter> value={rating} options={RATING_OPTS} onChange={setRating} />
        <select
          value={theme}
          onChange={(e) => setTheme(e.target.value)}
          aria-label="Lọc theo chủ đề"
          style={{ height: 36, padding: '0 10px', borderRadius: 8, border: '1px solid var(--border-default)', background: 'var(--surface)', font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}
        >
          <option value="">Tất cả chủ đề</option>
          {s.themes.map((t) => <option key={t.key} value={t.key}>{t.label} ({t.mentions})</option>)}
        </select>
        <div style={{ minWidth: 220, maxWidth: 300 }}>
          <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Tìm trong nội dung đánh giá…" prefix={<Icon size={16}>{icons.search}</Icon>} />
        </div>
        <div style={{ flex: 1 }} />
        <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>
          Hiển thị <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{formatInt(filtered.length)}</b>/{formatInt(s.total)} đánh giá
        </span>
      </div>

      {filtered.length === 0 ? (
        <Card padding="md">
          <p style={{ margin: 0, textAlign: 'center', padding: '18px 0', font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)' }}>
            Không có đánh giá nào khớp bộ lọc.
          </p>
        </Card>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2,minmax(0,1fr))', gap: 16, alignItems: 'start' }}>
          {filtered.map((r) => <ReviewCard key={r.id} r={r} themeLabel={themeLabel} />)}
        </div>
      )}
    </section>
  );
}
