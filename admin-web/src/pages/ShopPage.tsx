import { useEffect, useMemo, useState } from 'react';
import { Card, Button, SegmentedControl, StatusBadge, Tag, Icon, icons } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import { pageList } from '../lib/pageList';
import type { EconomyResponse, ShopItem, RangeKey } from '../lib/types';

const RANGE_OPTS: { value: RangeKey; label: string }[] = [
  { value: 'today', label: 'Hôm nay' }, { value: '7d', label: '7 ngày' },
  { value: '30d', label: '30 ngày' }, { value: 'quarter', label: 'Quý' },
];

const ITEM_TYPE_LABELS: Record<string, string> = {
  companion: 'Bạn đồng hành', boost: 'Tăng lực', skin: 'Giao diện', consumable: 'Tiêu hao', decor: 'Trang trí',
};
const itemTypeLabel = (t: string) => ITEM_TYPE_LABELS[t] ?? t;

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: 'var(--row-py, 13px) 16px', borderBottom: '1px solid var(--border-subtle)' };
const PAGE_SIZE = 15;

export function ShopPage() {
  const [range, setRange] = useState<RangeKey>('30d');
  const [eco, setEco] = useState<EconomyResponse | null>(null);
  const [ecoErr, setEcoErr] = useState<string | null>(null);

  const [items, setItems] = useState<ShopItem[] | null>(null);
  const [itemsErr, setItemsErr] = useState<string | null>(null);
  const [page, setPage] = useState(1);

  const [editId, setEditId] = useState<string | null>(null);
  const [draftPrice, setDraftPrice] = useState('');
  const [draftActive, setDraftActive] = useState(true);
  const [draftHot, setDraftHot] = useState(false);

  function loadEco() {
    setEcoErr(null);
    api.economy(range).then(setEco).catch((e) => setEcoErr(friendlyError(e)));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { loadEco(); }, [range]);

  function loadItems() {
    setItemsErr(null);
    api.shopItems().then((r) => setItems(r.items)).catch((e) => setItemsErr(friendlyError(e)));
  }
  useEffect(() => { loadItems(); }, []);

  async function saveItem(id: string) {
    const priceTokens = Number(draftPrice);
    if (!Number.isFinite(priceTokens) || priceTokens < 0) return;
    try {
      await api.updateShopItem(id, { priceTokens, isActive: draftActive, isHot: draftHot });
      setEditId(null);
      loadItems();
      loadEco();
    } catch (e) {
      setItemsErr(friendlyError(e));
    }
  }

  const total = items?.length ?? 0;
  const totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);
  const pageItems = useMemo(() => (items ?? []).slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE), [items, page]);

  function exportCsv() {
    const csv = toCsv(
      ['Mã', 'Tên', 'Loại', 'Giá (token)', 'Hiệu ứng', 'Nổi bật', 'Đang bán'],
      items ?? [],
      (it) => [it.code, it.name, itemTypeLabel(it.itemType), it.priceTokens, `${it.effectType}+${it.effectValue}`, it.isHot ? 'có' : 'không', it.isActive ? 'có' : 'không'],
    );
    downloadCsv('zenzoo-shop-items.csv', csv);
  }

  const k = eco?.kpis;
  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
        <SegmentedControl variant="lite" value={range} options={RANGE_OPTS} onChange={setRange} />
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
      </div>

      {ecoErr ? (
        <ErrorState message={ecoErr} onRetry={loadEco} />
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
          {!k ? Array.from({ length: 4 }).map((_, i) => (
            <div key={i} style={{ minHeight: 120, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}><Skeleton height={12} width="55%" /><div style={{ height: 12 }} /><Skeleton height={26} width="45%" /></div>
          )) : (
            <>
              <KpiCard label="Token phát hành" valueText={formatInt(k.tokenFaucet)} kpi={{ value: k.tokenFaucet, deltaPct: null, spark: [] }} color="var(--teal-500)" hideSpark note="thưởng phát ra" />
              <KpiCard label="Token đã tiêu" valueText={formatInt(k.tokenSink)} kpi={{ value: k.tokenSink, deltaPct: null, spark: [] }} color="var(--blue-500)" hideSpark note="tiêu trong shop" />
              <KpiCard label="Cân bằng token" valueText={formatInt(k.tokenNet)} kpi={{ value: k.tokenNet, deltaPct: null, spark: [] }} color="var(--blue-500)" hideSpark note="phát − tiêu" />
              <KpiCard label="Kim cương phát hành" valueText={formatInt(k.diamondFaucet)} kpi={{ value: k.diamondFaucet, deltaPct: null, spark: [] }} color="var(--green-500)" hideSpark note="thưởng kim cương" />
            </>
          )}
        </div>
      )}

      <Card title="Vật phẩm cửa hàng" subtitle={eco ? `${formatInt(eco.activeItems)} vật phẩm đang bán` : 'Danh mục & giá'} padding="none">
        {itemsErr ? (
          <div style={{ padding: 16 }}><ErrorState message={itemsErr} onRetry={loadItems} /></div>
        ) : (
          <>
            <div style={{ overflowX: 'auto' }}>
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead>
                  <tr>
                    <th style={TH}>Vật phẩm</th><th style={TH}>Loại</th>
                    <th style={{ ...TH, textAlign: 'right' }}>Giá (token)</th><th style={TH}>Trạng thái</th>
                    <th style={{ ...TH, textAlign: 'right' }}></th>
                  </tr>
                </thead>
                <tbody>
                  {!items && Array.from({ length: 6 }).map((_, i) => (<tr key={`s${i}`}><td style={TD} colSpan={5}><Skeleton height={24} /></td></tr>))}
                  {pageItems.map((it: ShopItem) => {
                    const isEditing = editId === it.id;
                    return (
                      <tr key={it.id} style={{ opacity: it.isActive ? 1 : 0.55 }}>
                        <td style={TD}>
                          <span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
                            <span style={{ fontSize: 20 }} aria-hidden>{it.emoji}</span>
                            <span style={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                              <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{it.name}</span>
                              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-faint)' }}>{it.code}</span>
                            </span>
                          </span>
                        </td>
                        <td style={TD}><Tag tone="neutral">{itemTypeLabel(it.itemType)}</Tag></td>
                        <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{formatInt(it.priceTokens)}</td>
                        <td style={TD}>
                          <span style={{ display: 'inline-flex', gap: 6 }}>
                            <StatusBadge status={it.isActive ? 'approved' : 'suspended'}>{it.isActive ? 'Đang bán' : 'Tắt'}</StatusBadge>
                            {it.isHot && <Tag tone="accent">Nổi bật</Tag>}
                          </span>
                        </td>
                        <td style={{ ...TD, textAlign: 'right' }}>
                          {!isEditing && (
                            <button type="button" onClick={() => { setEditId(it.id); setDraftPrice(String(it.priceTokens)); setDraftActive(it.isActive); setDraftHot(it.isHot); }} style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--brand)', background: 'transparent', border: 'none', cursor: 'pointer' }}>Sửa</button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                  {editId && pageItems.some((it) => it.id === editId) && (() => {
                    const it = pageItems.find((x) => x.id === editId)!;
                    return (
                      <tr key={`edit-${it.id}`}>
                        <td style={{ ...TD, background: 'var(--slate-25)' }} colSpan={5}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap' }}>
                            <span style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>Sửa "{it.name}":</span>
                            <label style={{ display: 'flex', alignItems: 'center', gap: 8, font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)' }}>Giá (token)
                              <input type="number" min={0} value={draftPrice} onChange={(e) => setDraftPrice(e.target.value)} aria-label="Giá token" style={{ width: 110, height: 32, padding: '0 10px', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)', font: 'var(--fw-regular) 13px/1 var(--font-mono)', color: 'var(--text-strong)' }} />
                            </label>
                            <label style={{ display: 'flex', alignItems: 'center', gap: 6, font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)', cursor: 'pointer' }}>
                              <input type="checkbox" checked={draftActive} onChange={(e) => setDraftActive(e.target.checked)} style={{ width: 15, height: 15, accentColor: 'var(--brand)' }} /> Đang bán
                            </label>
                            <label style={{ display: 'flex', alignItems: 'center', gap: 6, font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)', cursor: 'pointer' }}>
                              <input type="checkbox" checked={draftHot} onChange={(e) => setDraftHot(e.target.checked)} style={{ width: 15, height: 15, accentColor: 'var(--brand)' }} /> Nổi bật
                            </label>
                            <div style={{ display: 'flex', gap: 8, marginLeft: 'auto' }}>
                              <Button size="sm" onClick={() => saveItem(it.id)}>Lưu</Button>
                              <Button variant="secondary" size="sm" onClick={() => setEditId(null)}>Hủy</Button>
                            </div>
                          </div>
                        </td>
                      </tr>
                    );
                  })()}
                  {items && items.length === 0 && (<tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={5}>Chưa có vật phẩm nào.</td></tr>)}
                </tbody>
              </table>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)', flexWrap: 'wrap' }}>
              <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}><b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{items ? formatInt(total) : '—'}</b> vật phẩm</span>
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-medium) 12px/1 var(--font-mono)' }}>
                {pages.map((p, i) => p === '…' ? (<span key={`e${i}`} style={{ color: 'var(--text-faint)', padding: '0 4px' }}>…</span>) : (
                  <button key={p} type="button" onClick={() => setPage(p as number)} style={{ minWidth: 28, height: 28, padding: '0 8px', borderRadius: 7, border: 'none', cursor: 'pointer', fontFamily: 'var(--font-mono)', fontSize: 12, background: p === page ? 'var(--brand)' : 'transparent', color: p === page ? '#fff' : 'var(--text-body)' }}>{p}</button>
                ))}
              </div>
              <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>15 dòng / trang</span>
            </div>
          </>
        )}
      </Card>
    </section>
  );
}
