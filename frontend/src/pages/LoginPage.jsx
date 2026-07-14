import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { login } from '../api/client';
import LanguageToggle from '../components/LanguageToggle';

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
      const msg =
        err.response?.data?.detail || t('error');
      setError(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="relative min-h-screen flex items-center justify-center overflow-hidden"
      style={{ background: 'linear-gradient(135deg, #f5f2fe 0%, #ffffff 100%)' }}>

      {/* Animated background blobs */}
      <div className="blob blob-1" />
      <div className="blob blob-2" />

      {/* Language toggle */}
      <div className="fixed top-4 right-6 z-50">
        <LanguageToggle />
      </div>

      {/* Login card */}
      <main className="w-full max-w-md mx-4 z-10">
        <div className="glass-card rounded-2xl p-8 flex flex-col items-center space-y-6">

          {/* Branding */}
          <div className="text-center space-y-2">
            <div className="flex items-center justify-center gap-2">
              <span className="text-3xl">&#x1F931;</span>
              <h1 className="text-3xl font-bold tracking-tight text-indigo-600">
                {t('app_name')}
              </h1>
            </div>
            <p className="text-sm text-gray-500 italic">{t('tagline')}</p>
          </div>

          {/* Illustration */}
          <div className="w-full aspect-video rounded-xl overflow-hidden bg-gray-50 border border-gray-200">
            <img
              className="w-full h-full object-cover opacity-90"
              src="https://lh3.googleusercontent.com/aida-public/AB6AXuCHkjawZ8dk6oa8qn42p5OtwYG81apPGiaqBaUWgmv-WHFXq5_xKnuFKlCNR7_6JiXzuoutVSqHSeZRxXz4g5ehd0_U7C-s_Uo-Hj88RVWGScPMWwxCzUIJ0GvhCkrYe_93qpv7WmJMfSj3GSGsIgsCH6SWea7kJGumT7oIskoYvKfP4Yfiiz36h32mYvwfTz7ZSsP6NvF1dciGwButkmgDh_WFUF43Lx7tBS5JFxgYmbHwkzDRlyhuptW8VCVtyAOpisrCpQV-E4c"
              alt="Maternal care illustration"
            />
          </div>

          {/* Error message */}
          {error && (
            <div className="w-full bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3 text-center">
              {error}
            </div>
          )}

          {/* Form */}
          <form onSubmit={handleSubmit} className="w-full space-y-4">
            {/* Username */}
            <div className="space-y-1">
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider ml-1"
                htmlFor="username">
                {t('username')}
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">
                  person
                </span>
                <input
                  id="username"
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Health Worker ID"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-white border border-gray-200 rounded-xl text-sm text-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 input-glow transition-all"
                />
              </div>
            </div>

            {/* Password */}
            <div className="space-y-1">
              <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider ml-1"
                htmlFor="password">
                {t('password')}
              </label>
              <div className="relative">
                <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">
                  lock
                </span>
                <input
                  id="password"
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;&#8226;"
                  required
                  className="w-full pl-10 pr-10 py-3 bg-white border border-gray-200 rounded-xl text-sm text-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 input-glow transition-all"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-indigo-600 transition-colors"
                  tabIndex={-1}
                >
                  <span className="material-symbols-outlined text-xl">
                    {showPassword ? 'visibility_off' : 'visibility'}
                  </span>
                </button>
              </div>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-indigo-600 text-white font-semibold rounded-xl shadow-lg hover:bg-indigo-700 active:scale-[0.98] transition-all flex items-center justify-center gap-2 group disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="material-symbols-outlined text-xl animate-spin">
                  progress_activity
                </span>
              ) : (
                <>
                  <span>{t('login')}</span>
                  <span className="material-symbols-outlined text-lg group-hover:translate-x-1 transition-transform">
                    login
                  </span>
                </>
              )}
            </button>
          </form>

          {/* Footer credit */}
          <footer className="pt-2 text-center">
            <p className="text-xs font-semibold text-gray-400 tracking-wider uppercase">
              Developing Innovative Professionals &mdash; YIBS
            </p>
          </footer>
        </div>
      </main>
    </div>
  );
}
