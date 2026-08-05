import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { listInviteCodes, createInviteCode, revokeInviteCode } from '../api/client';

function InviteStatusBadge({ status }) {
  const { t } = useTranslation();
  const map = {
    pending:  { bg: 'bg-blue-100', text: 'text-blue-700', label: t('invite_pending') },
    used:     { bg: 'bg-green-100', text: 'text-green-700', label: t('invite_used') },
    revoked:  { bg: 'bg-red-100',  text: 'text-red-700',   label: t('invite_revoked') },
    expired:  { bg: 'bg-gray-100', text: 'text-gray-500',  label: t('invite_expired') },
  };
  const s = map[status] || map.pending;
  return <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${s.bg} ${s.text}`}>{s.label}</span>;
}

function formatDate(iso) {
  if (!iso) return '-';
  return new Date(iso).toLocaleDateString();
}

export default function InviteCodesPage() {
  const { t } = useTranslation();
  const [codes, setCodes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({ note: '', expires_in_days: 7 });
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [copied, setCopied] = useState(null);

  const load = () => {
    listInviteCodes().then(setCodes).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      await createInviteCode(form);
      setShowForm(false);
      setForm({ note: '', expires_in_days: 7 });
      load();
    } catch { setMessage(t('error')); } finally { setSaving(false); }
  };

  const handleCopy = (code) => {
    navigator.clipboard?.writeText(code);
    setCopied(code);
    setTimeout(() => setCopied(null), 1500);
  };

  const handleRevoke = async (id) => {
    setMessage('');
    try {
      await revokeInviteCode(id);
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

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <header className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('invite_codes')}</h1>
          <p className="text-sm text-text-muted mt-1">{t('invite_codes_desc')}</p>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-rose-500 text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors flex items-center gap-1.5"
        >
          <span className="material-symbols-outlined text-[18px]">vpn_key</span>
          {t('generate_code')}
        </button>
      </header>

      {message && (
        <div className="mb-6 bg-amber-50 border border-amber-200 text-amber-700 text-sm rounded-xl px-4 py-3">
          {message}
        </div>
      )}

      {showForm && (
        <form onSubmit={handleCreate} className="bg-white border border-border rounded-xl p-5 mb-6 space-y-3">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            <input placeholder={t('note_optional')} value={form.note} onChange={(e) => setForm({ ...form, note: e.target.value })}
              className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            <label className="flex items-center gap-2 text-sm text-text-muted">
              {t('expires_in_days')}
              <input type="number" min="1" max="365" value={form.expires_in_days}
                onChange={(e) => setForm({ ...form, expires_in_days: Number(e.target.value) })}
                className="w-24 px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading" />
            </label>
          </div>
          <div className="flex gap-2">
            <button type="submit" disabled={saving}
              className="bg-rose-500 text-white px-4 py-1.5 rounded-lg text-sm font-semibold hover:bg-rose-600 disabled:opacity-50">
              {saving ? t('saving') : t('generate_code')}
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
              <th className="px-4 py-3">{t('code')}</th>
              <th className="px-4 py-3">{t('status')}</th>
              <th className="px-4 py-3">{t('district')}</th>
              <th className="px-4 py-3">{t('note_optional')}</th>
              <th className="px-4 py-3">{t('expires')}</th>
              <th className="px-4 py-3">{t('created')}</th>
              <th className="px-4 py-3">{t('used_by')}</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {codes.map((c) => (
              <tr key={c.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-2">
                    <span className="font-mono font-semibold text-text-heading tracking-wider">{c.code}</span>
                    {c.status === 'pending' && (
                      <button onClick={() => handleCopy(c.code)} title={t('copy_code')}
                        className="text-text-muted hover:text-rose-500 transition-colors">
                        <span className="material-symbols-outlined text-[16px]">{copied === c.code ? 'check' : 'content_copy'}</span>
                      </button>
                    )}
                  </div>
                </td>
                <td className="px-4 py-3"><InviteStatusBadge status={c.status} /></td>
                <td className="px-4 py-3 text-text-muted">{c.district || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{c.note || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{formatDate(c.expires_at)}</td>
                <td className="px-4 py-3 text-text-muted">{formatDate(c.created_at)}</td>
                <td className="px-4 py-3 text-text-muted">{c.used_by_username || '-'}</td>
                <td className="px-4 py-3">
                  {c.status === 'pending' && (
                    <button onClick={() => handleRevoke(c.id)}
                      className="text-red-500 text-xs font-semibold hover:text-red-600">
                      {t('revoke')}
                    </button>
                  )}
                </td>
              </tr>
            ))}
            {codes.length === 0 && (
              <tr>
                <td colSpan={8} className="px-4 py-8 text-center text-text-muted">{t('no_invite_codes')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </main>
  );
}
