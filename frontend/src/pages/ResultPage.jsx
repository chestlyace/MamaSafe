import { useLocation, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import ReferralModal from '../components/ReferralModal';

const RISK_CONFIG = {
  'high risk': {
    heroBg: 'bg-red-50', heroBorder: 'border-red-200',
    accent: 'text-red-600', accentBg: 'bg-red-100',
    dot: 'bg-red-500', barColor: 'bg-red-500',
    titleKey: 'critical_result_title', descKey: 'critical_result_desc',
    recTitleKey: 'immediate_referral', recIcon: 'emergency_home',
    i18nLabel: 'high_risk',
  },
  'mid risk': {
    heroBg: 'bg-amber-50', heroBorder: 'border-amber-200',
    accent: 'text-amber-700', accentBg: 'bg-amber-100',
    dot: 'bg-amber-600', barColor: 'bg-amber-600',
    titleKey: 'moderate_result_title', descKey: 'moderate_result_desc',
    recTitleKey: 'clinical_followup', recIcon: 'monitor_heart',
    i18nLabel: 'moderate_risk',
  },
  'low risk': {
    heroBg: 'bg-green-50', heroBorder: 'border-green-200',
    accent: 'text-green-700', accentBg: 'bg-green-100',
    dot: 'bg-green-600', barColor: 'bg-green-600',
    titleKey: 'low_result_title', descKey: 'low_result_desc',
    recTitleKey: 'routine_monitoring', recIcon: 'check_circle',
    i18nLabel: 'low_risk',
  },
};

export default function ResultPage() {
  const { t } = useTranslation();
  const { state } = useLocation();
  const [showReferral, setShowReferral] = useState(false);

  if (!state) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="text-center py-24">
          <span className="material-symbols-outlined text-[48px] text-text-muted/40 block mb-4">analytics</span>
          <h2 className="text-lg font-semibold text-text-heading mb-1">{t('no_result_data')}</h2>
          <p className="text-sm text-text-muted mb-6">{t('no_result_hint')}</p>
          <Link to="/assess" className="inline-flex items-center gap-2 bg-rose-500 text-white px-6 py-2.5 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors">
            <span className="material-symbols-outlined text-[18px]">add_circle</span>
            {t('new_assessment')}
          </Link>
        </div>
      </main>
    );
  }

  const cfg = RISK_CONFIG[state.risk_level] || RISK_CONFIG['low risk'];
  const confidence = ((state.confidence || 0) * 100).toFixed(0);

  const shapValues = (state.shap_values || []).map((v) => ({ ...v, pct: Math.abs(v.shap_value) * 100 }));
  const maxPct = Math.max(...shapValues.map((v) => v.pct), 1);

  const probHigh = ((state.prob_high || 0) * 100).toFixed(0);
  const probMid = ((state.prob_mid || 0) * 100).toFixed(0);
  const probLow = ((state.prob_low || 0) * 100).toFixed(0);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-6 pb-24 md:pb-8">
      {/* Risk Hero */}
      <div className={`rounded-2xl ${cfg.heroBg} border ${cfg.heroBorder} p-6 sm:p-8 mb-6`}>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-5">
          <div>
            <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${cfg.accentBg} ${cfg.accent} mb-3`}>
              <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
              {t(cfg.i18nLabel)}
            </span>
            <h1 className="text-xl sm:text-2xl font-bold text-text-heading">{t(cfg.titleKey)}</h1>
            <p className="text-sm text-text-body mt-1 max-w-lg">{t(cfg.descKey)}</p>
          </div>
          <div className="bg-white rounded-xl px-5 py-4 text-center shadow-sm border border-border flex-shrink-0">
            <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider block">{t('confidence')}</span>
            <span className={`text-3xl font-bold ${cfg.accent}`}>{confidence}%</span>
          </div>
        </div>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        {/* Left */}
        <div className="lg:col-span-7 space-y-5">
          {/* Recommendation */}
          <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
            <div className="flex items-start gap-3 mb-4">
              <div className={`${cfg.accentBg} ${cfg.accent} p-2 rounded-lg flex-shrink-0`}>
                <span className="material-symbols-outlined text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>{cfg.recIcon}</span>
              </div>
              <div>
                <h2 className={`text-base font-semibold ${cfg.accent}`}>{t(cfg.recTitleKey)}</h2>
                <p className="text-xs text-text-muted mt-0.5">{t('action_2hrs')}</p>
              </div>
            </div>
            <div className="bg-surface rounded-xl p-4 border border-border">
              <p className="text-sm text-text-body leading-relaxed">{state.recommendation || t('no_recommendation')}</p>
            </div>
          </section>

          {/* SHAP */}
          {shapValues.length > 0 && (
            <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
              <h3 className="text-base font-semibold text-text-heading mb-0.5">{t('feature_contributions')}</h3>
              <p className="text-xs text-text-muted mb-5">{t('shap_explanation')}</p>
              <div className="space-y-3.5">
                {shapValues.map((v, i) => {
                  const isPos = v.shap_value >= 0;
                  const widthPct = (v.pct / maxPct) * 100;
                  return (
                    <div key={i}>
                      <div className="flex justify-between text-sm mb-1">
                        <span className={`font-medium ${isPos ? 'text-text-heading' : 'text-text-muted'}`}>
                          {v.feature} {v.raw_value !== undefined && `(${v.raw_value})`}
                        </span>
                        <span className={`font-semibold text-xs ${isPos ? 'text-red-600' : 'text-green-600'}`}>
                          {isPos ? '+' : ''}{v.pct.toFixed(1)}%
                        </span>
                      </div>
                      <div className="h-1.5 w-full bg-surface rounded-full overflow-hidden flex">
                        {isPos ? (
                          <div className="h-full bg-red-500 rounded-full" style={{ width: `${widthPct}%`, marginLeft: 'auto' }} />
                        ) : (
                          <div className="h-full bg-green-500 rounded-full" style={{ width: `${widthPct}%` }} />
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          )}
        </div>

        {/* Right */}
        <div className="lg:col-span-5 space-y-5">
          {/* Probability */}
          <section className="bg-white border border-border rounded-2xl p-5 sm:p-6">
            <h3 className="text-base font-semibold text-text-heading mb-5">{t('prob_distribution')}</h3>
            <div className="space-y-5">
              {[
                { label: t('high_risk'), val: probHigh, color: 'bg-red-500', text: 'text-red-600' },
                { label: t('mid_risk'), val: probMid, color: 'bg-amber-500', text: 'text-amber-600' },
                { label: t('low_risk'), val: probLow, color: 'bg-green-500', text: 'text-green-600' },
              ].map((p) => (
                <div key={p.label}>
                  <div className="flex justify-between items-end mb-1.5">
                    <span className={`text-xs font-semibold ${p.text}`}>{p.label}</span>
                    <span className="text-lg font-bold text-text-heading">{p.val}%</span>
                  </div>
                  <div className="h-2.5 w-full bg-surface rounded-full overflow-hidden">
                    <div className={`h-full ${p.color} rounded-full transition-all duration-700`} style={{ width: `${p.val}%` }} />
                  </div>
                </div>
              ))}
            </div>
            <div className="mt-5 pt-4 border-t border-border">
              <p className="text-xs text-text-muted leading-relaxed">{t('model_info')}</p>
            </div>
          </section>

          {/* Actions */}
          <div className="flex flex-col gap-2.5">
            {state.patient_id && (
              <Link
                to={`/patients/${state.patient_id}`}
                className="py-3 bg-rose-500 text-white rounded-xl text-sm font-semibold text-center hover:bg-rose-600 transition-colors flex items-center justify-center gap-2"
              >
                <span className="material-symbols-outlined text-[18px]">person</span>
                {t('view_patient_card')}
              </Link>
            )}
            <Link
              to="/history"
              className="py-3 bg-rose-500 text-white rounded-xl text-sm font-semibold text-center hover:bg-rose-600 transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">history</span>
              {t('view_history')}
            </Link>
            <Link
              to="/assess"
              className="py-3 border border-rose-500 text-rose-500 bg-white rounded-xl text-sm font-semibold text-center hover:bg-rose-50 transition-colors flex items-center justify-center gap-2"
            >
              <span className="material-symbols-outlined text-[18px]">add_circle</span>
              {t('new_assessment')}
            </Link>
          </div>
      </div>
    </div>

    {state?.risk_level === 'High Risk' && (
      <div className="mt-6">
        <button
          onClick={() => setShowReferral(true)}
          className="w-full py-4 bg-red-600 text-white rounded-2xl font-bold text-base hover:bg-red-700 transition-colors flex items-center justify-center gap-2 shadow-lg"
        >
          <span className="material-symbols-outlined">emergency</span>
          {t('emergency_referral')}
        </button>
      </div>
    )}

    {showReferral && (
      <ReferralModal
        patientId={state.patient_id}
        patientName={state.patient_name}
        assessmentId={state.assessment_id}
        onClose={() => setShowReferral(false)}
      />
    )}
  </main>
  );
}
