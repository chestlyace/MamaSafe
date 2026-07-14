import { useTranslation } from 'react-i18next';

export default function LanguageToggle() {
  const { i18n } = useTranslation();

  const toggle = () => {
    const next = i18n.language === 'en' ? 'fr' : 'en';
    i18n.changeLanguage(next);
    localStorage.setItem('lang', next);
  };

  return (
    <button
      onClick={toggle}
      className="flex items-center gap-1.5 px-4 py-1.5 bg-gray-100 rounded-full text-gray-600 text-xs font-semibold hover:bg-gray-200 transition-colors"
    >
      <span className="material-symbols-outlined text-base">language</span>
      <span>{i18n.language === 'en' ? 'EN/FR' : 'FR/EN'}</span>
    </button>
  );
}
