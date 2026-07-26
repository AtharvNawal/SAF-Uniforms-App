import { IconName } from '../../shared/icon/icon.component';

export interface NavItem {
  key: string;
  labelKey: string; // i18n key
  icon: IconName;
  route: string;
}

export const SIDEBAR_ITEMS: NavItem[] = [
  { key: 'dashboard', labelKey: 'nav.dashboard', icon: 'home', route: '/dashboard' },
  { key: 'dress', labelKey: 'nav.dress', icon: 'uniform', route: '/dress' },
  { key: 'accessories', labelKey: 'nav.accessories', icon: 'badge', route: '/accessories' },
  { key: 'models', labelKey: 'nav.models', icon: 'cube', route: '/models' },
  { key: 'branches', labelKey: 'nav.branches', icon: 'shield', route: '/branches' },
  { key: 'logic', labelKey: 'nav.logic', icon: 'sliders', route: '/logic' },
  { key: 'users', labelKey: 'nav.users', icon: 'users', route: '/users' },
  { key: 'admins', labelKey: 'nav.admins', icon: 'key', route: '/admins' },
];

export const SIDEBAR_FOOT: NavItem[] = [
  { key: 'settings', labelKey: 'nav.settings', icon: 'gear', route: '/settings' },
];

// Mobile bottom-nav: first 4 sidebar items + a "More" entry.
export const MOBILE_PRIMARY: NavItem[] = SIDEBAR_ITEMS.slice(0, 4).map((i) => ({
  ...i,
  labelKey: `nav.tab${i.key.charAt(0).toUpperCase() + i.key.slice(1)}`,
}));

// Items shown inside the "More" overflow modal — everything not in MOBILE_PRIMARY.
export const MOBILE_OVERFLOW: NavItem[] = [
  ...SIDEBAR_ITEMS.slice(4),
  ...SIDEBAR_FOOT,
];
