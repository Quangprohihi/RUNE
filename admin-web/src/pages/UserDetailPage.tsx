import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Card, Button, Tag, Avatar, StatusBadge, statusFromUserStatus, ProgressMeter } from '../ds';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatDate } from '../lib/format';
import type { UserDetail } from '../lib/types';

const THl: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '10px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)' };
const TD: React.CSSProperties = { padding: '11px 16px', borderBottom: '1px solid var(--border-subtle)' };
const MONO: React.CSSProperties = { color: 'var(--text-strong)', fontWeight: 600, fontFamily: 'var(--font-mono)' };

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}><span style={{ color: 'var(--text-muted)' }}>{label}</span><span>{children}</span></div>;
}

export function UserDetailPage() {
  const { id = '' } = useParams();
  const [u, setU] = useState<UserDetail | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  function load() {
    setErr(null);
    api.userDetail(id).then(setU).catch((e) => setErr(friendlyError(e)));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { load(); }, [id]);

  async function sub(action: 'cancel' | 'extend', days?: number) {
    const msg = action === 'cancel' ? 'Hủy subscription của user này?' : `Gia hạn thêm ${days} ngày?`;
    if (typeof window !== 'undefined' && !window.confirm(msg)) return;
    setBusy(true);
    try { await api.userSubscription(id, { action, days }); load(); }
    catch (e) { setErr(friendlyError(e)); }
    finally { setBusy(false); }
  }
  async function forceLogout() {
    if (typeof window !== 'undefined' && !window.confirm('Buộc đăng xuất tất cả thiết bị của user?')) return;
    setBusy(true);
    try { await api.forceLogout(id); load(); }
    catch (e) { setErr(friendlyError(e)); }
    finally { setBusy(false); }
  }

  if (err) return <section style={{ padding: '20px 32px 90px' }}><ErrorState message={err} onRetry={load} /></section>;
  if (!u) return <section style={{ padding: '20px 32px 90px' }}><Skeleton height={120} /></section>;

  const st = statusFromUserStatus(u.status ?? 'active');
  const isPro = !!u.subscription && u.subscription.plan !== 'free';

  return (
    <section style={{ padding: '20px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-muted)', marginBottom: 16 }}>
        <Link to="/users" style={{ color: 'var(--text-link)' }}>Người dùng</Link>
        <span style={{ color: 'var(--text-faint)' }}>/</span>
        <span style={{ color: 'var(--text-strong)', fontWeight: 600 }}>{u.displayName}</span>
      </div>

      {/* header */}
      <div style={{ background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-sm)', padding: '20px 22px', marginBottom: 20, display: 'flex', alignItems: 'center', gap: 18, flexWrap: 'wrap' }}>
        <Avatar name={u.displayName} size={60} />
        <div style={{ flex: 1, minWidth: 200 }}>
          <div style={{ font: 'var(--fw-bold) 22px/1.1 var(--font-sans)', letterSpacing: '-.01em', color: 'var(--text-strong)' }}>{u.displayName}</div>
          <div style={{ font: 'var(--fw-medium) 13px/1.4 var(--font-mono)', color: 'var(--text-muted)', marginTop: 4 }}>{u.email} · {u.id.slice(0, 8)}…</div>
          <div style={{ display: 'flex', gap: 8, marginTop: 11, flexWrap: 'wrap' }}>
            <Tag tone="neutral">{u.provider}</Tag>
            {isPro ? <Tag tone="accent">Zen Pro</Tag> : <Tag tone="outline">Free</Tag>}
            <StatusBadge status={st.status}>{st.label}</StatusBadge>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 10, flex: 'none', flexWrap: 'wrap' }}>
          <Button variant="secondary" disabled={busy} onClick={forceLogout}>Buộc đăng xuất</Button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', gap: 20, alignItems: 'start' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {u.pet && (
            <Card title={`Thú cưng · ${u.pet.name} (${u.pet.species})`} subtitle={`Cấp ${u.pet.level} · EXP ${u.pet.exp}/${u.pet.expToNext}`} padding="md">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12, paddingTop: 2 }}>
                <ProgressMeter label="Năng lượng" value={u.pet.energy} />
                <ProgressMeter label="Tâm trạng" value={u.pet.mood} />
                <ProgressMeter label="Độ đói" value={u.pet.hunger} />
                <ProgressMeter label="Yêu thương" value={u.pet.love} />
              </div>
            </Card>
          )}
          <Card title="Phiên focus gần nhất" padding="none">
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead><tr>
                  <th style={THl}>Mục tiêu</th><th style={{ ...THl, textAlign: 'right' }}>Phút</th><th style={THl}>Đồng hành</th><th style={THl}>Trạng thái</th>
                </tr></thead>
                <tbody>
                  {u.focusSessions.length === 0 && <tr><td style={{ ...TD, color: 'var(--text-muted)' }} colSpan={4}>Chưa có phiên.</td></tr>}
                  {u.focusSessions.map((s) => (
                    <tr key={s.id}>
                      <td style={{ ...TD, color: 'var(--text-strong)' }}>{s.label}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)' }}>{s.plannedMinutes}</td>
                      <td style={{ ...TD, color: 'var(--text-body)' }}>{s.companionCode ?? '—'}</td>
                      <td style={TD}>{s.status === 'completed' ? <StatusBadge status="approved">Hoàn thành</StatusBadge> : <StatusBadge status="draft">{s.status}</StatusBadge>}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          <Card title="Gói đăng ký" padding="md">
            <div style={{ display: 'flex', flexDirection: 'column', gap: 11, paddingTop: 2, font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
              <Row label="Gói"><b style={MONO}>{isPro ? (u.subscription?.plan ?? 'premium') : 'free'}</b></Row>
              <Row label="Trạng thái">{u.subscription ? <StatusBadge status={u.subscription.status === 'active' ? 'approved' : 'draft'}>{u.subscription.status}</StatusBadge> : <span style={{ color: 'var(--text-faint)' }}>—</span>}</Row>
              <Row label="Hết hạn"><b style={MONO}>{formatDate(u.subscription?.expiresAt ?? null)}</b></Row>
              <div style={{ display: 'flex', gap: 8, marginTop: 6, flexWrap: 'wrap' }}>
                <Button variant="secondary" size="sm" disabled={busy} onClick={() => sub('extend', 30)}>Gia hạn +30</Button>
                <Button variant="secondary" size="sm" disabled={busy} onClick={() => sub('extend', 365)}>+365</Button>
                <Button variant="secondary" size="sm" disabled={busy} onClick={() => sub('cancel')}>Hủy</Button>
              </div>
            </div>
          </Card>
          {u.wallet && (
            <Card title="Ví" padding="md">
              <div style={{ display: 'flex', flexDirection: 'column', gap: 11, paddingTop: 2, font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <Row label="Token"><b style={MONO}>{formatInt(u.wallet.tokens)}</b></Row>
                <Row label="Kim cương"><b style={{ ...MONO, color: 'var(--accent-soft-fg)' }}>{formatInt(u.wallet.diamonds)} ◆</b></Row>
                <Row label="Năng lượng"><b style={MONO}>{formatInt(u.wallet.energy)}</b></Row>
                <Row label="Streak"><b style={MONO}>{u.streak?.currentStreak ?? 0} ngày · best {u.streak?.bestStreak ?? 0}</b></Row>
              </div>
            </Card>
          )}
        </div>
      </div>
    </section>
  );
}
