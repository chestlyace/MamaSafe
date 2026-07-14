import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { login } from '../api/client';
import LanguageToggle from '../components/LanguageToggle';
import logo from '../assets/logo.svg';

export default function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const data = await login(username, password);
      localStorage.setItem('token', data.access_token);
      navigate('/assess');
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-canvas flex flex-col">
      {/* Top bar */}
      <div className="flex justify-end p-5">
        <LanguageToggle />
      </div>

      {/* Center content */}
      <div className="flex-1 flex items-center justify-center px-5 pb-12">
        <div className="w-full max-w-[380px]">
          {/* Brand */}
          <div className="text-center mb-8">
            <img src={logo} alt="MamaSafe" className="h-16 w-auto mx-auto mb-3" />
            <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('app_name')}</h1>
            <p className="text-sm text-text-muted mt-1">{t('tagline')}</p>
          </div>

          {/* Card */}
          <div className="bg-white rounded-2xl border border-border p-6 sm:p-8">
            {/* Error */}
            {error && (
              <div className="mb-5 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
                {error}
              </div>
            )}

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Username */}
              <div>
                <label htmlFor="username" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
                  {t('username')}
                </label>
                <input
                  id="username"
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder={t('health_worker_id')}
                  required
                  className="w-full px-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/60 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                />
              </div>

              {/* Password */}
              <div>
                <label htmlFor="password" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
                  {t('password')}
                </label>
                <div className="relative">
                  <input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;"
                    required
                    className="w-full px-4 py-3 pr-11 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/60 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-rose-500 transition-colors"
                    tabIndex={-1}
                  >
                    <span className="material-symbols-outlined text-[20px]">
                      {showPassword ? 'visibility_off' : 'visibility'}
                    </span>
                  </button>
                </div>
              </div>

              {/* Submit */}
              <button
                type="submit"
                disabled={loading}
                className="w-full py-3 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed mt-2"
              >
                {loading ? (
                  <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
                ) : (
                  <>
                    <span>{t('login')}</span>
                    <span className="material-symbols-outlined text-lg group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Footer */}
          <p className="text-center text-xs text-text-muted mt-6">
            Developing Innovative Professionals — YIBS
          </p>
        </div>
      </div>
    </div>
  );
}
