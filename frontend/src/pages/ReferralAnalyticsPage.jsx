import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getReferralAnalytics } from '../api/client';

export default function ReferralAnalyticsPage() {
  const { t } = useTranslation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getReferralAnalytics()
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

  const summaryCards = [
    { label: t('total_referrals'), value: data.total_referrals, color: 'text-blue-600' },
    { label: t('sent'), value: data.sent, color: 'text-amber-600' },
    { label: t('received'), value: data.received, color: 'text-purple-600' },
    { label: t('patient_arrived'), value: data.patient_arrived, color: 'text-green-600' },
    { label: t('completion_rate'), value: `${data.completion_rate}%`, color: 'text-emerald-600' },
    { label: t('high_risk_referrals'), value: data.high_risk_referrals, color: 'text-red-600' },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('referral_analytics')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('referral_analytics_desc')}</p>
      </header>

      <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-3 mb-6">
        {summaryCards.map((s) => (
          <div key={s.label} className="bg-white border border-border rounded-xl p-4">
            <div className="text-[11px] font-semibold text-text-muted uppercase tracking-wider mb-1">{s.label}</div>
            <div className={`text-2xl font-bold ${s.color}`}>{s.value}</div>
          </div>
        ))}
      </div>

      {data.avg_hours_to_receipt != null && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-1">{t('avg_time_to_receipt')}</h3>
            <div className="text-2xl font-bold text-text-heading">{data.avg_hours_to_receipt} {t('hours')}</div>
          </div>
          <div className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-sm font-semibold text-text-heading mb-1">{t('avg_time_to_arrival')}</h3>
            <div className="text-2xl font-bold text-text-heading">{data.avg_hours_to_arrival} {t('hours')}</div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('by_facility')}</h3>
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
                <th className="pb-2">{t('facility')}</th>
                <th className="pb-2">{t('total')}</th>
                <th className="pb-2">{t('arrived')}</th>
                <th className="pb-2">{t('rate')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {(data.by_facility || []).map((f) => (
                <tr key={f.facility_name}>
                  <td className="py-2 font-medium text-text-heading">{f.facility_name}</td>
                  <td className="py-2 text-text-muted">{f.total}</td>
                  <td className="py-2 text-text-muted">{f.arrived}</td>
                  <td className="py-2 font-semibold">{f.completion_rate}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('by_chw')}</h3>
          <table className="w-full text-sm">
            <thead>
              <tr className="text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
                <th className="pb-2">{t('chw')}</th>
                <th className="pb-2">{t('total')}</th>
                <th className="pb-2">{t('arrived')}</th>
                <th className="pb-2">{t('rate')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border">
              {(data.by_chw || []).map((c) => (
                <tr key={c.chw_name}>
                  <td className="py-2 font-medium text-text-heading">{c.chw_name}</td>
                  <td className="py-2 text-text-muted">{c.total}</td>
                  <td className="py-2 text-text-muted">{c.arrived}</td>
                  <td className="py-2 font-semibold">{c.completion_rate}%</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </main>
  );
}
