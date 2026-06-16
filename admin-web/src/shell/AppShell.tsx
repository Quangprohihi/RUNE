import { Outlet } from 'react-router-dom';
import { CompareBar } from './CompareBar';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';

export function AppShell() {
  return (
    <>
      <CompareBar />
      <div style={{ display: 'grid', gridTemplateColumns: '264px minmax(0,1fr)', minHeight: 'calc(100vh - 46px)', background: 'var(--surface-page)' }}>
        <Sidebar />
        <div style={{ gridColumn: 2, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
          <Topbar />
          <Outlet />
        </div>
      </div>
    </>
  );
}
