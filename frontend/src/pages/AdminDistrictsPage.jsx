import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listAdminDistricts } from '../api/client';

export default function AdminDistrictsPage() {
  const { t } = useTranslation();
  const [districts, setDistricts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listAdminDistricts().then(setDistricts).catch(() => {}).finally(() => setLoading(false));
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
      <Link to="/admin" className="inline-flex items-center gap-1 text-sm text-rose-500 hover:text-rose-600 mb-4">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t('back_to_admin')}
      </Link>
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('districts')}</h1>
        <p className="text-sm text-text-muted mt-1">{districts.length} {t('districts')}</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {districts.map((d) => (
          <div key={d.district} className="bg-white border border-border rounded-xl p-5">
            <h3 className="text-base font-bold text-text-heading">{d.district}</h3>
            <p className="text-sm text-text-muted mb-4">{d.region || '-'}</p>
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="bg-surface rounded-lg p-2">
                <div className="text-lg font-bold text-text-heading">{d.supervisor_count}</div>
                <div className="text-[11px] text-text-muted">{t('supervisors')}</div>
              </div>
              <div className="bg-surface rounded-lg p-2">
                <div className="text-lg font-bold text-text-heading">{d.chw_count}</div>
                <div className="text-[11px] text-text-muted">{t('chw')}</div>
              </div>
              <div className="bg-surface rounded-lg p-2">
                <div className="text-lg font-bold text-text-heading">{d.patient_count}</div>
                <div className="text-[11px] text-text-muted">{t('patients')}</div>
              </div>
            </div>
          </div>
        ))}
        {districts.length === 0 && (
          <p className="col-span-full text-center py-16 text-text-muted">{t('no_districts')}</p>
        )}
      </div>
    </main>
  );
}
