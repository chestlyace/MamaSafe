import { useTranslation } from 'react-i18next';

export default function LanguageToggle() {
  const { i18n } = useTranslation();
  const isEn = i18n.language === 'en';

  const toggle = () => {
    const next = isEn ? 'fr' : 'en';
    i18n.changeLanguage(next);
    localStorage.setItem('lang', next);
  };

  return (
    <button
      onClick={toggle}
      className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-border bg-white text-xs font-medium text-text-body hover:border-rose-200 hover:text-rose-500 transition-colors"
      aria-label={isEn ? 'Switch to French' : 'Passer a l\'anglais'}
    >
      <span className="material-symbols-outlined text-[16px]">translate</span>
      <span>{isEn ? 'EN' : 'FR'}</span>
    </button>
  );
}
