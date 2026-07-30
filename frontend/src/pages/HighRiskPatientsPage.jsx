import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { getHighRiskPatients } from '../api/client';

export default function HighRiskPatientsPage() {
  const { t } = useTranslation();
  const [patients, setPatients] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getHighRiskPatients()
      .then(setPatients)
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

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('high_risk_patients')}</h1>
        <p className="text-sm text-text-muted mt-1">{patients.length} {t('patients_flagged_high_risk')}</p>
      </header>

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('patient')}</th>
              <th className="px-4 py-3">{t('age')}</th>
              <th className="px-4 py-3">{t('chw')}</th>
              <th className="px-4 py-3">{t('facility')}</th>
              <th className="px-4 py-3">{t('last_assessment')}</th>
              <th className="px-4 py-3">{t('days_ago')}</th>
              <th className="px-4 py-3">{t('bp')}</th>
              <th className="px-4 py-3">{t('blood_sugar')}</th>
              <th className="px-4 py-3">{t('referral_made')}</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {patients.length === 0 ? (
              <tr><td colSpan={10} className="px-4 py-12 text-center text-text-muted">{t('no_high_risk_patients')}</td></tr>
            ) : (
              patients.map((p) => (
                <tr key={p.patient_id} className={`hover:bg-surface/50 transition-colors ${p.flagged ? 'bg-red-50' : ''}`}>
                  <td className="px-4 py-3 font-medium text-text-heading">{p.full_name}</td>
                  <td className="px-4 py-3 text-text-muted">{p.age || '-'}</td>
                  <td className="px-4 py-3 text-text-muted">{p.chw_name || '-'}</td>
                  <td className="px-4 py-3 text-text-muted">{p.facility || '-'}</td>
                  <td className="px-4 py-3 text-text-muted">{p.last_assessment_date || '-'}</td>
                  <td className="px-4 py-3">
                    {p.flagged
                      ? <span className="text-red-600 font-semibold">{p.days_since_assessment}d</span>
                      : <span className="text-text-muted">{p.days_since_assessment}d</span>}
                  </td>
                  <td className="px-4 py-3 text-text-muted">{p.systolic_bp ? `${p.systolic_bp}` : '-'}</td>
                  <td className="px-4 py-3 text-text-muted">{p.blood_sugar || '-'}</td>
                  <td className="px-4 py-3">
                    {p.referral_made
                      ? <span className="text-green-600 text-[11px] font-semibold">{t('yes')}</span>
                      : <span className="text-red-500 text-[11px] font-semibold">{t('no')}</span>}
                  </td>
                  <td className="px-4 py-3">
                    <Link to={`/patients/${p.patient_id}`}
                      className="text-rose-500 text-xs font-semibold hover:text-rose-600">
                      {t('view')}
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
