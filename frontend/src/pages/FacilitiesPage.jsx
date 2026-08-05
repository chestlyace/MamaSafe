import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getFacilities, getPendingFacilities, addFacility, approveFacility, rejectFacility, getMe } from '../api/client';

export default function FacilitiesPage() {
  const { t } = useTranslation();
  const [facilities, setFacilities] = useState([]);
  const [pending, setPending] = useState([]);
  const [loading, setLoading] = useState(true);
  const [pendingLoading, setPendingLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [banner, setBanner] = useState('');
  const [actingId, setActingId] = useState(null);
  const [tab, setTab] = useState('approved');
  const [form, setForm] = useState({ name: '', level: 'health_center', district: '', phone: '', whatsapp: '' });

  const load = () => {
    getFacilities().then(setFacilities).catch(() => {}).finally(() => setLoading(false));
  };

  const loadPending = () => {
    getPendingFacilities().then(setPending).catch(() => {}).finally(() => setPendingLoading(false));
  };

  useEffect(() => {
    load();
    loadPending();
  }, []);

  useEffect(() => {
    if (showForm) {
      getMe().then((user) => {
        if (user.district) setForm((f) => ({ ...f, district: user.district }));
      }).catch(() => {});
    }
  }, [showForm]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setBanner('');
    setSaving(true);
    try {
      await addFacility(form);
      setBanner(t('facility_added'));
      setShowForm(false);
      setForm({ name: '', level: 'health_center', district: '', phone: '', whatsapp: '' });
      load();
      setTab('approved');
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setSaving(false);
    }
  };

  const handleApprove = async (id) => {
    setError('');
    setBanner('');
    setActingId(id);
    try {
      await approveFacility(id);
      setBanner(t('facility_approved'));
      loadPending();
      load();
    } catch (err) {
      setError(err.response?.data?.detail || t('approve_failed'));
    } finally {
      setActingId(null);
    }
  };

  const handleReject = async (id) => {
    setError('');
    setBanner('');
    setActingId(id);
    try {
      await rejectFacility(id);
      setBanner(t('facility_rejected'));
      loadPending();
    } catch (err) {
      setError(err.response?.data?.detail || t('reject_failed'));
    } finally {
      setActingId(null);
    }
  };

  const inputClass = "px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading";

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
      <header className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('facilities')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('facilities_desc')}</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-rose-500 text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors flex items-center gap-1.5"
        >
          <span className="material-symbols-outlined text-[18px]">add_location</span>
          {t('add_facility')}
        </button>
      </header>

      {banner && (
        <div className="mb-6 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl px-4 py-3">
          {banner}
        </div>
      )}

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <div className="flex gap-1 mb-6 bg-surface rounded-xl p-1 w-fit">
        <button
          onClick={() => setTab('approved')}
          className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${tab === 'approved' ? 'bg-white text-text-heading shadow-sm' : 'text-text-muted hover:text-text-heading'}`}
        >
          {t('facilities_approved_tab')}
          <span className="ml-2 text-xs text-text-muted">{facilities.length}</span>
        </button>
        <button
          onClick={() => setTab('pending')}
          className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors ${tab === 'pending' ? 'bg-white text-text-heading shadow-sm' : 'text-text-muted hover:text-text-heading'}`}
        >
          {t('facilities_pending_tab')}
          <span className="ml-2 text-xs text-text-muted">{pending.length}</span>
        </button>
      </div>

      {showForm && (
        <form onSubmit={handleSubmit} className="bg-white border border-border rounded-xl p-5 mb-6 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <input placeholder={`${t('name')} *`} value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} required className={inputClass} />
            <select value={form.level} onChange={(e) => setForm({ ...form, level: e.target.value })} className={inputClass}>
              <option value="health_post">{t('level_health_post')}</option>
              <option value="health_center">{t('level_health_center')}</option>
              <option value="district_hospital">{t('level_district_hospital')}</option>
              <option value="regional_hospital">{t('level_regional_hospital')}</option>
              <option value="central_hospital">{t('level_central_hospital')}</option>
            </select>
            <input placeholder={t('district')} value={form.district} onChange={(e) => setForm({ ...form, district: e.target.value })} className={inputClass} />
            <input placeholder={t('phone')} value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} className={inputClass} />
            <input placeholder={t('whatsapp_number')} value={form.whatsapp} onChange={(e) => setForm({ ...form, whatsapp: e.target.value })} className={inputClass} />
          </div>
          <div className="flex gap-2">
            <button type="submit" disabled={saving}
              className="bg-rose-500 text-white px-4 py-1.5 rounded-lg text-sm font-semibold hover:bg-rose-600 disabled:opacity-50">
              {saving ? t('saving') : t('add_facility')}
            </button>
            <button type="button" onClick={() => setShowForm(false)}
              className="text-text-muted px-4 py-1.5 text-sm">{t('cancel')}</button>
          </div>
        </form>
      )}

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('name')}</th>
              <th className="px-4 py-3">{t('level')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('region')}</th>
              <th className="px-4 py-3">{t('phone')}</th>
              <th className="px-4 py-3">{t('whatsapp_number')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {facilities.map((f) => (
              <tr key={f.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{f.name}</td>
                <td className="px-4 py-3 text-text-muted">{t(`level_${f.level}`) || f.level}</td>
                <td className="px-4 py-3 text-text-muted">{f.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.region || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.phone || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{f.whatsapp || '-'}</td>
              </tr>
            ))}
            {facilities.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-text-muted">{t('no_facilities')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {tab === 'pending' && (
        <div className="bg-white border border-border rounded-xl overflow-hidden">
          {pendingLoading ? (
            <div className="flex items-center justify-center py-16">
              <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
              <span className="text-text-muted">{t('loading')}</span>
            </div>
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
                  <th className="px-4 py-3">{t('name')}</th>
                  <th className="px-4 py-3">{t('level')}</th>
                  <th className="px-4 py-3">{t('district')}</th>
                  <th className="px-4 py-3">{t('suggested_by')}</th>
                  <th className="px-4 py-3">{t('actions')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {pending.map((f) => (
                  <tr key={f.id} className="hover:bg-surface/50 transition-colors">
                    <td className="px-4 py-3 font-medium text-text-heading">{f.name}</td>
                    <td className="px-4 py-3 text-text-muted">{t(`level_${f.level}`) || f.level}</td>
                    <td className="px-4 py-3 text-text-muted">{f.district || '-'}</td>
                    <td className="px-4 py-3 text-text-muted">{f.suggested_by_name || '-'}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <button
                          onClick={() => handleApprove(f.id)}
                          disabled={actingId !== null}
                          className="bg-green-500 text-white px-3 py-1.5 rounded-lg text-xs font-semibold hover:bg-green-600 disabled:opacity-50 transition-colors flex items-center gap-1"
                        >
                          {actingId === f.id ? (
                            <span className="material-symbols-outlined text-sm animate-spin">progress_activity</span>
                          ) : (
                            <span className="material-symbols-outlined text-sm">check</span>
                          )}
                          {t('approve')}
                        </button>
                        <button
                          onClick={() => handleReject(f.id)}
                          disabled={actingId !== null}
                          className="bg-red-500 text-white px-3 py-1.5 rounded-lg text-xs font-semibold hover:bg-red-600 disabled:opacity-50 transition-colors flex items-center gap-1"
                        >
                          {actingId === f.id ? (
                            <span className="material-symbols-outlined text-sm animate-spin">progress_activity</span>
                          ) : (
                            <span className="material-symbols-outlined text-sm">close</span>
                          )}
                          {t('reject')}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {pending.length === 0 && (
                  <tr>
                    <td colSpan={5} className="px-4 py-8 text-center text-text-muted">{t('no_pending_facilities')}</td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      )}
    </main>
  );
}
