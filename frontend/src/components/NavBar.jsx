import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from './LanguageToggle';

export default function NavBar() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const token = localStorage.getItem('token');

  const logout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  return (
    <nav className="bg-white shadow-sm border-b">
      <div className="max-w-5xl mx-auto px-4 h-14 flex items-center justify-between">
        <Link to="/" className="text-lg font-bold text-indigo-600">
          {t('app.title')}
        </Link>

        <div className="flex items-center gap-4 text-sm">
          {token && (
            <>
              <Link to="/assess" className="hover:text-indigo-600 transition-colors">
                {t('nav.assess')}
              </Link>
              <Link to="/history" className="hover:text-indigo-600 transition-colors">
                {t('nav.history')}
              </Link>
              <Link to="/dashboard" className="hover:text-indigo-600 transition-colors">
                {t('nav.dashboard')}
              </Link>
              <button onClick={logout} className="text-red-500 hover:text-red-700 transition-colors">
                {t('nav.logout')}
              </button>
            </>
          )}
          <LanguageToggle />
        </div>
      </div>
    </nav>
  );
}
