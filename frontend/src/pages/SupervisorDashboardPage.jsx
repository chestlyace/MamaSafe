import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { getAdminDashboard } from '../api/client';

export default function SupervisorDashboardPage() {
  const { t } = useTranslation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAdminDashboard()
      .then(setData)
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

  if (!data) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="text-center py-24 text-text-muted">{t('error')}</div>
      </main>
    );
  }

  const overviewCards = [
    { label: t('total_chws'), value: data.total_chws, icon: 'group', color: 'text-blue-500' },
    { label: t('active_today'), value: data.active_chws_today, icon: 'check_circle', color: 'text-green-500' },
    { label: t('total_patients'), value: data.total_patients, icon: 'people', color: 'text-purple-500' },
    { label: t('total_assessments'), value: data.total_assessments, icon: 'assessment', color: 'text-amber-500' },
    { label: t('total_referrals'), value: data.total_referrals, icon: 'local_hospital', color: 'text-red-500' },
    { label: t('referral_completion'), value: `${data.referral_completion_rate}%`, icon: 'task_alt', color: 'text-emerald-500' },
  ];

  const riskCards = [
    { label: t('high_risk'), value: data.high_risk_active, color: 'text-red-600', bg: 'bg-red-50', dot: 'bg-red-500' },
    { label: t('mid_risk'), value: data.mid_risk_active, color: 'text-amber-600', bg: 'bg-amber-50', dot: 'bg-amber-500' },
    { label: t('low_risk'), value: data.low_risk_active, color: 'text-green-600', bg: 'bg-green-50', dot: 'bg-green-500' },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">
          {t('supervisor_dashboard')}
        </h1>
        <p className="text-sm text-text-muted mt-1">
          {data.district} — {t('last_7_days')}
        </p>
      </header>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3 mb-6">
        {overviewCards.map((s) => (
          <div key={s.label} className="bg-white border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{s.label}</span>
              <span className={`material-symbols-outlined text-[18px] ${s.color}`}>{s.icon}</span>
            </div>
            <div className="text-2xl font-bold text-text-heading">{s.value}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-3 mb-8">
        {riskCards.map((s) => (
          <div key={s.label} className={`${s.bg} border border-border rounded-xl p-4`}>
            <div className="flex items-center gap-2 mb-1">
              <span className={`w-2 h-2 rounded-full ${s.dot}`} />
              <span className="text-xs font-semibold text-text-muted uppercase">{s.label}</span>
            </div>
            <div className={`text-2xl font-bold ${s.color}`}>{s.value}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-1">{t('this_week')}</h3>
          <p className="text-xs text-text-muted mb-4">{t('weekly_activity')}</p>
          <div className="space-y-3">
            {[
              { label: t('assessments'), value: data.this_week?.assessments || 0, icon: 'assessment' },
              { label: t('referrals'), value: data.this_week?.referrals || 0, icon: 'local_hospital' },
              { label: t('deliveries'), value: data.this_week?.deliveries || 0, icon: 'child_care' },
              { label: t('new_patients'), value: data.this_week?.new_patients || 0, icon: 'person_add' },
            ].map((item) => (
              <div key={item.label} className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span className="material-symbols-outlined text-[16px] text-text-muted">{item.icon}</span>
                  <span className="text-sm text-text-muted">{item.label}</span>
                </div>
                <span className="text-sm font-semibold text-text-heading">{item.value}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('quick_links')}</h3>
          <div className="space-y-2">
            <Link to="/supervisor/chws" className="flex items-center gap-3 p-3 rounded-xl hover:bg-surface transition-colors">
              <span className="material-symbols-outlined text-[20px] text-blue-500">group</span>
              <span className="text-sm font-medium text-text-heading">{t('manage_chws')}</span>
            </Link>
            <Link to="/supervisor/high-risk" className="flex items-center gap-3 p-3 rounded-xl hover:bg-surface transition-colors">
              <span className="material-symbols-outlined text-[20px] text-red-500">warning</span>
              <span className="text-sm font-medium text-text-heading">{t('high_risk_patients')}</span>
            </Link>
            <Link to="/supervisor/referrals" className="flex items-center gap-3 p-3 rounded-xl hover:bg-surface transition-colors">
              <span className="material-symbols-outlined text-[20px] text-amber-500">analytics</span>
              <span className="text-sm font-medium text-text-heading">{t('referral_analytics')}</span>
            </Link>
            <Link to="/supervisor/report" className="flex items-center gap-3 p-3 rounded-xl hover:bg-surface transition-colors">
              <span className="material-symbols-outlined text-[20px] text-purple-500">summarize</span>
              <span className="text-sm font-medium text-text-heading">{t('monthly_report')}</span>
            </Link>
          </div>
        </div>
      </div>

      <div className="bg-white border border-border rounded-xl p-5">
        <h3 className="text-sm font-semibold text-text-heading mb-3">{t('quality_indicators')}</h3>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <div className="text-xs text-text-muted mb-1">{t('pnc1_completion')}</div>
            <div className="text-lg font-bold text-text-heading">{data.pnc1_completion_rate}%</div>
          </div>
          <div>
            <div className="text-xs text-text-muted mb-1">{t('phq2_positive_this_month')}</div>
            <div className="text-lg font-bold text-text-heading">{data.phq2_positive_this_month}</div>
          </div>
          <div>
            <div className="text-xs text-text-muted mb-1">{t('active_growth_alerts')}</div>
            <div className="text-lg font-bold text-text-heading">{data.growth_alerts_active}</div>
          </div>
          <div>
            <div className="text-xs text-text-muted mb-1">{t('total_deliveries')}</div>
            <div className="text-lg font-bold text-text-heading">{data.total_deliveries}</div>
          </div>
        </div>
      </div>
    </main>
  );
}
