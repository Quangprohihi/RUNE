export interface NavBadge { text: string; tone: 'amber' | 'muted' | 'teal-outline'; }
export interface NavItem { screen: string; label: string; to: string; enabled: boolean; badge?: NavBadge; }
export interface NavGroup { title: string; items: NavItem[]; }

const wip = (screen: string, label: string, badge?: NavBadge): NavItem =>
  ({ screen, label, to: `/wip/${screen}`, enabled: false, badge });

export const NAV_GROUPS: NavGroup[] = [
  { title: 'Lõi vận hành', items: [
    { screen: 'overview', label: 'Tổng quan', to: '/', enabled: true },
    { screen: 'users', label: 'Người dùng', to: '/users', enabled: true, badge: { text: '6.8k', tone: 'muted' } },
    { screen: 'reviews', label: 'Đánh giá người dùng', to: '/reviews', enabled: true, badge: { text: '20', tone: 'muted' } },
    wip('moderation', 'Kiểm duyệt', { text: '5', tone: 'amber' }),
  ]},
  { title: 'Dòng tiền', items: [
    { screen: 'billing', label: 'Thanh toán & Gói', to: '/billing', enabled: true },
    wip('ops', 'Vận hành & IPN'),
  ]},
  { title: 'Phân tích', items: [
    { screen: 'analytics', label: 'Phân tích', to: '/analytics', enabled: true },
    { screen: 'audit', label: 'Nhật ký kiểm toán', to: '/audit', enabled: true },
  ]},
  { title: 'Nội dung game', items: [
    { screen: 'tasks', label: 'Nhiệm vụ & Mốc', to: '/tasks', enabled: true },
    { screen: 'shop', label: 'Cửa hàng & Kinh tế', to: '/shop', enabled: true },
    wip('pets', 'Thú cưng & Tiến hóa'),
    wip('achievements', 'Thành tựu & Streak'),
    wip('ai', 'AI Focus Designer', { text: 'Beta', tone: 'teal-outline' }),
  ]},
  { title: 'Tiếp cận', items: [
    wip('notifications', 'Thông báo & Chiến dịch'),
  ]},
  { title: 'Quản trị & bảo mật', items: [
    wip('rbac', 'Vai trò & Bảo mật'),
    wip('adminteam', 'Đội quản trị'),
    wip('flags', 'Cờ tính năng'),
    wip('gdpr', 'Quyền riêng tư & Xuất DL'),
    wip('bulk', 'Tác vụ hàng loạt'),
    wip('support', 'Hỗ trợ', { text: '12', tone: 'muted' }),
  ]},
];

export interface RouteMeta { crumb: string; title: string; }
export const ROUTE_META: Record<string, RouteMeta> = {
  '/': { crumb: 'Lõi vận hành', title: 'Tổng quan' },
  '/users': { crumb: 'Lõi vận hành', title: 'Người dùng' },
  '/reviews': { crumb: 'Lõi vận hành', title: 'Đánh giá người dùng' },
  '/billing': { crumb: 'Dòng tiền', title: 'Thanh toán & Gói' },
  '/analytics': { crumb: 'Phân tích', title: 'Phân tích' },
  '/audit': { crumb: 'Phân tích', title: 'Nhật ký kiểm toán' },
  '/shop': { crumb: 'Nội dung game', title: 'Cửa hàng & Kinh tế' },
  '/tasks': { crumb: 'Nội dung game', title: 'Nhiệm vụ & Mốc' },
};
export function metaFor(pathname: string): RouteMeta {
  if (pathname.startsWith('/users')) return ROUTE_META['/users'];
  if (pathname.startsWith('/reviews')) return ROUTE_META['/reviews'];
  if (pathname.startsWith('/billing')) return ROUTE_META['/billing'];
  if (pathname.startsWith('/analytics')) return ROUTE_META['/analytics'];
  if (pathname.startsWith('/audit')) return ROUTE_META['/audit'];
  if (pathname.startsWith('/shop')) return ROUTE_META['/shop'];
  if (pathname.startsWith('/tasks')) return ROUTE_META['/tasks'];
  return ROUTE_META['/'];
}
