import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getDashboardSummary } from '../api/client';

function DonutChart({ high, mid, low, total }) {
  const [hovered, setHovered] = useState(null);

  if (total === 0) return null;

  const highPct = (high / total) * 100;
  const midPct = (mid / total) * 100;
  const lowPct = (low / total) * 100;
  const circumference = 2 * Math.PI * 15.915;

  const segments = [
    { key: 'high', pct: highPct, color: '#ef4444', offset: 0 },
    { key: 'mid', pct: midPct, color: '#825100', offset: -highPct },
    { key: 'low', pct: lowPct, color: '#006e2f', offset: -(highPct + midPct) },
  ];

  const formatTotal = (n) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(n));

  return (
    <div className="flex flex-col gap-6 h-full justify-between">
      <div className="flex flex-col gap-1">
        <h3 className="text-lg font-semibold text-gray-900">Risk Distribution</h3>
        <p className="text-sm text-gray-500">
          Breakdown of maternal health risk levels across all patients.
        </p>
      </div>

      <div className="relative flex justify-center py-4">
        <svg
          className="transform -rotate-90"
          height="220"
          width="220"
          viewBox="0 0 42 42"
        >
          <circle cx="21" cy="21" fill="transparent" r="15.915" stroke="#efecf8" strokeWidth="4" />
          {segments.map((s) => (
            <circle
              key={s.key}
              cx="21"
              cy="21"
              fill="transparent"
              r="15.915"
              stroke={s.color}
              strokeWidth={hovered === s.key ? 6 : 4}
              strokeDasharray={`${s.pct} ${100 - s.pct}`}
              strokeDashoffset={s.offset}
              style={{
                transition: 'stroke-width 0.2s ease, filter 0.2s ease',
                filter: hovered === s.key ? 'drop-shadow(0 0 4px rgba(0,0,0,0.15))' : 'none',
                cursor: 'pointer',
              }}
              onMouseEnter={() => setHovered(s.key)}
              onMouseLeave={() => setHovered(null)}
            />
          ))}
        </svg>
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center">
          <div className="text-3xl font-bold text-gray-900">{formatTotal(total)}</div>
          <div className="text-[10px] font-semibold text-gray-500 uppercase">Total</div>
        </div>
      </div>

      {/* Legend */}
      <div className="flex flex-col gap-2">
        {[
          { label: 'High Risk', pct: highPct, color: 'bg-red-500', count: high },
          { label: 'Mid Risk', pct: midPct, color: 'bg-amber-700', count: mid },
          { label: 'Low Risk', pct: lowPct, color: 'bg-green-700', count: low },
        ].map((item) => (
          <div key={item.label} className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <span className={`w-3 h-3 rounded-sm ${item.color}`} />
              <span className="text-gray-800">{item.label}</span>
            </div>
            <span className="font-semibold">{item.pct.toFixed(0)}%</span>
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

  if (!summary) {
    return (
      <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-12">
        <div className="text-center py-24 text-gray-500">Failed to load dashboard.</div>
      </main>
    );
  }

  const { total_assessments, high_risk_count, mid_risk_count, low_risk_count } = summary;

  const statCards = [
    {
      label: 'Total Assessments',
      value: total_assessments.toLocaleString(),
      icon: 'assessment',
      iconColor: 'text-indigo-600',
      valueColor: 'text-gray-900',
      subtitle: null,
    },
    {
      label: 'High Risk',
      value: high_risk_count,
      dot: 'bg-red-500 ring-red-100',
      valueColor: 'text-red-600',
      subtitle: 'Requires immediate intervention',
    },
    {
      label: 'Mid Risk',
      value: mid_risk_count,
      dot: 'bg-amber-600 ring-amber-100',
      valueColor: 'text-amber-700',
      subtitle: 'Needs clinical follow-up',
    },
    {
      label: 'Low Risk',
      value: low_risk_count,
      dot: 'bg-green-600 ring-green-100',
      valueColor: 'text-green-700',
      subtitle: 'Regular monitoring recommended',
    },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-8 mb-20 md:mb-8">
      <div className="flex flex-col gap-6">
        {/* Header */}
        <header className="flex flex-col gap-1">
          <h1 className="text-3xl font-bold text-gray-900">{t('dashboard')}</h1>
          <p className="text-base text-gray-500">
            Clinical summary and population risk oversight.
          </p>
        </header>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Stat Cards 2x2 */}
          <div className="lg:col-span-7 grid grid-cols-2 gap-4">
            {statCards.map((card) => (
              <div
                key={card.label}
                className="bg-white p-6 rounded-xl shadow-md border border-gray-100 flex flex-col gap-1"
              >
                <div className="flex justify-between items-start">
                  <span className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                    {card.label}
                  </span>
                  {card.icon ? (
                    <span className={`material-symbols-outlined text-xl ${card.iconColor}`}>
                      {card.icon}
                    </span>
                  ) : (
                    <span
                      className={`w-3 h-3 rounded-full ring-4 ${card.dot}`}
                    />
                  )}
                </div>
                <div className={`text-3xl font-bold ${card.valueColor}`}>{card.value}</div>
                {card.subtitle && (
                  <span className="text-sm text-gray-500">{card.subtitle}</span>
                )}
              </div>
            ))}
          </div>

          {/* Donut Chart */}
          <div className="lg:col-span-5 bg-white p-6 rounded-xl shadow-md border border-gray-100">
            <DonutChart
              high={high_risk_count}
              mid={mid_risk_count}
              low={low_risk_count}
              total={total_assessments}
            />
          </div>
        </div>

        {/* Critical Alerts */}
        <div className="bg-white p-6 rounded-xl shadow-md border border-gray-100">
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold text-gray-900">Critical Alerts</h3>
            <button className="text-indigo-600 text-xs font-semibold hover:underline">
              View All
            </button>
          </div>
          <div className="flex flex-col gap-3">
            {high_risk_count > 0 ? (
              <div className="flex items-center gap-4 p-4 bg-red-50 rounded-xl border-l-4 border-red-500">
                <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                  <span className="material-symbols-outlined text-red-600">warning</span>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-semibold text-gray-900">
                    {high_risk_count} patient{high_risk_count !== 1 ? 's' : ''} flagged as high risk
                  </div>
                  <div className="text-sm text-gray-500">
                    Requires immediate clinical review and intervention
                  </div>
                </div>
                <button className="bg-red-600 text-white px-4 py-1 rounded-lg text-xs font-semibold flex-shrink-0 hover:bg-red-700 transition-colors">
                  Escalate
                </button>
              </div>
            ) : (
              <div className="flex items-center gap-4 p-4 bg-green-50 rounded-xl border-l-4 border-green-500">
                <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center flex-shrink-0">
                  <span className="material-symbols-outlined text-green-600">check_circle</span>
                </div>
                <div className="flex-1">
                  <div className="text-sm font-semibold text-gray-900">No critical alerts</div>
                  <div className="text-sm text-gray-500">All patients are within safe thresholds</div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
