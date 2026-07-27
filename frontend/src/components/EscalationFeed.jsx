import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { getRecentEscalations } from '../api/client';
import { useTranslation } from 'react-i18next';

const ESCALATION_STYLES = {
  low_risk_to_mid_risk: {
    bg: 'bg-amber-50',
    border: 'border-amber-200',
    dot: 'bg-amber-400',
    text: 'text-amber-800',
  },
  mid_risk_to_high_risk: {
    bg: 'bg-red-50',
    border: 'border-red-200',
    dot: 'bg-red-500',
    text: 'text-red-800',
  },
  low_risk_to_high_risk: {
    bg: 'bg-red-50',
    border: 'border-red-300',
    dot: 'bg-red-600',
    text: 'text-red-900',
  },
};

export default function EscalationFeed({ escalations: externalEscalations, loading: externalLoading }) {
  const { t } = useTranslation();
  const [events, setEvents] = useState([]);
  const [loading, setLoading] = useState(true);

  const isControlled = externalEscalations !== undefined;

  useEffect(() => {
    if (isControlled) return;
    getRecentEscalations(7)
      .then(setEvents)
      .catch(() => setEvents([]))
      .finally(() => setLoading(false));
  }, [isControlled]);

  const displayEvents = isControlled ? externalEscalations : events;
  const isLoading = isControlled ? externalLoading : loading;

  if (isLoading) {
    return (
      <div className="bg-white rounded-2xl border border-border p-5">
        <div className="flex items-center gap-2 mb-4">
          <span className="material-symbols-outlined text-rose-500 text-lg">warning</span>
          <h3 className="font-bold text-text-heading text-sm">{t('recent_escalations')}</h3>
        </div>
        <div className="flex items-center justify-center py-8">
          <span className="material-symbols-outlined text-2xl animate-spin text-text-muted/40">progress_activity</span>
        </div>
      </div>
    );
  }

  if (displayEvents.length === 0) {
    return (
      <div className="bg-white rounded-2xl border border-border p-5">
        <div className="flex items-center gap-2 mb-4">
          <span className="material-symbols-outlined text-green-500 text-lg">check_circle</span>
          <h3 className="font-bold text-text-heading text-sm">{t('recent_escalations')}</h3>
        </div>
        <p className="text-text-muted text-xs text-center py-6">
          {t('no_escalations')}
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-2xl border border-border p-5">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          <span className="material-symbols-outlined text-rose-500 text-lg">warning</span>
          <h3 className="font-bold text-text-heading text-sm">{t('recent_escalations')}</h3>
        </div>
        <span className="bg-rose-100 text-rose-700 text-[11px] font-semibold px-2.5 py-0.5 rounded-full">
          {displayEvents.length}
        </span>
      </div>

      <div className="space-y-2">
        {displayEvents.map((event, i) => {
          const style = ESCALATION_STYLES[event.escalation_type] || ESCALATION_STYLES.mid_risk_to_high_risk;
          return (
            <Link
              key={i}
              to={`/patients/${event.patient_id}`}
              className={`flex items-center gap-3 p-3 rounded-xl border ${style.bg} ${style.border} hover:shadow-sm transition-shadow`}
            >
              <span className={`w-2 h-2 rounded-full ${style.dot} flex-shrink-0`} />
              <div className="flex-1 min-w-0">
                <p className={`text-xs font-semibold ${style.text} truncate`}>
                  {event.patient_name}
                </p>
                <p className="text-[11px] text-text-muted mt-0.5">
                  {event.from?.replace(' risk', '')} → {event.to?.replace(' risk', '')} · {event.date}
                </p>
              </div>
              <span className="material-symbols-outlined text-text-muted/40 text-lg">chevron_right</span>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
