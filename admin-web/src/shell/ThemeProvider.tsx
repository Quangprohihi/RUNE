import { createContext, useContext, useState } from 'react';
import type { CSSProperties, ReactNode } from 'react';
import { themeVars } from './theme';
import type { ThemeVariant } from './theme';
import { getTheme, setTheme as persistTheme } from '../lib/auth';

interface ThemeCtx { variant: ThemeVariant; setVariant: (v: ThemeVariant) => void; }
const Ctx = createContext<ThemeCtx>({ variant: 'a', setVariant: () => {} });
export const useTheme = () => useContext(Ctx);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [variant, setVariantState] = useState<ThemeVariant>(getTheme());
  const setVariant = (v: ThemeVariant) => { persistTheme(v); setVariantState(v); };
  const style: CSSProperties = {
    ...(themeVars(variant) as CSSProperties),
    background: 'var(--surface-page)',
    color: 'var(--text-body)',
    minHeight: '100vh',
    fontFamily: 'var(--font-sans)',
  };
  return <Ctx.Provider value={{ variant, setVariant }}><div style={style}>{children}</div></Ctx.Provider>;
}
