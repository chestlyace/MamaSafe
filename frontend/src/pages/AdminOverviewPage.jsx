import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listAdminDistricts, listAdminSupervisors, listAdminChws, listAdminFacilities } from '../api/client';

export default function AdminOverviewPage() {
  const { t } = useTranslation();
  const [stats, setStats] = useState({ districts: 0, supervisors: 0, chws: 0, patients: 0, facilities: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      listAdminDistricts().catch(() => []),
      listAdminSupervisors().catch(() => []),
      listAdminChws().catch(() => []),
      listAdminFacilities().catch(() => []),
    ]).then(([districts, supervisors, chws, facilities]) => {
      setStats({
        districts: districts.length,
        supervisors: supervisors.length,
        chws: chws.length,
        patients: districts.reduce((sum, d) => sum + (d.patient_count || 0), 0),
        facilities: facilities.length,
      });
    }).finally(() => setLoading(false));
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

  const cards = [
    { label: t('districts'), value: stats.districts, icon: 'map', to: '/admin/districts', color: 'text-blue-600 bg-blue-100' },
    { label: t('supervisors'), value: stats.supervisors, icon: 'supervisor_account', to: '/admin/supervisors', color: 'text-violet-600 bg-violet-100' },
    { label: t('total_chws'), value: stats.chws, icon: 'group', to: '/admin/chws', color: 'text-emerald-600 bg-emerald-100' },
    { label: t('patients'), value: stats.patients, icon: 'people', to: '/admin/districts', color: 'text-rose-600 bg-rose-100' },
    { label: t('facilities'), value: stats.facilities, icon: 'local_hospital', to: '/admin/facilities', color: 'text-teal-600 bg-teal-100' },
  ];

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('admin_overview')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('admin_overview_desc')}</p>
      </header>

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4">
        {cards.map((c) => (
          <Link key={c.label} to={c.to}
            className="bg-white border border-border rounded-xl p-5 hover:shadow-md transition-shadow">
            <div className="flex items-center justify-between mb-3">
              <span className={`material-symbols-outlined text-[22px] p-2 rounded-lg ${c.color}`}>{c.icon}</span>
            </div>
            <div className="text-2xl font-bold text-text-heading">{c.value ?? <span className="material-symbols-outlined text-xl">arrow_forward</span>}</div>
            <div className="text-sm text-text-muted mt-1">{c.label}</div>
          </Link>
        ))}
      </div>
    </main>
  );
}
