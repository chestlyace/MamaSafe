import { useEffect, useRef, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { listChws } from '../api/client';
import ManualChwModal from '../components/ManualChwModal';

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
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [showManualModal, setShowManualModal] = useState(false);
  const dropdownRef = useRef(null);

  const load = () => {
    setLoading(true);
    listChws().then(setChws).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target)) {
        setDropdownOpen(false);
      }
    };
    document.addEventListener('click', handleClickOutside);
    return () => document.removeEventListener('click', handleClickOutside);
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
      <header className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('community_health_workers')}</h1>
          <p className="text-sm text-text-muted mt-1">{chws.length} {t('workers_registered')}</p>
        </div>
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setDropdownOpen(!dropdownOpen)}
            className="bg-rose-500 text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 transition-colors flex items-center gap-1.5"
          >
            {t('add_chw')}
            <span className="material-symbols-outlined text-[18px]">expand_more</span>
          </button>
          {dropdownOpen && (
            <div className="absolute right-0 mt-2 bg-white rounded-xl shadow-lg border border-border z-20 min-w-[180px] overflow-hidden">
              <Link
                to="/supervisor/invites"
                onClick={() => setDropdownOpen(false)}
                className="flex items-center gap-2.5 px-4 py-2.5 hover:bg-surface text-sm text-text-heading transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">vpn_key</span>
                {t('add_chw_via_code')}
              </Link>
              <button
                onClick={() => { setDropdownOpen(false); setShowManualModal(true); }}
                className="w-full flex items-center gap-2.5 px-4 py-2.5 hover:bg-surface text-sm text-text-heading transition-colors"
              >
                <span className="material-symbols-outlined text-[18px]">person_add</span>
                {t('add_chw_manually')}
              </button>
            </div>
          )}
        </div>
      </header>

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

      <ManualChwModal
        open={showManualModal}
        onClose={() => setShowManualModal(false)}
        onSuccess={() => { setShowManualModal(false); load(); }}
      />
    </main>
  );
}
