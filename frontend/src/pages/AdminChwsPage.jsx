import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listAdminChws } from '../api/client';

export default function AdminChwsPage() {
  const { t } = useTranslation();
  const [chws, setChws] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    listAdminChws().then(setChws).catch(() => {}).finally(() => setLoading(false));
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
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('community_health_workers')}</h1>
        <p className="text-sm text-text-muted mt-1">{chws.length} {t('workers_registered')}</p>
      </header>

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('name')}</th>
              <th className="px-4 py-3">{t('username')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('facility')}</th>
              <th className="px-4 py-3">{t('patients')}</th>
              <th className="px-4 py-3">{t('status')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {chws.map((chw) => (
              <tr key={chw.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{chw.full_name || chw.username}</td>
                <td className="px-4 py-3 text-text-muted">{chw.username}</td>
                <td className="px-4 py-3 text-text-muted">{chw.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{chw.facility || '-'}</td>
                <td className="px-4 py-3">{chw.patient_count}</td>
                <td className="px-4 py-3">
                  {chw.is_active
                    ? <span className="text-emerald-600 font-semibold">{t('active')}</span>
                    : <span className="text-text-muted">{t('inactive')}</span>}
                </td>
              </tr>
            ))}
            {chws.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-text-muted">{t('no_chws')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
