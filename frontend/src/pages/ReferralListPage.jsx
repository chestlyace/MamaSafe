import { useState, useEffect } from 'react';
import { getReferrals, getReferralStats } from '../api/client';
import ReferralCard from '../components/ReferralCard';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';

export default function ReferralListPage() {
  const { t } = useTranslation();
  const [referrals, setReferrals] = useState([]);
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    setLoading(true);
    Promise.all([
      getReferrals({ status: filter === 'all' ? undefined : filter }),
      getReferralStats(),
    ])
      .then(([r, s]) => { setReferrals(r); setStats(s); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [filter]);

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <p className="text-gray-400 text-sm">{t('loading')}</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 px-4 py-8 pb-24 space-y-6">
      <div className="flex items-center justify-between">
        <Link to="/" className="text-gray-400 hover:text-gray-600">
          <span className="material-symbols-outlined">arrow_back</span>
        </Link>
        <h1 className="text-lg font-bold text-gray-800">{t('referral_history')}</h1>
        <div className="w-8" />
      </div>

      {stats && (
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
            <p className="text-2xl font-bold text-gray-800">{stats.total}</p>
            <p className="text-xs text-gray-500 mt-1">{t('total')}</p>
          </div>
          <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
            <p className="text-2xl font-bold text-yellow-600">{stats.pending}</p>
            <p className="text-xs text-gray-500 mt-1">{t('pending')}</p>
          </div>
          <div className="bg-white rounded-2xl p-4 text-center shadow-sm border border-gray-100">
            <p className="text-2xl font-bold text-green-600">{stats.delivered}</p>
            <p className="text-xs text-gray-500 mt-1">{t('delivered')}</p>
          </div>
        </div>
      )}

      <div className="flex gap-2 overflow-x-auto">
        {['all', 'sent', 'received', 'patient_arrived'].map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-4 py-2 rounded-full text-xs font-semibold whitespace-nowrap transition-colors ${
              filter === f
                ? 'bg-rose-600 text-white'
                : 'bg-white text-gray-600 border border-gray-200 hover:border-rose-300'
            }`}
          >
            {f === 'patient_arrived' ? t('arrived') : f === 'all' ? t('all') : f}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {referrals.length === 0 ? (
          <div className="text-center py-12">
            <span className="material-symbols-outlined text-gray-300 text-5xl">local_hospital</span>
            <p className="text-gray-400 text-sm mt-3">{t('no_referrals')}</p>
          </div>
        ) : (
          referrals.map((r) => <ReferralCard key={r.id} referral={r} />)
        )}
      </div>
    </div>
  );
}
