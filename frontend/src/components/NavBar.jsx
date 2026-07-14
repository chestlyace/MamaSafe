import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from './LanguageToggle';

export default function NavBar() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  const linkClass = (path) =>
    `transition-colors ${
      location.pathname === path
        ? 'text-indigo-600 font-bold border-b-2 border-indigo-600 pb-1'
        : 'text-gray-500 hover:text-indigo-600'
    }`;

  return (
    <nav className="sticky top-0 z-50 flex justify-between items-center w-full px-6 md:px-12 py-4 max-w-[1200px] mx-auto bg-white/95 backdrop-blur-sm shadow-sm">
      {/* Brand */}
      <Link to="/assess" className="flex items-center gap-2">
        <span className="text-3xl">&#x1F931;</span>
        <span className="text-lg font-bold text-indigo-600">MamaSafe</span>
      </Link>

      {/* Desktop nav */}
      <div className="hidden md:flex items-center space-x-8 text-sm">
        <Link to="/assess" className={linkClass('/assess')}>
          {t('new_assessment')}
        </Link>
        <Link to="/history" className={linkClass('/history')}>
          {t('history')}
        </Link>
        <Link to="/dashboard" className={linkClass('/dashboard')}>
          {t('dashboard')}
        </Link>
      </div>

      {/* Right side */}
      <div className="flex items-center gap-4">
        <LanguageToggle />
        <button
          onClick={logout}
          className="text-sm font-bold text-indigo-600 hover:opacity-80 transition-all"
        >
          {t('logout')}
        </button>
      </div>
    </nav>
  );
}
