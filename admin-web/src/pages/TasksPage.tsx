import { Fragment, useEffect, useMemo, useState } from 'react';
import { Card, Button, StatusBadge, Tag } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt } from '../lib/format';
import { pageList } from '../lib/pageList';
import type { TaskConfigResponse, TaskTemplate, DailyMilestone } from '../lib/types';

const TASK_TYPE_LABELS: Record<string, string> = {
  daily_login: 'Đăng nhập', pomodoro_count: 'Pomodoro', focus_minutes: 'Phút focus',
  streak: 'Streak', task_complete: 'Hoàn thành',
};
const taskTypeLabel = (t: string) => TASK_TYPE_LABELS[t] ?? t;

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: 'var(--row-py, 13px) 16px', borderBottom: '1px solid var(--border-subtle)' };
const numInput: React.CSSProperties = { width: 90, height: 32, padding: '0 10px', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)', font: 'var(--fw-regular) 13px/1 var(--font-mono)', color: 'var(--text-strong)' };
const PAGE_SIZE = 15;

function Reward({ tokens, diamonds, points }: { tokens: number; diamonds: number; points?: number }) {
  return (
    <span style={{ display: 'inline-flex', gap: 10, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)', whiteSpace: 'nowrap' }}>
      <span title="token">🪙 {formatInt(tokens)}</span>
      <span title="kim cương">💎 {formatInt(diamonds)}</span>
      {points !== undefined && <span title="điểm">⭐ {formatInt(points)}</span>}
    </span>
  );
}

export function TasksPage() {
  const [data, setData] = useState<TaskConfigResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [editTask, setEditTask] = useState<string | null>(null);
  const [editMs, setEditMs] = useState<string | null>(null);
  const [d, setD] = useState({ tok: '', dia: '', pts: '', active: true });
  const [page, setPage] = useState(1);

  function load() {
    setError(null);
    api.taskConfig().then(setData).catch((e) => setError(friendlyError(e)));
  }
  useEffect(() => { load(); }, []);

  function beginTask(t: TaskTemplate) {
    setEditMs(null); setEditTask(t.id);
    setD({ tok: String(t.rewardTokens), dia: String(t.rewardDiamonds), pts: String(t.rewardPoints), active: t.isActive });
  }
  function beginMs(m: DailyMilestone) {
    setEditTask(null); setEditMs(m.id);
    setD({ tok: String(m.rewardTokens), dia: String(m.rewardDiamonds), pts: '', active: m.isActive });
  }
  const valid = (s: string) => { const n = Number(s); return Number.isFinite(n) && n >= 0; };

  async function saveTask(id: string) {
    if (!valid(d.tok) || !valid(d.dia) || !valid(d.pts)) return;
    try {
      await api.updateTask(id, { rewardTokens: Number(d.tok), rewardDiamonds: Number(d.dia), rewardPoints: Number(d.pts), isActive: d.active });
      setEditTask(null); load();
    } catch (e) { setError(friendlyError(e)); }
  }
  async function saveMs(id: string) {
    if (!valid(d.tok) || !valid(d.dia)) return;
    try {
      await api.updateMilestone(id, { rewardTokens: Number(d.tok), rewardDiamonds: Number(d.dia), isActive: d.active });
      setEditMs(null); load();
    } catch (e) { setError(friendlyError(e)); }
  }

  const tasks = data?.tasks ?? [];
  const totalPages = Math.max(1, Math.ceil(tasks.length / PAGE_SIZE));
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);
  const pageTasks = useMemo(() => tasks.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE), [tasks, page]);
  const k = data?.kpis;

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      {error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
            {!k ? Array.from({ length: 3 }).map((_, i) => (
              <div key={i} style={{ minHeight: 120, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}><Skeleton height={12} width="55%" /><div style={{ height: 12 }} /><Skeleton height={26} width="45%" /></div>
            )) : (
              <>
                <KpiCard label="Nhiệm vụ đang bật" valueText={formatInt(k.activeTasks)} kpi={{ value: k.activeTasks, deltaPct: null, spark: [] }} hideSpark note="task template đang chạy" />
                <KpiCard label="Token phát / ngày" valueText={formatInt(k.dailyTokenFaucet)} kpi={{ value: k.dailyTokenFaucet, deltaPct: null, spark: [] }} color="var(--teal-500)" hideSpark note="tối đa mỗi user/ngày" />
                <KpiCard label="Mốc đang bật" valueText={formatInt(k.activeMilestones)} kpi={{ value: k.activeMilestones, deltaPct: null, spark: [] }} color="var(--green-500)" hideSpark note="mốc điểm trong ngày" />
              </>
            )}
          </div>

          <Card title="Nhiệm vụ hằng ngày" subtitle="Vòi phát token/điểm — sửa phần thưởng để cân bằng kinh tế" padding="none">
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead>
                  <tr>
                    <th style={TH}>Nhiệm vụ</th><th style={TH}>Loại</th>
                    <th style={{ ...TH, textAlign: 'right' }}>Mục tiêu</th><th style={TH}>Thưởng</th>
                    <th style={TH}>Trạng thái</th><th style={{ ...TH, textAlign: 'right' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {!data && Array.from({ length: 4 }).map((_, i) => (<tr key={`s${i}`}><td style={TD} colSpan={6}><Skeleton height={24} /></td></tr>))}
                  {pageTasks.map((t: TaskTemplate) => (
                    <Fragment key={t.id}>
                      <tr style={{ opacity: t.isActive ? 1 : 0.55 }}>
                        <td style={TD}>
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                            <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{t.title}</span>
                            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-faint)' }}>{t.code}</span>
                          </span>
                        </td>
                        <td style={TD}><Tag tone="neutral">{taskTypeLabel(t.taskType)}</Tag></td>
                        <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-body)' }}>{formatInt(t.targetValue)}</td>
                        <td style={TD}><Reward tokens={t.rewardTokens} diamonds={t.rewardDiamonds} points={t.rewardPoints} /></td>
                        <td style={TD}><StatusBadge status={t.isActive ? 'approved' : 'suspended'}>{t.isActive ? 'Đang bật' : 'Tắt'}</StatusBadge></td>
                        <td style={{ ...TD, textAlign: 'right' }}>
                          {editTask !== t.id && <button type="button" onClick={() => beginTask(t)} style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--brand)', background: 'transparent', border: 'none', cursor: 'pointer' }}>Sửa</button>}
                        </td>
                      </tr>
                      {editTask === t.id && (
                        <tr>
                          <td style={{ ...TD, background: 'var(--slate-25)' }} colSpan={6}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
                              <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>Sửa "{t.title}":</span>
                              <label style={lbl}>🪙 Token<input type="number" min={0} value={d.tok} onChange={(e) => setD({ ...d, tok: e.target.value })} aria-label="Token thưởng" style={numInput} /></label>
                              <label style={lbl}>💎 Kim cương<input type="number" min={0} value={d.dia} onChange={(e) => setD({ ...d, dia: e.target.value })} aria-label="Kim cương thưởng" style={numInput} /></label>
                              <label style={lbl}>⭐ Điểm<input type="number" min={0} value={d.pts} onChange={(e) => setD({ ...d, pts: e.target.value })} aria-label="Điểm thưởng" style={numInput} /></label>
                              <label style={chk}><input type="checkbox" checked={d.active} onChange={(e) => setD({ ...d, active: e.target.checked })} style={{ width: 15, height: 15, accentColor: 'var(--brand)' }} /> Đang bật</label>
                              <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
                                <Button size="sm" onClick={() => saveTask(t.id)}>Lưu</Button>
                                <Button variant="secondary" size="sm" onClick={() => setEditTask(null)}>Hủy</Button>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  ))}
                  {data && tasks.length === 0 && (<tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={6}>Chưa có nhiệm vụ.</td></tr>)}
                </tbody>
              </table>
            </div>
            {totalPages > 1 && (
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)' }}>
                <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}><b style={{ color: 'var(--text-body)', fontWeight: 600 }}>{formatInt(tasks.length)}</b> nhiệm vụ</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-medium) 12px/1 var(--font-mono)' }}>
                  {pages.map((p, i) => p === '…' ? (<span key={`e${i}`} style={{ color: 'var(--text-faint)', padding: '0 4px' }}>…</span>) : (
                    <button key={p} type="button" onClick={() => setPage(p as number)} style={{ minWidth: 28, height: 28, padding: '0 8px', borderRadius: 7, border: 'none', cursor: 'pointer', fontFamily: 'var(--font-mono)', fontSize: 12, background: p === page ? 'var(--brand)' : 'transparent', color: p === page ? '#fff' : 'var(--text-body)' }}>{p}</button>
                  ))}
                </div>
                <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>15 dòng / trang</span>
              </div>
            )}
          </Card>

          <div style={{ height: 22 }} />

          <Card title="Mốc điểm trong ngày" subtitle="Thưởng khi đạt ngưỡng điểm tích lũy" padding="none">
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead>
                  <tr>
                    <th style={{ ...TH, textAlign: 'right' }}>Ngưỡng điểm</th><th style={TH}>Thưởng</th>
                    <th style={TH}>Trạng thái</th><th style={{ ...TH, textAlign: 'right' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {!data && Array.from({ length: 3 }).map((_, i) => (<tr key={`m${i}`}><td style={TD} colSpan={4}><Skeleton height={24} /></td></tr>))}
                  {(data?.milestones ?? []).map((m: DailyMilestone) => (
                    <Fragment key={m.id}>
                      <tr style={{ opacity: m.isActive ? 1 : 0.55 }}>
                        <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{formatInt(m.pointsRequired)} ⭐</td>
                        <td style={TD}><Reward tokens={m.rewardTokens} diamonds={m.rewardDiamonds} /></td>
                        <td style={TD}><StatusBadge status={m.isActive ? 'approved' : 'suspended'}>{m.isActive ? 'Đang bật' : 'Tắt'}</StatusBadge></td>
                        <td style={{ ...TD, textAlign: 'right' }}>
                          {editMs !== m.id && <button type="button" onClick={() => beginMs(m)} style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--brand)', background: 'transparent', border: 'none', cursor: 'pointer' }}>Sửa</button>}
                        </td>
                      </tr>
                      {editMs === m.id && (
                        <tr>
                          <td style={{ ...TD, background: 'var(--slate-25)' }} colSpan={4}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
                              <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>Mốc {formatInt(m.pointsRequired)} điểm:</span>
                              <label style={lbl}>🪙 Token<input type="number" min={0} value={d.tok} onChange={(e) => setD({ ...d, tok: e.target.value })} aria-label="Token mốc" style={numInput} /></label>
                              <label style={lbl}>💎 Kim cương<input type="number" min={0} value={d.dia} onChange={(e) => setD({ ...d, dia: e.target.value })} aria-label="Kim cương mốc" style={numInput} /></label>
                              <label style={chk}><input type="checkbox" checked={d.active} onChange={(e) => setD({ ...d, active: e.target.checked })} style={{ width: 15, height: 15, accentColor: 'var(--brand)' }} /> Đang bật</label>
                              <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
                                <Button size="sm" onClick={() => saveMs(m.id)}>Lưu</Button>
                                <Button variant="secondary" size="sm" onClick={() => setEditMs(null)}>Hủy</Button>
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </Fragment>
                  ))}
                  {data && data.milestones.length === 0 && (<tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={4}>Chưa có mốc.</td></tr>)}
                </tbody>
              </table>
            </div>
          </Card>
        </>
      )}
    </section>
  );
}

const lbl: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 6, font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)' };
const chk: React.CSSProperties = { display: 'flex', alignItems: 'center', gap: 6, font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)', cursor: 'pointer' };
