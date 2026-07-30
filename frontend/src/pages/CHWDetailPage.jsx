import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import { getChwStats } from '../api/client';

export default function CHWDetailPage() {
  const { t } = useTranslation();
  const { chwId } = useParams();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getChwStats(chwId)
      .then(setData)
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [chwId]);

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

  const rd = data.risk_distribution || {};

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to="/supervisor/chws" className="text-xs text-rose-500 font-semibold flex items-center gap-1 mb-4 hover:text-rose-600">
        <span className="material-symbols-outlined text-[14px]">arrow_back</span>
        {t('back_to_chws')}
      </Link>

      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{data.full_name || data.username}</h1>
        <p className="text-sm text-text-muted mt-1">{data.facility || t('no_facility')} — {data.username}</p>
      </header>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-3 mb-6">
        {[
          { label: t('patients'), value: data.patient_count, icon: 'people' },
          { label: t('assessments'), value: data.assessment_count, icon: 'assessment' },
          { label: t('referrals'), value: data.referral_count, icon: 'local_hospital' },
          { label: t('ref_completion'), value: `${data.referral_completion_rate}%`, icon: 'task_alt' },
          { label: t('last_active'), value: data.last_active ? new Date(data.last_active).toLocaleDateString() : '-', icon: 'schedule' },
        ].map((s) => (
          <div key={s.label} className="bg-white border border-border rounded-xl p-4">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[11px] font-semibold text-text-muted uppercase tracking-wider">{s.label}</span>
              <span className="material-symbols-outlined text-[16px] text-text-muted">{s.icon}</span>
            </div>
            <div className="text-xl font-bold text-text-heading">{s.value}</div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('risk_distribution')}</h3>
          <div className="flex gap-4">
            {[
              { label: t('high_risk'), value: rd.high || 0, color: 'text-red-600', bg: 'bg-red-100' },
              { label: t('mid_risk'), value: rd.mid || 0, color: 'text-amber-600', bg: 'bg-amber-100' },
              { label: t('low_risk'), value: rd.low || 0, color: 'text-green-600', bg: 'bg-green-100' },
            ].map((item) => (
              <div key={item.label} className={`flex-1 ${item.bg} rounded-lg p-3 text-center`}>
                <div className={`text-xl font-bold ${item.color}`}>{item.value}</div>
                <div className="text-[11px] text-text-muted mt-1">{item.label}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('weekly_activity')}</h3>
          <div className="space-y-2">
            {(data.weekly_activity || []).map((w) => (
              <div key={w.week} className="flex items-center justify-between text-sm">
                <span className="text-text-muted">{w.week}</span>
                <div className="flex gap-4">
                  <span>{t('assessments')}: <strong>{w.assessments}</strong></span>
                  <span>{t('referrals')}: <strong>{w.referrals}</strong></span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 mb-6">
        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('anc_completion')}</h3>
          <div className="space-y-1.5">
            {Object.entries(data.anc_completion || {}).map(([k, v]) => (
              <div key={k} className="flex items-center gap-3 text-sm">
                <span className="w-16 text-text-muted">{k.replace('_', ' ')}</span>
                <div className="flex-1 h-2 bg-surface rounded-full overflow-hidden">
                  <div className="h-full bg-blue-500 rounded-full" style={{ width: `${v}%` }} />
                </div>
                <span className="w-10 text-right font-semibold text-text-heading">{v}%</span>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white border border-border rounded-xl p-5">
          <h3 className="text-sm font-semibold text-text-heading mb-3">{t('pnc_completion')}</h3>
          <div className="space-y-1.5">
            {Object.entries(data.pnc_completion || {}).map(([k, v]) => (
              <div key={k} className="flex items-center gap-3 text-sm">
                <span className="w-16 text-text-muted">{k.replace('_', ' ')}</span>
                <div className="flex-1 h-2 bg-surface rounded-full overflow-hidden">
                  <div className="h-full bg-emerald-500 rounded-full" style={{ width: `${v}%` }} />
                </div>
                <span className="w-10 text-right font-semibold text-text-heading">{v}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="bg-white border border-border rounded-xl p-5">
        <h3 className="text-sm font-semibold text-text-heading mb-3">{t('patients')} ({data.patients?.length || 0})</h3>
        <table className="w-full text-sm">
          <thead>
            <tr className="text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="pb-2">{t('name')}</th>
              <th className="pb-2">{t('risk_level')}</th>
              <th className="pb-2">{t('last_assessment')}</th>
              <th className="pb-2"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {(data.patients || []).map((p) => (
              <tr key={p.id} className="hover:bg-surface/50 transition-colors">
                <td className="py-2 font-medium text-text-heading">{p.full_name}</td>
                <td className="py-2">
                  {p.risk_level ? (
                    <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${
                      p.risk_level === 'high risk' ? 'bg-red-100 text-red-700' :
                      p.risk_level === 'mid risk' ? 'bg-amber-100 text-amber-700' :
                      'bg-green-100 text-green-700'
                    }`}>{p.risk_level}</span>
                  ) : <span className="text-text-muted">-</span>}
                </td>
                <td className="py-2 text-text-muted">{p.last_assessment || '-'}</td>
                <td className="py-2">
                  <Link to={`/patients/${p.id}`} className="text-rose-500 text-xs font-semibold">{t('view')}</Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
