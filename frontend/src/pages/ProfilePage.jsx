import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { getMe, updateMe, changePassword } from '../api/client';

function RoleBadge({ role }) {
  const { t } = useTranslation();
  const map = {
    chw:        { bg: 'bg-blue-100', text: 'text-blue-700', label: t('chw') },
    supervisor: { bg: 'bg-purple-100', text: 'text-purple-700', label: t('supervisor') },
    admin:      { bg: 'bg-rose-100', text: 'text-rose-700', label: t('admin') },
  };
  const s = map[role] || map.chw;
  return <span className={`text-[11px] font-semibold px-2 py-0.5 rounded-full uppercase tracking-wide ${s.bg} ${s.text}`}>{s.label}</span>;
}

function formatDate(iso) {
  if (!iso) return '-';
  return new Date(iso).toLocaleDateString();
}

export default function ProfilePage() {
  const { t } = useTranslation();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);

  const [form, setForm] = useState({ full_name: '', whatsapp_number: '', facility: '', district: '', region: '' });
  const [saving, setSaving] = useState(false);
  const [profileMsg, setProfileMsg] = useState('');
  const [profileErr, setProfileErr] = useState('');

  const [pwd, setPwd] = useState({ current_password: '', new_password: '', confirm_password: '' });
  const [savingPwd, setSavingPwd] = useState(false);
  const [pwdMsg, setPwdMsg] = useState('');
  const [pwdErr, setPwdErr] = useState('');

  const load = () => {
    getMe().then((data) => {
      setProfile(data);
      setForm({
        full_name: data.full_name || '',
        whatsapp_number: data.whatsapp_number || '',
        facility: data.facility || '',
        district: data.district || '',
        region: data.region || '',
      });
    }).catch(() => {}).finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  if (loading || !profile) {
    return (
      <main className="max-w-[1200px] mx-auto px-5 py-12">
        <div className="flex items-center justify-center py-24">
          <span className="material-symbols-outlined text-4xl animate-spin text-rose-500 mr-3">progress_activity</span>
          <span className="text-text-muted">{t('loading')}</span>
        </div>
      </main>
    );
  }

  const isChw = profile.role === 'chw';
  const isSupervisor = profile.role === 'supervisor';
  const editableFields = profile.role === 'chw'
    ? ['full_name', 'whatsapp_number', 'facility']
    : profile.role === 'supervisor'
      ? ['full_name', 'whatsapp_number', 'district', 'region']
      : ['full_name', 'whatsapp_number'];

  const handleSaveProfile = async (e) => {
    e.preventDefault();
    setSaving(true);
    setProfileMsg('');
    setProfileErr('');
    try {
      const data = {};
      editableFields.forEach((f) => { data[f] = form[f] ?? null; });
      const updated = await updateMe(data);
      setProfile(updated);
      setProfileMsg(t('profile_updated'));
    } catch (err) {
      setProfileErr(err.response?.data?.detail || t('error'));
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async (e) => {
    e.preventDefault();
    setPwdMsg('');
    setPwdErr('');
    if (pwd.new_password.length < 8) {
      setPwdErr(t('password_too_short'));
      return;
    }
    if (pwd.new_password !== pwd.confirm_password) {
      setPwdErr(t('passwords_do_not_match'));
      return;
    }
    setSavingPwd(true);
    try {
      await changePassword(pwd.current_password, pwd.new_password);
      setPwdMsg(t('password_updated'));
      setPwd({ current_password: '', new_password: '', confirm_password: '' });
    } catch (err) {
      setPwdErr(err.response?.data?.detail || t('error'));
    } finally {
      setSavingPwd(false);
    }
  };

  const initial = (profile.full_name || profile.username || '?').trim().charAt(0).toUpperCase();

  const fieldInput = (name, label, placeholder) => (
    <label className="block">
      <span className="block text-sm font-medium text-text-muted mb-1">{label}</span>
      <input
        value={form[name] || ''}
        onChange={(e) => setForm({ ...form, [name]: e.target.value })}
        placeholder={placeholder || ''}
        className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
      />
    </label>
  );

  const readOnlyRow = (label, value) => (
    <div>
      <div className="text-sm font-medium text-text-muted mb-1">{label}</div>
      <div className="px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-muted">{value || '-'}</div>
    </div>
  );

  return (
    <main className="max-w-[1200px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      <h1 className="text-2xl font-bold text-text-heading tracking-tight mb-6">{t('profile')}</h1>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        {/* Account summary */}
        <div className="bg-white border border-border rounded-xl p-6">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-14 h-14 rounded-full bg-rose-500 text-white flex items-center justify-center text-2xl font-bold">
              {initial}
            </div>
            <div>
              <div className="text-lg font-bold text-text-heading">{profile.full_name || profile.username}</div>
              <div className="text-sm text-text-muted">@{profile.username}</div>
            </div>
          </div>
          <div className="flex items-center gap-2 mb-6">
            <RoleBadge role={profile.role} />
          </div>
          <dl className="space-y-3 text-sm">
            <div className="flex justify-between">
              <dt className="text-text-muted">{t('member_since')}</dt>
              <dd className="text-text-heading font-medium">{formatDate(profile.created_at)}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-text-muted">{t('last_active')}</dt>
              <dd className="text-text-heading font-medium">{formatDate(profile.last_active)}</dd>
            </div>
            <div className="flex justify-between">
              <dt className="text-text-muted">{t('status')}</dt>
              <dd className="text-text-heading font-medium">{profile.is_active ? t('active') : t('inactive')}</dd>
            </div>
          </dl>
        </div>

        {/* Editable profile */}
        <div className="lg:col-span-2 space-y-6">
          <form onSubmit={handleSaveProfile} className="bg-white border border-border rounded-xl p-6">
            <h2 className="text-lg font-bold text-text-heading mb-4">{t('account_info')}</h2>
            {profileMsg && (
              <div className="mb-4 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl px-4 py-3">{profileMsg}</div>
            )}
            {profileErr && (
              <div className="mb-4 bg-amber-50 border border-amber-200 text-amber-700 text-sm rounded-xl px-4 py-3">{profileErr}</div>
            )}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {fieldInput('full_name', t('full_name'), t('full_name'))}
              {fieldInput('whatsapp_number', t('whatsapp_number'))}
              {isChw
                ? fieldInput('facility', t('facility'))
                : readOnlyRow(t('facility'), profile.facility)}
              {isSupervisor
                ? fieldInput('district', t('district'))
                : readOnlyRow(t('district'), profile.district)}
              {isSupervisor
                ? fieldInput('region', t('region'))
                : readOnlyRow(t('region'), profile.region)}
            </div>
            <div className="mt-5">
              <button
                type="submit"
                disabled={saving}
                className="bg-rose-500 text-white px-5 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 disabled:opacity-50 transition-colors"
              >
                {saving ? t('saving') : t('save')}
              </button>
            </div>
          </form>

          {/* Change password */}
          <form onSubmit={handleChangePassword} className="bg-white border border-border rounded-xl p-6">
            <h2 className="text-lg font-bold text-text-heading mb-4">{t('change_password')}</h2>
            {pwdMsg && (
              <div className="mb-4 bg-green-50 border border-green-200 text-green-700 text-sm rounded-xl px-4 py-3">{pwdMsg}</div>
            )}
            {pwdErr && (
              <div className="mb-4 bg-amber-50 border border-amber-200 text-amber-700 text-sm rounded-xl px-4 py-3">{pwdErr}</div>
            )}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <label className="block">
                <span className="block text-sm font-medium text-text-muted mb-1">{t('current_password')}</span>
                <input
                  type="password"
                  value={pwd.current_password}
                  onChange={(e) => setPwd({ ...pwd, current_password: e.target.value })}
                  className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
                />
              </label>
              <label className="block">
                <span className="block text-sm font-medium text-text-muted mb-1">{t('new_password')}</span>
                <input
                  type="password"
                  value={pwd.new_password}
                  onChange={(e) => setPwd({ ...pwd, new_password: e.target.value })}
                  className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
                />
              </label>
              <label className="block">
                <span className="block text-sm font-medium text-text-muted mb-1">{t('confirm_password')}</span>
                <input
                  type="password"
                  value={pwd.confirm_password}
                  onChange={(e) => setPwd({ ...pwd, confirm_password: e.target.value })}
                  className="w-full px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading"
                />
              </label>
            </div>
            <div className="mt-5">
              <button
                type="submit"
                disabled={savingPwd}
                className="bg-rose-500 text-white px-5 py-2 rounded-xl text-sm font-semibold hover:bg-rose-600 disabled:opacity-50 transition-colors"
              >
                {savingPwd ? t('saving') : t('change_password')}
              </button>
            </div>
          </form>
        </div>
      </div>
    </main>
  );
}
