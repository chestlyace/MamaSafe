import { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { getAssessments } from '../api/client';

const RISK_STYLES = {
  high: { dot: 'bg-red-500', text: 'text-red-600', bg: 'bg-red-50', border: 'border-red-200', i18nKey: 'high_risk' },
  mid: { dot: 'bg-amber-500', text: 'text-amber-600', bg: 'bg-amber-50', border: 'border-amber-200', i18nKey: 'moderate_risk' },
  low: { dot: 'bg-green-500', text: 'text-green-600', bg: 'bg-green-50', border: 'border-green-200', i18nKey: 'low_risk' },
};

function riskKey(level) {
  if (level === 'high risk') return 'high';
  if (level === 'mid risk') return 'mid';
  return 'low';
}

function formatDate(iso) {
  const d = new Date(iso);
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
    + ' \u2022 '
    + d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
}

export default function HistoryPage() {
  const { t } = useTranslation();
  const [assessments, setAssessments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    getAssessments(0, 100)
      .then((data) => setAssessments(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const filtered = useMemo(() => {
    if (!search.trim()) return assessments;
    const term = search.toLowerCase();
    return assessments.filter((a) => a.patient_ref?.toLowerCase().includes(term));
  }, [assessments, search]);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      </main>
    );
  }

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('assessment_history')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('manage_history')}</p>
        </div>
        <div className="relative">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">search</span>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('search_patient_id')}
            className="pl-10 pr-4 py-2.5 border border-border rounded-xl bg-white w-full sm:w-56 text-sm focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
          />
        </div>
      </div>

      {/* Cards */}
      {filtered.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {filtered.map((a) => {
            const rk = riskKey(a.risk_level);
            const style = RISK_STYLES[rk];
            return (
              <div
                key={a.id}
                className="bg-white border border-border rounded-2xl p-5 hover:shadow-md hover:border-rose-100 transition-all"
              >
                {/* Top row */}
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{t('patient_id')}</span>
                    <p className="text-lg font-semibold text-text-heading mt-0.5">{a.patient_ref || '\u2014'}</p>
                  </div>
                  <div className="flex flex-col items-end gap-2">
                    <span className="text-xs text-text-muted">{formatDate(a.created_at)}</span>
                    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${style.bg} ${style.border} ${style.text} border`}>
                      <span className={`w-1.5 h-1.5 rounded-full ${style.dot}`} />
                      {t(style.i18nKey)}
                    </span>
                  </div>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-3 bg-surface rounded-xl p-3.5 mb-4">
                  <div>
                    <span className="text-[11px] text-text-muted block">{t('age')}</span>
                    <span className="text-sm font-semibold text-text-heading">{a.age}</span>
                  </div>
                  <div className="text-center border-x border-border px-3">
                    <span className="text-[11px] text-text-muted block">{t('systolic_bp')}</span>
                    <span className={`text-sm font-semibold ${rk === 'high' ? 'text-red-600' : 'text-text-heading'}`}>{a.systolic_bp}</span>
                  </div>
                  <div className="text-right">
                    <span className="text-[11px] text-text-muted block">{t('blood_sugar')}</span>
                    <span className={`text-sm font-semibold ${rk === 'mid' ? 'text-amber-600' : 'text-text-heading'}`}>{a.blood_sugar}</span>
                  </div>
                </div>

                {/* Link */}
                <Link
                  to="/result"
                  state={{
                    risk_level: a.risk_level,
                    confidence: a.prob_high,
                    recommendation: '',
                    shap_values: [],
                    assessment_id: a.id,
                  }}
                  className="block text-center py-2 text-rose-500 text-sm font-semibold hover:bg-rose-50 rounded-lg transition-colors"
                >
                  {t('view_full_report')} &rarr;
                </Link>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty state */
        <div className="flex flex-col items-center justify-center py-24 text-center border-2 border-dashed border-border rounded-2xl">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 mb-4">assignment</span>
          <h3 className="text-lg font-semibold text-text-heading mb-1">{t('no_assessments')}</h3>
          <p className="text-sm text-text-muted mb-6 max-w-xs">{t('history_empty_hint')}</p>
          <Link
            to="/assess"
            className="bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors"
          >
            {t('new_assessment')}
          </Link>
        </div>
      )}
    </main>
  );
}
