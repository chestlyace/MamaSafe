import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listAdminSupervisors } from '../api/client';

export default function AdminSupervisorsPage() {
  const { t } = useTranslation();
  const [supervisors, setSupervisors] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listAdminSupervisors().then(setSupervisors).catch(() => {}).finally(() => setLoading(false));
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
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('supervisors')}</h1>
        <p className="text-sm text-text-muted mt-1">{supervisors.length} {t('supervisors')}</p>
      </header>

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('name')}</th>
              <th className="px-4 py-3">{t('username')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('region')}</th>
              <th className="px-4 py-3">{t('total_chws')}</th>
              <th className="px-4 py-3">{t('patients')}</th>
              <th className="px-4 py-3">{t('last_active')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {supervisors.map((s) => (
              <tr key={s.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{s.full_name || s.username}</td>
                <td className="px-4 py-3 text-text-muted">{s.username}</td>
                <td className="px-4 py-3 text-text-muted">{s.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{s.region || '-'}</td>
                <td className="px-4 py-3">{s.chw_count}</td>
                <td className="px-4 py-3">{s.patient_count}</td>
                <td className="px-4 py-3 text-text-muted">{s.last_active ? new Date(s.last_active).toLocaleDateString() : '-'}</td>
              </tr>
            ))}
            {supervisors.length === 0 && (
              <tr>
                <td colSpan={7} className="px-4 py-8 text-center text-text-muted">{t('no_supervisors')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
