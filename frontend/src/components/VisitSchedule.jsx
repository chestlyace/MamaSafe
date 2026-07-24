import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getSchedule } from '../api/client';
import RescheduleModal from './RescheduleModal';

const STATUS_STYLES = {
  scheduled:   { dot: 'bg-indigo-500', label: 'Scheduled',   text: 'text-indigo-600', bg: 'bg-indigo-50' },
  completed:   { dot: 'bg-green-500',  label: 'Completed',   text: 'text-green-600',  bg: 'bg-green-50'  },
  missed:      { dot: 'bg-red-500',    label: 'Missed',      text: 'text-red-600',    bg: 'bg-red-50'    },
  rescheduled: { dot: 'bg-amber-500',  label: 'Rescheduled', text: 'text-amber-600',  bg: 'bg-amber-50'  },
  cancelled:   { dot: 'bg-gray-400',   label: 'Cancelled',   text: 'text-gray-500',   bg: 'bg-gray-50'   },
};

const STATUS_DOT_COLORS = {
  indigo: '#6366F1',
  green:  '#22C55E',
  red:    '#EF4444',
  amber:  '#F59E0B',
  gray:   '#9CA3AF',
};

function getDotColor(dotClass) {
  for (const [key, color] of Object.entries(STATUS_DOT_COLORS)) {
    if (dotClass.includes(key)) return color;
  }
  return STATUS_DOT_COLORS.gray;
}

export default function VisitSchedule({ pregnancyId, onReschedule }) {
  const { t } = useTranslation();
  const [visits, setVisits] = useState([]);
  const [loading, setLoading] = useState(true);
  const [rescheduleVisit, setRescheduleVisit] = useState(null);

  useEffect(() => {
    if (!pregnancyId) return;
    getSchedule(pregnancyId)
      .then(setVisits)
      .finally(() => setLoading(false));
  }, [pregnancyId]);

  const handleRescheduled = () => {
    setRescheduleVisit(null);
    getSchedule(pregnancyId).then(setVisits);
    if (onReschedule) onReschedule();
  };

  if (loading) {
    return (
      <div className="text-gray-400 text-sm py-4 flex items-center gap-2">
        <span className="material-symbols-outlined text-[16px] animate-spin">progress_activity</span>
        {t('loading')}
      </div>
    );
  }

  if (visits.length === 0) return null;

  const completed = visits.filter(v => v.status === 'completed').length;
  const pct = Math.round((completed / visits.length) * 100);
  const today = new Date().toISOString().split('T')[0];

  return (
    <>
      <div className="bg-white rounded-2xl border border-gray-200 p-5">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-bold text-gray-800">{t('anc_visit_schedule')}</h3>
          <span className="text-sm text-gray-500">
            {completed}/{visits.length} {t('completed')}
          </span>
        </div>

        {/* Progress bar */}
        <div className="h-2 bg-gray-100 rounded-full overflow-hidden mb-5">
          <div
            className="h-full bg-indigo-500 rounded-full transition-all duration-500"
            style={{ width: `${pct}%` }}
          />
        </div>

        {/* Visit timeline */}
        <div className="space-y-2">
          {visits.map((visit) => {
            const sc = STATUS_STYLES[visit.status] || STATUS_STYLES.scheduled;
            const isToday = visit.scheduled_date === today;
            return (
              <div
                key={visit.id}
                className={`flex items-center gap-3 p-3 rounded-xl border transition-colors
                            ${sc.bg} ${isToday ? 'ring-2 ring-indigo-400' : 'border-transparent'}`}
              >
                <div
                  className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold text-white flex-shrink-0"
                  style={{ background: getDotColor(sc.dot) }}
                >
                  {visit.visit_number}
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium text-gray-800 truncate">
                      {visit.label}
                    </p>
                    {isToday && (
                      <span className="text-xs bg-indigo-600 text-white px-2 py-0.5 rounded-full">
                        {t('today')}
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5">
                    {new Date(visit.scheduled_date).toLocaleDateString('en-GB', {
                      day: 'numeric', month: 'short', year: 'numeric'
                    })}
                    {visit.original_date && (
                      <span className="ml-2 line-through text-gray-300">
                        {new Date(visit.original_date).toLocaleDateString('en-GB', {
                          day: 'numeric', month: 'short'
                        })}
                      </span>
                    )}
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <span className={`text-xs font-semibold ${sc.text}`}>
                    {sc.label}
                  </span>
                  {visit.status === 'scheduled' && (
                    <button
                      onClick={() => setRescheduleVisit(visit)}
                      className="text-gray-400 hover:text-indigo-500 transition-colors"
                      title={t('reschedule')}
                    >
                      <span className="material-symbols-outlined text-[18px]">edit_calendar</span>
                    </button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {rescheduleVisit && (
        <RescheduleModal
          visit={rescheduleVisit}
          onClose={() => setRescheduleVisit(null)}
          onRescheduled={handleRescheduled}
        />
      )}
    </>
  );
}
