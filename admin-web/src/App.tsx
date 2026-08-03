import { Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider } from './shell/ThemeProvider';
import { ProtectedRoute } from './shell/ProtectedRoute';
import { AppShell } from './shell/AppShell';
import { LoginPage } from './pages/LoginPage';
import { WipPage } from './pages/WipPage';
import { OverviewPage } from './pages/OverviewPage';
import { UsersPage } from './pages/UsersPage';
import { UserDetailPage } from './pages/UserDetailPage';
import { BillingPage } from './pages/BillingPage';
import { AnalyticsPage } from './pages/AnalyticsPage';
import { AuditPage } from './pages/AuditPage';
import { ShopPage } from './pages/ShopPage';
import { TasksPage } from './pages/TasksPage';
import { ReviewsPage } from './pages/ReviewsPage';

export default function App() {
  return (
    <ThemeProvider>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route element={<ProtectedRoute />}>
          <Route element={<AppShell />}>
            <Route path="/" element={<OverviewPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/users/:id" element={<UserDetailPage />} />
            <Route path="/reviews" element={<ReviewsPage />} />
            <Route path="/billing" element={<BillingPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/audit" element={<AuditPage />} />
            <Route path="/shop" element={<ShopPage />} />
            <Route path="/tasks" element={<TasksPage />} />
            <Route path="/wip/:screen" element={<WipPage />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </ThemeProvider>
  );
}
