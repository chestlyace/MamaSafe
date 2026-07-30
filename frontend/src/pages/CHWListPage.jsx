import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { listChws, createChw } from '../api/client';

function StatusBadge({ status }) {
  const { t } = useTranslation();
  const map = {
    active:           { bg: 'bg-green-100', text: 'text-green-700', label: t('active') },
    inactive_warning: { bg: 'bg-amber-100', text: 'text-amber-700', label: t('inactive_warning') },
    inactive:         { bg: 'bg-red-100',   text: 'text-red-700',   label: t('inactive') },
    never_active:     { bg: 'bg-gray-100',  text: 'text-gray-500',  label: t('never_active') },
  };
  const s = map[status] || map.never_active;
  return <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${s.bg} ${s.text}`}>{s.label}</span>;
}

export default function CHWListPage() {
  const { t } = useTranslation();
  const [chws, setChws] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ username: '', password: '', full_name: '', facility: '', district: '', whatsapp_number: '' });
  const [saving, setSaving] = useState(false);

  const load = () => {
    setLoading(true);
    listChws().then(setChws).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    setSaving(true);
    try {
      await createChw(form);
      setShowForm(false);
      setForm({ username: '', password: '', full_name: '', facility: '', district: '', whatsapp_number: '' });
      load();
    } catch { } finally { setSaving(false); }
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

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('community_health_workers')}</h1>
          <p className="text-sm text-text-muted mt-1">{chws.length} {t('workers_registered')}</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-rose-500 text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors flex items-center gap-1.5"
        >
          <span className="material-symbols-outlined text-[18px]">person_add</span>
          {t('add_chw')}
        </button>
      </header>

      {showForm && (
        <form onSubmit={handleCreate} className="bg-white border border-border rounded-xl p-5 mb-6 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <input placeholder={t('username')} value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })} required
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <input type="password" placeholder={t('password')} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} required
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <input placeholder={t('full_name')} value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })}
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <input placeholder={t('facility')} value={form.facility} onChange={(e) => setForm({ ...form, facility: e.target.value })}
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <input placeholder={t('district')} value={form.district} onChange={(e) => setForm({ ...form, district: e.target.value })}
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <input placeholder={t('whatsapp_number')} value={form.whatsapp_number} onChange={(e) => setForm({ ...form, whatsapp_number: e.target.value })}
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
          </div>
          <div className="flex gap-2">
            <button type="submit" disabled={saving}
              className="bg-rose-500 text-white px-4 py-1.5 rounded-lg text-sm font-semibold hover:bg-rose-600 disabled:opacity-50">
              {saving ? t('saving') : t('create')}
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
              <th className="px-4 py-3">{t('username')}</th>
              <th className="px-4 py-3">{t('facility')}</th>
              <th className="px-4 py-3">{t('status')}</th>
              <th className="px-4 py-3">{t('patients')}</th>
              <th className="px-4 py-3">{t('assessments')}</th>
              <th className="px-4 py-3">{t('referrals')}</th>
              <th className="px-4 py-3">{t('high_risk')}</th>
              <th className="px-4 py-3">{t('ref_completion')}</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {chws.map((chw) => (
              <tr key={chw.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{chw.full_name || chw.username}</td>
                <td className="px-4 py-3 text-text-muted">{chw.username}</td>
                <td className="px-4 py-3 text-text-muted">{chw.facility || '-'}</td>
                <td className="px-4 py-3"><StatusBadge status={chw.status} /></td>
                <td className="px-4 py-3">{chw.patient_count}</td>
                <td className="px-4 py-3">{chw.assessment_count}</td>
                <td className="px-4 py-3">{chw.referral_count}</td>
                <td className="px-4 py-3">
                  {chw.high_risk_count > 0
                    ? <span className="text-red-600 font-semibold">{chw.high_risk_count}</span>
                    : <span className="text-text-muted">0</span>}
                </td>
                <td className="px-4 py-3">{chw.referral_completion_rate}%</td>
                <td className="px-4 py-3">
                  <Link to={`/supervisor/chws/${chw.id}`}
                    className="text-rose-500 text-xs font-semibold hover:text-rose-600">
                    {t('view')}
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </main>
  );
}
