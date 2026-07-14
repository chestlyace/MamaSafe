import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getDashboardSummary } from '../api/client';

function DonutChart({ high, mid, low, total }) {
  const { t } = useTranslation();
  const [hovered, setHovered] = useState(null);

  if (total === 0) return null;

  const highPct = (high / total) * 100;
  const midPct = (mid / total) * 100;
  const lowPct = (low / total) * 100;

  const segments = [
    { key: 'high', pct: highPct, color: '#ef4444', offset: 0 },
    { key: 'mid', pct: midPct, color: '#d97706', offset: -highPct },
    { key: 'low', pct: lowPct, color: '#16a34a', offset: -(highPct + midPct) },
  ];

  const formatTotal = (n) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(n));

  return (
    <div className="flex flex-col">
      <h3 className="text-sm font-semibold text-text-heading mb-1">{t('risk_distribution')}</h3>
      <p className="text-xs text-text-muted mb-5">{t('risk_distribution_desc')}</p>

      <div className="relative flex justify-center">
        <svg className="transform -rotate-90" height="180" width="180" viewBox="0 0 42 42">
          <circle cx="21" cy="21" fill="transparent" r="15.915" stroke="#E8E5EC" strokeWidth="3.5" />
          {segments.map((s) => (
            <circle
              key={s.key}
              cx="21" cy="21" fill="transparent" r="15.915"
              stroke={s.color}
              strokeWidth={hovered === s.key ? 5 : 3.5}
              strokeDasharray={`${s.pct} ${100 - s.pct}`}
              strokeDashoffset={s.offset}
              style={{
                transition: 'stroke-width 0.15s ease',
                cursor: 'pointer',
              }}
              onMouseEnter={() => setHovered(s.key)}
              onMouseLeave={() => setHovered(null)}
            />
          ))}
        </svg>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center">
          <div className="text-2xl font-bold text-text-heading">{formatTotal(total)}</div>
          <div className="text-[10px] font-medium text-text-muted uppercase">{t('total')}</div>
        </div>
      </div>

      {/* Legend */}
      <div className="flex justify-center gap-5 mt-5">
        {[
          { label: t('high_risk'), pct: highPct, color: 'bg-red-500' },
          { label: t('mid_risk'), pct: midPct, color: 'bg-amber-500' },
          { label: t('low_risk'), pct: lowPct, color: 'bg-green-500' },
        ].map((item) => (
          <div key={item.label} className="flex items-center gap-1.5">
            <span className={`w-2 h-2 rounded-full ${item.color}`} />
            <span className="text-xs text-text-muted">{item.label} {item.pct.toFixed(0)}%</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export default function DashboardPage() {
  const { t } = useTranslation();
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDashboardSummary()
      .then((data) => setSummary(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

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

  if (!summary) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="text-center py-24 text-text-muted">{t('error')}</div>
      </main>
    );
  }

  const { total_assessments, high_risk_count, mid_risk_count, low_risk_count } = summary;

  const stats = [
    { label: t('total_assessments'), value: total_assessments.toLocaleString(), icon: 'assessment', color: 'text-rose-500', valueColor: 'text-text-heading', sub: null },
    { label: t('high_risk'), value: high_risk_count, dot: 'bg-red-500', color: 'text-red-500', valueColor: 'text-red-600', sub: t('requires_immediate') },
    { label: t('mid_risk'), value: mid_risk_count, dot: 'bg-amber-500', color: 'text-amber-500', valueColor: 'text-amber-600', sub: t('needs_followup') },
    { label: t('low_risk'), value: low_risk_count, dot: 'bg-green-500', color: 'text-green-500', valueColor: 'text-green-600', sub: t('regular_monitoring') },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('dashboard')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('clinical_summary')}</p>
      </header>

      {/* Stat cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-6">
        {stats.map((s) => (
          <div key={s.label} className="bg-white border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{s.label}</span>
              {s.icon ? (
                <span className={`material-symbols-outlined text-[18px] ${s.color}`}>{s.icon}</span>
              ) : (
                <span className={`w-2 h-2 rounded-full ${s.dot}`} />
              )}
            </div>
            <div className={`text-2xl font-bold ${s.valueColor}`}>{s.value}</div>
            {s.sub && <span className="text-xs text-text-muted mt-0.5 block">{s.sub}</span>}
          </div>
        ))}
      </div>

      {/* Donut + Distribution */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        {/* Donut */}
        <div className="bg-white border border-border rounded-xl p-5">
          <DonutChart high={high_risk_count} mid={mid_risk_count} low={low_risk_count} total={total_assessments} />
        </div>

        {/* Stacked bar */}
        {total_assessments > 0 && (
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-1">{t('weekly_trend')}</h3>
            <p className="text-xs text-text-muted mb-5">{t('weekly_trend_desc')}</p>
            <div className="w-full h-7 rounded-full overflow-hidden flex bg-surface">
              {high_risk_count > 0 && (
                <div
                  className="h-full bg-red-500 flex items-center justify-center"
                  style={{ width: `${(high_risk_count / total_assessments) * 100}%` }}
                >
                  {(high_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{high_risk_count}</span>
                  )}
                </div>
              )}
              {mid_risk_count > 0 && (
                <div
                  className="h-full bg-amber-500 flex items-center justify-center"
                  style={{ width: `${(mid_risk_count / total_assessments) * 100}%` }}
                >
                  {(mid_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{mid_risk_count}</span>
                  )}
                </div>
              )}
              {low_risk_count > 0 && (
                <div
                  className="h-full bg-green-500 flex items-center justify-center"
                  style={{ width: `${(low_risk_count / total_assessments) * 100}%` }}
                >
                  {(low_risk_count / total_assessments) * 100 > 10 && (
                    <span className="text-[10px] font-bold text-white">{low_risk_count}</span>
                  )}
                </div>
              )}
            </div>
            <div className="flex justify-between mt-3">
              {[
                { label: t('high_risk'), pct: high_risk_count, color: 'bg-red-500' },
                { label: t('mid_risk'), pct: mid_risk_count, color: 'bg-amber-500' },
                { label: t('low_risk'), pct: low_risk_count, color: 'bg-green-500' },
              ].map((item) => (
                <div key={item.label} className="flex items-center gap-1.5">
                  <span className={`w-2 h-2 rounded-full ${item.color}`} />
                  <span className="text-xs text-text-muted">{item.label} ({((item.pct / total_assessments) * 100).toFixed(0)}%)</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Critical Alerts */}
      <div className="bg-white border border-border rounded-xl p-5">
        <div className="flex justify-between items-center mb-4">
          <h3 className="text-sm font-semibold text-text-heading">{t('critical_alerts')}</h3>
          <button className="text-rose-500 text-xs font-semibold hover:underline">{t('view_all')}</button>
        </div>
        {high_risk_count > 0 ? (
          <div className="flex items-center gap-4 p-4 bg-red-50 rounded-xl">
            <div className="w-9 h-9 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
              <span className="material-symbols-outlined text-red-600 text-[20px]">warning</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-semibold text-text-heading">{t('high_risk_count_alert', { count: high_risk_count })}</p>
              <p className="text-xs text-text-muted">{t('high_risk_alert_desc')}</p>
            </div>
            <button className="bg-red-600 text-white px-3.5 py-1.5 rounded-lg text-xs font-semibold flex-shrink-0 hover:bg-red-700 transition-colors">
              {t('escalate')}
            </button>
          </div>
        ) : (
          <div className="flex items-center gap-4 p-4 bg-green-50 rounded-xl">
            <div className="w-9 h-9 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
              <span className="material-symbols-outlined text-green-600 text-[20px]">check_circle</span>
            </div>
            <div>
              <p className="text-sm font-semibold text-text-heading">{t('no_critical_alerts')}</p>
              <p className="text-xs text-text-muted">{t('all_patients_safe')}</p>
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
