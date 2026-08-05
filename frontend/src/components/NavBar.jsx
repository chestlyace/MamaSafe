import { useState, useMemo } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from './LanguageToggle';
import navLogo from '../assets/nav_logo.svg';

function getRoleFromToken() {
  const token = localStorage.getItem('token');
  if (!token) return null;
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.role;
  } catch {
    return null;
  }
}

export default function NavBar() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const role = useMemo(() => getRoleFromToken(), []);

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  const isAdmin = role === 'admin';
  const isSup = !isAdmin && role === 'supervisor';

  const navLinks = [
    ...(isAdmin
      ? [{ path: '/admin', label: t('admin'), icon: 'shield_person' }]
      : [
        { path: '/assess', label: t('new_assessment'), icon: 'assessment' },
        { path: '/patients', label: t('patients'), icon: 'people' },
        { path: '/schedule', label: t('schedule'), icon: 'calendar_month' },
        { path: '/referrals', label: t('referrals'), icon: 'local_hospital' },
        { path: '/history', label: t('history'), icon: 'history' },
        { path: '/dashboard', label: t('dashboard'), icon: 'monitoring' },
        ...(isSup
          ? [{ path: '/supervisor', label: t('supervisor'), icon: 'admin_panel_settings' }]
          : []),
        ...(isSup
          ? [{ path: '/supervisor/invites', label: t('invite_codes'), icon: 'vpn_key' }]
          : []),
        ...(isSup
          ? [{ path: '/supervisor/facilities', label: t('facilities'), icon: 'local_hospital' }]
          : []),
      ]),
    { path: '/profile', label: t('profile'), icon: 'person' },
  ];

  const activePrefixes = ['/patients', '/schedule', '/supervisor', '/admin'];

  const linkClass = (path) =>
    `text-sm whitespace-nowrap transition-colors ${
      activePrefixes.some((p) => path.startsWith(p))
        ? location.pathname.startsWith(path)
          ? 'text-rose-500 font-semibold'
          : 'text-text-body hover:text-rose-500'
        : location.pathname === path
          ? 'text-rose-500 font-semibold'
          : 'text-text-body hover:text-rose-500'
    }`;

  return (
    <>
      <nav className="sticky top-0 z-50 bg-white border-b border-border">
        <div className="max-w-[1200px] mx-auto px-5 h-14 flex items-center justify-between">
          {/* Brand */}
          <Link to="/assess" className="flex items-center">
            <img src={navLogo} alt="MamaSafe" className="h-12 w-auto" />
          </Link>

          {/* Desktop nav — evenly distributed across available width */}
          <div className="hidden lg:flex flex-1 items-center justify-evenly overflow-x-auto no-scrollbar px-4">
            {navLinks.map((link) => (
              <Link key={link.path} to={link.path} className={linkClass(link.path)}>
                {link.label}
              </Link>
            ))}
          </div>

          {/* Right side */}
          <div className="flex items-center gap-3">
            <LanguageToggle />
            <button
              onClick={logout}
              className="hidden lg:block text-sm font-medium text-text-muted hover:text-rose-500 transition-colors"
            >
              {t('logout')}
            </button>
            {/* Mobile hamburger */}
            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="lg:hidden p-1.5 -mr-1.5 text-text-body hover:text-rose-500 transition-colors"
              aria-label="Menu"
            >
              <span className="material-symbols-outlined text-[22px]">
                {mobileOpen ? 'close' : 'menu'}
              </span>
            </button>
          </div>
        </div>
      </nav>

      {/* Mobile drawer */}
      {mobileOpen && (
        <>
          <div
            className="fixed inset-0 bg-black/20 z-40 lg:hidden"
            onClick={() => setMobileOpen(false)}
          />
          <div className="fixed top-14 right-0 w-64 bg-white border-b border-border shadow-lg z-50 lg:hidden">
            <div className="flex flex-col py-2">
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  to={link.path}
                  onClick={() => setMobileOpen(false)}
                  className={`flex items-center gap-3 px-5 py-3 text-sm transition-colors ${
                    (['/patients', '/schedule', '/supervisor', '/admin'].includes(link.path)
                      ? location.pathname.startsWith(link.path)
                      : location.pathname === link.path)
                      ? 'text-rose-500 font-semibold bg-rose-50'
                      : 'text-text-body hover:bg-gray-50'
                  }`}
                >
                  <span className="material-symbols-outlined text-[20px]">{link.icon}</span>
                  {link.label}
                </Link>
              ))}
              <div className="border-t border-border mt-1 pt-1">
                <button
                  onClick={() => { setMobileOpen(false); logout(); }}
                  className="flex items-center gap-3 px-5 py-3 text-sm text-text-muted hover:text-rose-500 hover:bg-gray-50 w-full transition-colors"
                >
                  <span className="material-symbols-outlined text-[20px]">logout</span>
                  {t('logout')}
                </button>
              </div>
            </div>
          </div>
        </>
      )}
    </>
  );
}
