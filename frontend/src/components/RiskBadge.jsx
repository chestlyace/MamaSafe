import { useTranslation } from 'react-i18next';

const COLORS = {
  high: 'bg-red-100 text-red-800 border-red-300',
  mid: 'bg-amber-100 text-amber-800 border-amber-300',
  low: 'bg-green-100 text-green-800 border-green-300',
};

export default function RiskBadge({ level }) {
  const { t } = useTranslation();
  const key = level === 'high risk' ? 'high' : level === 'mid risk' ? 'mid' : 'low';
  return (
    <span className={`inline-block px-3 py-1 rounded-full text-sm font-semibold border ${COLORS[key]}`}>
      {t(`risk.${key}`)}
    </span>
  );
}
