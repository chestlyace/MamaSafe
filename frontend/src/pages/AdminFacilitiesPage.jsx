import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listAdminFacilities, approveFacility } from '../api/client';

export default function AdminFacilitiesPage() {
  const { t } = useTranslation();
  const [facilities, setFacilities] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState('');

  const load = () => {
    listAdminFacilities().then(setFacilities).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleApprove = async (id) => {
    setMessage('');
    try {
      await approveFacility(id);
      setMessage(t('facility_approved'));
      load();
    } catch (err) {
      setMessage(err.response?.data?.detail || t('error'));
    }
  };

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

  const pending = facilities.filter((f) => !f.approved);
  const approved = facilities.filter((f) => f.approved);

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <Link to="/admin" className="inline-flex items-center gap-1 text-sm text-rose-500 hover:text-rose-600 mb-4">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t('back_to_admin')}
      </Link>
      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('facilities')}</h1>
        <p className="text-sm text-text-muted mt-1">{pending.length} {t('facilities_pending')}</p>
      </header>

      {message && (
        <div className="mb-6 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl px-4 py-3">
          {message}
        </div>
      )}

      <div className="bg-white border border-border rounded-xl overflow-hidden mb-8">
        <div className="px-4 py-3 bg-amber-50 border-b border-amber-100 text-sm font-semibold text-amber-800">
          {t('pending_approvals')}
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('name')}</th>
              <th className="px-4 py-3">{t('level')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('phone')}</th>
              <th className="px-4 py-3">{t('whatsapp_number')}</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {pending.map((f) => (
              <tr key={f.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{f.name}</td>
                <td className="px-4 py-3 text-text-muted">{t(`level_${f.level}`) || f.level}</td>
                <td className="px-4 py-3 text-text-muted">{f.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.phone || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.whatsapp || '-'}</td>
                <td className="px-4 py-3">
                  <button onClick={() => handleApprove(f.id)}
                    className="bg-green-500 text-white px-3 py-1.5 rounded-lg text-xs font-semibold hover:bg-green-600 transition-colors">
                    {t('approve')}
                  </button>
                </td>
              </tr>
            ))}
            {pending.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-text-muted">{t('no_pending_facilities')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <div className="px-4 py-3 bg-surface border-b border-border text-sm font-semibold text-text-heading">
          {t('approved_facilities')}
        </div>
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('name')}</th>
              <th className="px-4 py-3">{t('level')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('region')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {approved.map((f) => (
              <tr key={f.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{f.name}</td>
                <td className="px-4 py-3 text-text-muted">{t(`level_${f.level}`) || f.level}</td>
                <td className="px-4 py-3 text-text-muted">{f.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.region || '-'}</td>
              </tr>
            ))}
            {approved.length === 0 && (
              <tr>
                <td colSpan={4} className="px-4 py-8 text-center text-text-muted">{t('no_approved_facilities')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
