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
      className="px-2 py-1 text-sm border rounded hover:bg-gray-100 transition-colors"
    >
      {i18n.language === 'en' ? 'FR' : 'EN'}
    </button>
  );
}
