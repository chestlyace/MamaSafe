import { useEffect, useState, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { getAssessments } from '../api/client';

const RISK_STYLES = {
  high: {
    pill: 'bg-red-50 border border-red-300',
    dot: 'bg-red-500',
    text: 'text-red-600 font-semibold',
    label: 'High Risk',
  },
  mid: {
    pill: 'bg-amber-50 border border-amber-300',
    dot: 'bg-amber-500',
    text: 'text-amber-600 font-semibold',
    label: 'Moderate Risk',
  },
  low: {
    pill: 'bg-green-50 border border-green-300',
    dot: 'bg-green-500',
    text: 'text-green-600 font-semibold',
    label: 'Low Risk',
  },
};

function riskKey(level) {
  if (level === 'high risk') return 'high';
  if (level === 'mid risk') return 'mid';
  return 'low';
}

function formatDate(iso) {
  const d = new Date(iso);
  const date = d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  const time = d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  return `${date} \u2022 ${time}`;
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
    return assessments.filter(
      (a) => a.patient_ref && a.patient_ref.toLowerCase().includes(term)
    );
  }, [assessments, search]);

  if (loading) {
    return (
      <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-indigo-500 mr-3">
            progress_activity
          </span>
          <span className="text-gray-400">{t('loading')}</span>
        </div>
      </main>
    );
  }

  return (
    <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-8 mb-20 md:mb-8">
      {/* Header + Search */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{t('assessment_history')}</h1>
          <p className="text-base text-gray-500 mt-1">
            Manage and review past maternal health screenings.
          </p>
        </div>
        <div className="relative flex-shrink-0">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">
            search
          </span>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search patient ID..."
            className="pl-10 pr-4 py-2.5 border border-gray-200 rounded-xl bg-white w-full md:w-64 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all"
          />
        </div>
      </div>

      {/* Cards Grid */}
      {filtered.length > 0 ? (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {filtered.map((a) => {
            const rk = riskKey(a.risk_level);
            const style = RISK_STYLES[rk];
            return (
              <div
                key={a.id}
                className="assessment-card bg-white border border-gray-200 rounded-2xl p-5 shadow-[0_4px_12px_rgba(0,0,0,0.05)] flex flex-col gap-4"
              >
                {/* Top row: Patient ID + Date + Badge */}
                <div className="flex justify-between items-start">
                  <div className="flex flex-col">
                    <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                      Patient ID
                    </span>
                    <span className="text-lg font-semibold text-gray-900">
                      {a.patient_ref || '\u2014'}
                    </span>
                  </div>
                  <div className="text-right flex flex-col items-end gap-2">
                    <span className="text-sm text-gray-500">{formatDate(a.created_at)}</span>
                    <div className={`flex items-center gap-2 px-3 py-1 rounded-full ${style.pill}`}>
                      <div className={`w-2 h-2 rounded-full ${style.dot}`} />
                      <span className={`text-xs ${style.text}`}>{style.label}</span>
                    </div>
                  </div>
                </div>

                {/* Stats row */}
                <div className="grid grid-cols-3 gap-2 bg-gray-50 rounded-xl p-4">
                  <div className="flex flex-col">
                    <span className="text-sm text-gray-500">Age</span>
                    <span className="text-sm font-semibold text-gray-900">{a.age} Years</span>
                  </div>
                  <div className="flex flex-col border-x border-gray-200 px-2">
                    <span className="text-sm text-gray-500">Systolic BP</span>
                    <span className={`text-sm font-semibold ${rk === 'high' ? 'text-red-600' : 'text-gray-900'}`}>
                      {a.systolic_bp} mmHg
                    </span>
                  </div>
                  <div className="flex flex-col items-end">
                    <span className="text-sm text-gray-500">Blood Sugar</span>
                    <span className={`text-sm font-semibold ${rk === 'mid' ? 'text-amber-600' : 'text-gray-900'}`}>
                      {a.blood_sugar} mmol/L
                    </span>
                  </div>
                </div>

                {/* View button */}
                <Link
                  to="/result"
                  state={{
                    risk_level: a.risk_level,
                    confidence: a.prob_high,
                    recommendation: '',
                    shap_values: [],
                    assessment_id: a.id,
                  }}
                  className="w-full text-center py-2 text-indigo-600 font-semibold text-sm hover:bg-indigo-50 rounded-lg transition-colors"
                >
                  View Full Report
                </Link>
              </div>
            );
          })}
        </div>
      ) : (
        /* Empty State */
        <div className="flex flex-col items-center justify-center py-24 text-center bg-white border-2 border-dashed border-gray-200 rounded-2xl">
          <div className="w-20 h-20 bg-gray-100 flex items-center justify-center rounded-full mb-6">
            <span className="material-symbols-outlined text-4xl text-gray-400">assignment</span>
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">{t('no_assessments')}</h3>
          <p className="text-base text-gray-500 mb-6 max-w-xs mx-auto">
            History will populate once you complete patient health assessments.
          </p>
          <Link
            to="/assess"
            className="bg-indigo-600 text-white px-8 py-3 rounded-xl font-semibold text-sm hover:bg-indigo-700 shadow-lg transition-all"
          >
            {t('new_assessment')}
          </Link>
        </div>
      )}
    </main>
  );
}
