export type ThemeVariant = 'a' | 'b';
export type Density = 'comfortable' | 'compact';

const railA: Record<string, string> = {
  '--rail-bg': 'var(--slate-900)', '--rail-edge': 'var(--slate-900)',
  '--rail-fg': '#9AA8BE', '--rail-fg-strong': '#FFFFFF', '--rail-muted': '#6C7B93',
  '--rail-border': 'rgba(255,255,255,0.08)', '--rail-hover': 'rgba(255,255,255,0.06)',
  '--rail-active-bg': 'rgba(94,132,240,0.18)', '--rail-active-fg': '#FFFFFF', '--rail-active-bar': '#8FAEF8',
  '--rail-group': '#6C7B93', '--rail-plate-bg': 'rgba(255,255,255,0.04)',
  '--rail-plate-border': 'rgba(255,255,255,0.10)', '--rail-foot': '#6C7B93',
  '--kpi-gap': '1px', '--kpi-wrap-bg': 'var(--border-subtle)',
  '--kpi-wrap-border': '1px solid var(--border-subtle)', '--kpi-wrap-radius': 'var(--radius-lg)',
  '--kpi-wrap-overflow': 'hidden', '--kpi-cell-bg': 'var(--surface-card)',
  '--kpi-cell-border': 'none', '--kpi-cell-radius': '0px', '--kpi-cell-shadow': 'none',
};

const railB: Record<string, string> = {
  '--rail-bg': 'var(--slate-0)', '--rail-edge': 'var(--border-subtle)',
  '--rail-fg': 'var(--slate-600)', '--rail-fg-strong': 'var(--slate-900)', '--rail-muted': 'var(--text-muted)',
  '--rail-border': 'var(--border-subtle)', '--rail-hover': 'var(--surface-hover)',
  '--rail-active-bg': 'var(--surface-brand-soft)', '--rail-active-fg': 'var(--blue-700)', '--rail-active-bar': 'var(--brand)',
  '--rail-group': 'var(--text-faint)', '--rail-plate-bg': 'var(--slate-50)',
  '--rail-plate-border': 'var(--border-subtle)', '--rail-foot': 'var(--text-faint)',
  '--kpi-gap': '14px', '--kpi-wrap-bg': 'transparent',
  '--kpi-wrap-border': '0px solid transparent', '--kpi-wrap-radius': '0px',
  '--kpi-wrap-overflow': 'visible', '--kpi-cell-bg': 'var(--surface-card)',
  '--kpi-cell-border': '1px solid var(--border-subtle)', '--kpi-cell-radius': 'var(--radius-lg)', '--kpi-cell-shadow': 'var(--shadow-sm)',
};

export function themeVars(variant: ThemeVariant, density: Density = 'comfortable'): Record<string, string> {
  return {
    ...(variant === 'a' ? railA : railB),
    '--row-py': density === 'compact' ? '8px' : '13px',
  };
}
