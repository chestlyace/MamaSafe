import { useTranslation } from 'react-i18next';
import ScheduleDashboard from '../components/ScheduleDashboard';

export default function SchedulePage() {
  const { t } = useTranslation();

  return (
    <main className="max-w-[1200px] mx-auto px-5 py-8">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-800 tracking-tight">
          {t('visit_schedule')}
        </h1>
        <p className="text-sm text-gray-500 mt-1">
          {t('schedule_description')}
        </p>
      </div>

      <ScheduleDashboard />
    </main>
  );
}
