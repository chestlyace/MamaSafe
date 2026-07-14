import { useLocation, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const RISK_CONFIG = {
  'high risk': {
    label: 'HIGH RISK',
    heroBg: 'bg-red-50',
    heroBorder: 'border-red-200',
    accent: 'text-red-600',
    accentBg: 'bg-red-100',
    dot: 'bg-red-500',
    barColor: 'bg-red-500',
    pillBg: 'bg-white/60 border-red-200',
    title: 'Critical Assessment Result',
    desc: 'The diagnostic engine has identified multiple elevated risk factors requiring immediate clinical intervention.',
    recTitle: 'Immediate Referral Required',
    recIcon: 'emergency_home',
    borderColor: 'border-red-400',
  },
  'mid risk': {
    label: 'MODERATE RISK',
    heroBg: 'bg-amber-50',
    heroBorder: 'border-amber-200',
    accent: 'text-amber-700',
    accentBg: 'bg-amber-100',
    dot: 'bg-amber-600',
    barColor: 'bg-amber-600',
    pillBg: 'bg-white/60 border-amber-200',
    title: 'Moderate Risk Assessment',
    desc: 'Some risk factors have been identified that may require clinical attention and monitoring.',
    recTitle: 'Clinical Follow-up Recommended',
    recIcon: 'monitor_heart',
    borderColor: 'border-amber-400',
  },
  'low risk': {
    label: 'LOW RISK',
    heroBg: 'bg-green-50',
    heroBorder: 'border-green-200',
    accent: 'text-green-700',
    accentBg: 'bg-green-100',
    dot: 'bg-green-600',
    barColor: 'bg-green-600',
    pillBg: 'bg-white/60 border-green-200',
    title: 'Low Risk Assessment',
    desc: 'No significant risk factors detected. Continue routine monitoring and prenatal care.',
    recTitle: 'Routine Monitoring',
    recIcon: 'check_circle',
    borderColor: 'border-green-400',
  },
};

export default function ResultPage() {
  const { t } = useTranslation();
  const { state } = useLocation();

  if (!state) {
    return (
      <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-12">
        <div className="text-center py-24">
          <div className="w-20 h-20 bg-gray-100 flex items-center justify-center rounded-full mx-auto mb-6">
            <span className="material-symbols-outlined text-4xl text-gray-400">analytics</span>
          </div>
          <h2 className="text-lg font-semibold text-gray-900 mb-2">No result data</h2>
          <p className="text-gray-500 mb-6">Complete an assessment to see results here.</p>
          <Link
            to="/assess"
            className="inline-flex items-center gap-2 bg-indigo-600 text-white px-6 py-3 rounded-xl font-semibold text-sm hover:bg-indigo-700 transition-all"
          >
            <span className="material-symbols-outlined text-xl">add_circle</span>
            {t('new_assessment')}
          </Link>
        </div>
      </main>
    );
  }

  const riskKey = state.risk_level === 'high risk' ? 'high' : state.risk_level === 'mid risk' ? 'mid' : 'low';
  const cfg = RISK_CONFIG[state.risk_level] || RISK_CONFIG['low risk'];
  const confidence = ((state.confidence || 0) * 100).toFixed(0);

  const shapValues = (state.shap_values || []).map((v) => ({
    ...v,
    pct: Math.abs(v.shap_value) * 100,
  }));
  const maxPct = Math.max(...shapValues.map((v) => v.pct), 1);

  const probHigh = ((state.prob_high || 0) * 100).toFixed(0);
  const probMid = ((state.prob_mid || 0) * 100).toFixed(0);
  const probLow = ((state.prob_low || 0) * 100).toFixed(0);

  return (
    <main className="max-w-[1200px] mx-auto px-4 md:px-12 py-6 mb-20 md:mb-8">
      {/* Risk Hero Banner */}
      <div className={`mb-6 rounded-xl overflow-hidden ${cfg.heroBg} border ${cfg.heroBorder}`}>
        <div className="p-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-6">
          <div className="space-y-3">
            <div className={`flex items-center gap-2 px-3 py-1 rounded-full border w-fit ${cfg.pillBg} backdrop-blur-md`}>
              <span className={`w-2 h-2 rounded-full ${cfg.dot}`} />
              <span className={`font-bold text-xs ${cfg.accent}`}>{cfg.label}</span>
            </div>
            <h1 className="text-3xl font-bold text-gray-900">{cfg.title}</h1>
            <p className="text-gray-600 max-w-xl">{cfg.desc}</p>
          </div>
          <div className="flex flex-col items-center justify-center bg-white rounded-2xl p-6 shadow-lg min-w-[160px]">
            <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Confidence</span>
            <span className={`text-5xl font-bold leading-tight ${cfg.accent}`}>{confidence}%</span>
          </div>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* Left: Recommendation + SHAP */}
        <div className="lg:col-span-7 space-y-6">
          {/* Recommendation Card */}
          <section className={`bg-white border-2 p-6 rounded-xl shadow-sm ${cfg.borderColor}`}>
            <div className="flex items-start gap-4 mb-4">
              <div className={`${cfg.accentBg} ${cfg.accent} p-2 rounded-lg`}>
                <span className="material-symbols-outlined" style={{ fontVariationSettings: "'FILL' 1" }}>
                  {cfg.recIcon}
                </span>
              </div>
              <div>
                <h2 className={`text-lg font-semibold ${cfg.accent}`}>{cfg.recTitle}</h2>
                <p className="text-gray-500 mt-1">Primary action required within the next 2 hours.</p>
              </div>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg border border-gray-200">
              <p className="text-gray-800 font-medium leading-relaxed">
                {state.recommendation || 'No specific recommendation available. Please review the assessment results and consult clinical guidelines.'}
              </p>
            </div>
          </section>

          {/* SHAP Feature Contributions */}
          {shapValues.length > 0 && (
            <section className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
              <h3 className="text-lg font-semibold mb-1">Feature Contributions</h3>
              <p className="text-sm text-gray-500 mb-6">
                Analysis of how individual metrics influenced this risk score (SHAP values).
              </p>
              <div className="space-y-4">
                {shapValues.map((v, i) => {
                  const isPositive = v.shap_value >= 0;
                  const widthPct = (v.pct / maxPct) * 100;
                  return (
                    <div key={i} className="space-y-1">
                      <div className="flex justify-between text-sm mb-1">
                        <span className={`font-semibold ${isPositive ? 'text-gray-900' : 'text-gray-500'}`}>
                          {v.feature} {v.raw_value !== undefined && `(${v.raw_value})`}
                        </span>
                        <span className={`font-bold ${isPositive ? 'text-red-600' : 'text-green-600'}`}>
                          {isPositive ? '+' : ''}{v.pct.toFixed(1)}%
                        </span>
                      </div>
                      <div className="h-2 w-full bg-gray-100 rounded-full overflow-hidden flex">
                        {isPositive ? (
                          <div
                            className="h-full bg-red-500 rounded-full transition-all duration-700"
                            style={{ width: `${widthPct}%`, marginLeft: 'auto' }}
                          />
                        ) : (
                          <div
                            className="h-full bg-green-600 rounded-full transition-all duration-700"
                            style={{ width: `${widthPct}%` }}
                          />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          )}
        </div>

        {/* Right: Probability + Actions */}
        <div className="lg:col-span-5 space-y-6">
          {/* Probability Distribution */}
          <section className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
            <h3 className="text-lg font-semibold mb-6">Probability Distribution</h3>
            <div className="space-y-6">
              {/* High */}
              <div>
                <div className="flex justify-between items-end mb-2">
                  <span className="text-sm font-bold text-red-600">High Risk</span>
                  <span className="text-lg font-bold text-gray-900">{probHigh}%</span>
                </div>
                <div className="h-4 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-red-500 rounded-full transition-all duration-1000 ease-out"
                    style={{ width: `${probHigh}%` }}
                  />
                </div>
              </div>
              {/* Mid */}
              <div>
                <div className="flex justify-between items-end mb-2">
                  <span className="text-sm font-bold text-amber-700">Moderate Risk</span>
                  <span className="text-lg font-bold text-gray-900">{probMid}%</span>
                </div>
                <div className="h-4 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-amber-600 rounded-full transition-all duration-1000 ease-out"
                    style={{ width: `${probMid}%` }}
                  />
                </div>
              </div>
              {/* Low */}
              <div>
                <div className="flex justify-between items-end mb-2">
                  <span className="text-sm font-bold text-green-700">Low Risk</span>
                  <span className="text-lg font-bold text-gray-900">{probLow}%</span>
                </div>
                <div className="h-4 w-full bg-gray-100 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-green-600 rounded-full transition-all duration-1000 ease-out"
                    style={{ width: `${probLow}%` }}
                  />
                </div>
              </div>
            </div>
            <div className="mt-6 pt-6 border-t border-gray-200">
              <div className="flex items-center gap-2 text-sm text-gray-500">
                <span className="material-symbols-outlined text-gray-400 text-base">info</span>
                <span>Calculated using Ensemble Model v4.2 based on current global maternal health benchmarks.</span>
              </div>
            </div>
          </section>

          {/* Action Buttons */}
          <div className="flex flex-col gap-3">
            <Link
              to="/history"
              className="w-full py-4 bg-indigo-600 text-white rounded-xl font-semibold shadow-lg hover:bg-indigo-700 transition-all active:scale-[0.98] flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-xl">history</span>
              View History
            </Link>
            <Link
              to="/assess"
              className="w-full py-4 border-2 border-indigo-600 text-indigo-600 bg-white rounded-xl font-semibold hover:bg-indigo-50 transition-all active:scale-[0.98] flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-xl">add_circle</span>
              {t('new_assessment')}
            </Link>
          </div>
        </div>
      </div>
    </main>
  );
}
