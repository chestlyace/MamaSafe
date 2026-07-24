import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getScheduleAnalytics, getTodaysVisits } from '../api/client';

export default function ScheduleDashboard() {
  const { t } = useTranslation();
  const [analytics, setAnalytics] = useState(null);
  const [todaysVisits, setTodaysVisits] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([getScheduleAnalytics(), getTodaysVisits()])
      .then(([a, v]) => { setAnalytics(a); setTodaysVisits(v); })
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <span className="material-symbols-outlined text-2xl animate-spin text-rose-500 mr-2">progress_activity</span>
        <span className="text-sm text-gray-400">{t('loading')}</span>
      </div>
    );
  }

  if (!analytics) return null;

  const stats = [
    { label: t('total_scheduled'), value: analytics.total_scheduled, icon: 'calendar_month', color: 'text-indigo-500' },
    { label: t('completed'), value: analytics.completed, icon: 'check_circle', color: 'text-green-500' },
    { label: t('missed'), value: analytics.missed, icon: 'cancel', color: 'text-red-500' },
    { label: t('upcoming_this_week'), value: analytics.upcoming_this_week, icon: 'upcoming', color: 'text-amber-500' },
  ];

  return (
    <div className="space-y-6">
      {/* Stats grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((s) => (
          <div key={s.label} className="bg-white rounded-2xl border border-gray-200 p-4">
            <div className="flex items-center gap-2 mb-2">
              <span className={`material-symbols-outlined text-[20px] ${s.color}`}>{s.icon}</span>
              <span className="text-xs font-medium text-gray-500">{s.label}</span>
            </div>
            <p className="text-2xl font-bold text-gray-800">{s.value}</p>
          </div>
        ))}
      </div>

      {/* Completion rate */}
      <div className="bg-white rounded-2xl border border-gray-200 p-5">
        <div className="flex items-center justify-between mb-3">
          <h3 className="font-bold text-gray-800">{t('completion_rate')}</h3>
          <span className="text-lg font-bold text-indigo-600">{analytics.completion_rate}%</span>
        </div>
        <div className="h-3 bg-gray-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-indigo-500 rounded-full transition-all duration-500"
            style={{ width: `${analytics.completion_rate}%` }}
          />
        </div>
        <p className="text-xs text-gray-400 mt-2">
          {analytics.missed_rate}% {t('missed_rate_label')}
        </p>
      </div>

      {/* Today's visits */}
      <div className="bg-white rounded-2xl border border-gray-200 p-5">
        <h3 className="font-bold text-gray-800 mb-4">{t('todays_visits')}</h3>
        {todaysVisits.length === 0 ? (
          <div className="text-center py-6">
            <span className="material-symbols-outlined text-[36px] text-gray-300 mb-2">event_available</span>
            <p className="text-sm text-gray-400">{t('no_visits_today')}</p>
          </div>
        ) : (
          <div className="space-y-2">
            {todaysVisits.map((v) => (
              <div key={v.visit_id} className="flex items-center gap-3 p-3 bg-indigo-50 rounded-xl">
                <div className="w-8 h-8 rounded-full bg-indigo-500 flex items-center justify-center text-xs font-bold text-white">
                  {v.visit_number}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-800 truncate">{v.patient_name}</p>
                  <p className="text-xs text-gray-500">{v.label}</p>
                </div>
                <span className="text-xs text-gray-400">{v.patient_phone}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
