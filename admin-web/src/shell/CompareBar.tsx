import { SegmentedControl } from '../ds';
import { useTheme } from './ThemeProvider';

export function CompareBar() {
  const { variant, setVariant } = useTheme();
  return (
    <div style={{
      position: 'sticky', top: 0, zIndex: 300, height: 46, background: 'var(--slate-950)',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '0 18px 0 20px', gap: 16,
      borderBottom: '1px solid rgba(255,255,255,.08)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, minWidth: 0 }}>
        <img src={`${import.meta.env.BASE_URL}zenzoo-mark.png`} alt="ZenZoo" style={{ width: 22, height: 22, objectFit: 'contain', flex: 'none' }} />
        <span style={{ font: 'var(--fw-bold) 12px/1 var(--font-sans)', letterSpacing: '.14em', textTransform: 'uppercase', color: '#fff' }}>ZenZoo Admin</span>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 'none' }}>
        <span style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.14em', textTransform: 'uppercase', color: 'var(--slate-400)' }}>So sánh</span>
        <SegmentedControl
          variant="dark"
          value={variant}
          onChange={(v) => setVariant(v)}
          options={[{ value: 'a', label: 'A · Console' }, { value: 'b', label: 'B · Workspace' }]}
        />
      </div>
    </div>
  );
}
