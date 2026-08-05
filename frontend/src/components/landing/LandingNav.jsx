import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import LanguageToggle from '../LanguageToggle';
import navLogo from '../../assets/nav_logo.svg';

export default function LandingNav() {
  const { t } = useTranslation();
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const links = [
    ['problem', '#problem'],
    ['what', '#what'],
    ['how', '#how'],
    ['features', '#features'],
    ['audiences', '#audiences'],
  ];

  return (
    <header
      className={`fixed top-0 inset-x-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'bg-canvas/95 backdrop-blur-md shadow-[0_1px_0_0_rgba(61,56,71,0.08)]'
          : 'bg-transparent'
      }`}
    >
      <nav
        className="mx-auto flex max-w-6xl items-center justify-between gap-4 px-5 py-3"
        aria-label="Main"
      >
        <a href="#top" className="flex items-center">
          <img src={navLogo} alt="MamaSafe" className="h-12 w-auto" />
        </a>
        <ul className="hidden items-center gap-6 lg:flex">
          {links.map(([key, href]) => (
            <li key={key}>
              <a
                href={href}
                className="text-sm font-medium text-text-body hover:text-rose-primary transition-colors"
              >
                {t(`landing.nav.${key}`)}
              </a>
            </li>
          ))}
        </ul>
        <div className="flex items-center gap-2">
          <LanguageToggle />
          <Link
            to="/login"
            className="hidden sm:inline-flex rounded-full px-4 py-2 text-sm font-semibold text-text-heading hover:text-rose-primary transition-colors"
          >
            {t('landing.nav.login')}
          </Link>
          <Link
            to="/signup"
            className="inline-flex rounded-full bg-rose-primary px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-rose-hover transition-colors"
          >
            {t('landing.nav.cta')}
          </Link>
        </div>
      </nav>
    </header>
  );
}
