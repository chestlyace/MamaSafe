import { useCallback, useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { listChwPatients, listChws, transferPatient } from '../api/client';

function RiskBadge({ risk }) {
  if (!risk) return <span className="text-text-muted">-</span>;
  const map = {
    'high risk': 'bg-red-100 text-red-700',
    'mid risk':  'bg-amber-100 text-amber-700',
    'low risk':  'bg-green-100 text-green-700',
  };
  return <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full ${map[risk] || 'bg-gray-100 text-gray-600'}`}>{risk}</span>;
}

export default function ChwPatientsPage() {
  const { chwId } = useParams();
  const { t } = useTranslation();
  const [patients, setPatients] = useState([]);
  const [chws, setChws] = useState([]);
  const [loading, setLoading] = useState(true);
  const [transferTarget, setTransferTarget] = useState(null);
  const [transferForm, setTransferForm] = useState({ new_chw_id: '', reason: '' });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const load = useCallback(() => {
    Promise.all([listChwPatients(chwId), listChws()])
      .then(([p, c]) => {
        setPatients(p);
        setChws(c.filter((chw) => chw.id !== Number(chwId)));
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [chwId]);

  useEffect(() => { load(); }, [load]);

  const handleTransfer = async (e) => {
    e.preventDefault();
    setError('');
    setSaving(true);
    try {
      await transferPatient(transferTarget.id, {
        new_chw_id: Number(transferForm.new_chw_id),
        reason: transferForm.reason,
      });
      setTransferTarget(null);
      setTransferForm({ new_chw_id: '', reason: '' });
      setMessage(t('patient_transferred'));
      load();
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setSaving(false);
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
      <Link to={`/supervisor/chws/${chwId}`} className="inline-flex items-center gap-1 text-sm text-rose-500 hover:text-rose-600 mb-4">
        <span className="material-symbols-outlined text-[16px]">arrow_back</span>
        {t('back_to_chw')}
      </Link>

      <header className="mb-6">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('chw_patients')}</h1>
        <p className="text-sm text-text-muted mt-1">{patients.length} {t('patients')}</p>
      </header>

      {message && (
        <div className="mb-6 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl px-4 py-3">
          {message}
        </div>
      )}
      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <div className="bg-white border border-border rounded-xl overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-surface text-left text-[11px] font-semibold text-text-muted uppercase tracking-wider">
              <th className="px-4 py-3">{t('full_name')}</th>
              <th className="px-4 py-3">{t('date_of_birth')}</th>
              <th className="px-4 py-3">{t('phone')}</th>
              <th className="px-4 py-3">{t('risk_level')}</th>
              <th className="px-4 py-3">{t('last_assessment')}</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {patients.map((p) => (
              <tr key={p.id} className="hover:bg-surface/50 transition-colors">
                <td className="px-4 py-3 font-medium text-text-heading">{p.full_name}</td>
                <td className="px-4 py-3 text-text-muted">{p.date_of_birth || '-'}</td>
                <td className="px-4 py-3 text-text-muted">{p.phone || '-'}</td>
                <td className="px-4 py-3"><RiskBadge risk={p.risk_level} /></td>
                <td className="px-4 py-3 text-text-muted">{p.last_assessment || '-'}</td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => setTransferTarget(p)}
                    className="text-rose-500 text-xs font-semibold hover:text-rose-600"
                  >
                    {t('transfer')}
                  </button>
                </td>
              </tr>
            ))}
            {patients.length === 0 && (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-text-muted">{t('no_patients_yet')}</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {transferTarget && (
        <div className="fixed inset-0 bg-black/30 z-50 flex items-center justify-center px-5">
          <div className="bg-white rounded-2xl p-6 w-full max-w-md">
            <h2 className="text-lg font-bold text-text-heading mb-1">{t('transfer_patient')}</h2>
            <p className="text-sm text-text-muted mb-4">{transferTarget.full_name}</p>
            <form onSubmit={handleTransfer} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">{t('new_chw')}</label>
                <select
                  required
                  value={transferForm.new_chw_id}
                  onChange={(e) => setTransferForm({ ...transferForm, new_chw_id: e.target.value })}
                  className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
                >
                  <option value="">{t('select')}</option>
                  {chws.map((chw) => (
                    <option key={chw.id} value={chw.id}>{chw.full_name || chw.username}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">{t('reason_optional')}</label>
                <input
                  value={transferForm.reason}
                  onChange={(e) => setTransferForm({ ...transferForm, reason: e.target.value })}
                  className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
                />
              </div>
              <div className="flex gap-2">
                <button type="submit" disabled={saving}
                  className="flex-1 bg-rose-500 text-white px-4 py-2 rounded-lg text-sm font-semibold hover:bg-rose-600 disabled:opacity-50">
                  {saving ? t('saving') : t('confirm_transfer')}
                </button>
                <button type="button" onClick={() => setTransferTarget(null)}
                  className="px-4 py-2 text-sm text-text-muted">{t('cancel')}</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}
