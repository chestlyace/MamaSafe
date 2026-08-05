import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { chwSignup } from '../api/client';
import LanguageToggle from '../components/LanguageToggle';
import logo from '../assets/logo.svg';

export default function ChwSignupPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    full_name: '', username: '', password: '',
    facility: '', whatsapp_number: '', invite_code: '',
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await chwSignup(form);
      setSuccess(true);
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setLoading(false);
    }
  };

  const inputClass = "w-full px-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/60 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all";
  const labelClass = "block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5";

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      <div className="flex justify-end p-5">
        <LanguageToggle />
      </div>
      <div className="flex-1 flex items-center justify-center px-5 pb-12">
        <div className="w-full max-w-[440px]">
          <div className="text-center mb-8">
            <img src={logo} alt="MamaSafe" className="h-16 w-auto mx-auto mb-3" />
            <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('chw_signup_title')}</h1>
            <p className="text-sm text-text-muted mt-1">{t('chw_signup_desc')}</p>
          </div>

          {success ? (
            <div className="bg-white rounded-2xl border border-border p-8 text-center">
              <span className="material-symbols-outlined text-5xl text-green-500">check_circle</span>
              <h2 className="text-xl font-bold text-text-heading mt-4">{t('chw_signup_success')}</h2>
              <p className="text-sm text-text-muted mt-2">{t('chw_signup_success_desc')}</p>
              <button
                onClick={() => navigate('/login')}
                className="mt-6 w-full py-3 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 transition-colors"
              >
                {t('go_to_login')}
              </button>
            </div>
          ) : (
            <div className="bg-white rounded-2xl border border-border p-6 sm:p-8">
              {error && (
                <div className="mb-5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                  {error}
                </div>
              )}
              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className={labelClass}>{t('invite_code')}</label>
                  <input required value={form.invite_code} onChange={(e) => setForm({ ...form, invite_code: e.target.value })}
                    placeholder="XXXX-XXXX"
                    className={`${inputClass} text-center font-mono tracking-[0.3em] uppercase`} />
                </div>
                <div>
                  <label className={labelClass}>{t('full_name')}</label>
                  <input required value={form.full_name} onChange={(e) => setForm({ ...form, full_name: e.target.value })}
                    placeholder={t('full_name')} className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>{t('username')}</label>
                  <input required value={form.username} onChange={(e) => setForm({ ...form, username: e.target.value })}
                    placeholder={t('username')} className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>{t('password')}</label>
                  <input required type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })}
                    placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;" className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>{t('facility')}</label>
                  <input value={form.facility} onChange={(e) => setForm({ ...form, facility: e.target.value })}
                    placeholder={t('facility')} className={inputClass} />
                </div>
                <div>
                  <label className={labelClass}>{t('whatsapp_number')}</label>
                  <input value={form.whatsapp_number} onChange={(e) => setForm({ ...form, whatsapp_number: e.target.value })}
                    placeholder={t('whatsapp_number')} className={inputClass} />
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 mt-2"
                >
                  {loading ? (
                    <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
                  ) : (
                    t('create_account')
                  )}
                </button>
              </form>
            </div>
          )}

          <p className="text-center text-xs text-text-muted mt-6">
            <Link to="/login" className="text-rose-500 hover:text-rose-600 font-medium">{t('back_to_login')}</Link>
          </p>
        </div>
      </div>
    </div>
  );
}
