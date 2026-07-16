import { useState } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from './LanguageToggle';
import navLogo from '../assets/nav_logo.svg';

export default function NavBar() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileOpen, setMobileOpen] = useState(false);

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  const navLinks = [
    { path: '/assess', label: t('new_assessment'), icon: 'assessment' },
    { path: '/patients', label: t('patients'), icon: 'people' },
    { path: '/referrals', label: t('referrals'), icon: 'local_hospital' },
    { path: '/history', label: t('history'), icon: 'history' },
    { path: '/dashboard', label: t('dashboard'), icon: 'monitoring' },
  ];

  const linkClass = (path) =>
    `text-sm transition-colors ${
      path === '/patients'
        ? location.pathname.startsWith('/patients')
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
            <img src={navLogo} alt="MamaSafe" className="h-16 w-auto" />
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-8">
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
              className="hidden md:block text-sm font-medium text-text-muted hover:text-rose-500 transition-colors"
            >
              {t('logout')}
            </button>
            {/* Mobile hamburger */}
            <button
              onClick={() => setMobileOpen(!mobileOpen)}
              className="md:hidden p-1.5 -mr-1.5 text-text-body hover:text-rose-500 transition-colors"
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
            className="fixed inset-0 bg-black/20 z-40 md:hidden"
            onClick={() => setMobileOpen(false)}
          />
          <div className="fixed top-14 right-0 w-64 bg-white border-b border-border shadow-lg z-50 md:hidden">
            <div className="flex flex-col py-2">
              {navLinks.map((link) => (
                <Link
                  key={link.path}
                  to={link.path}
                  onClick={() => setMobileOpen(false)}
                  className={`flex items-center gap-3 px-5 py-3 text-sm transition-colors ${
                    (link.path === '/patients' ? location.pathname.startsWith('/patients') : location.pathname === link.path)
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
