import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { login, register } from '../api/client';

export default function LoginPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [isRegister, setIsRegister] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');

    try {
      if (isRegister) {
        await register(username, password);
        setSuccess(t('auth.registerSuccess'));
        setIsRegister(false);
      } else {
        const data = await login(username, password);
        localStorage.setItem('token', data.access_token);
        navigate('/assess');
      }
    } catch {
      setError(t('auth.error'));
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="w-full max-w-sm bg-white rounded-lg shadow p-6">
        <h1 className="text-2xl font-bold text-center mb-1">{t('app.title')}</h1>
        <p className="text-center text-gray-500 text-sm mb-6">{t('app.subtitle')}</p>

        <h2 className="text-lg font-semibold mb-4">
          {isRegister ? t('auth.registerTitle') : t('auth.loginTitle')}
        </h2>

        {error && <p className="text-red-500 text-sm mb-3">{error}</p>}
        {success && <p className="text-green-600 text-sm mb-3">{success}</p>}

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="text"
            placeholder={t('auth.username')}
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
            className="w-full border rounded px-3 py-2 text-sm"
          />
          <input
            type="password"
            placeholder={t('auth.password')}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            className="w-full border rounded px-3 py-2 text-sm"
          />
          <button
            type="submit"
            className="w-full bg-indigo-600 text-white rounded py-2 text-sm font-medium hover:bg-indigo-700 transition-colors"
          >
            {isRegister ? t('auth.registerButton') : t('auth.loginButton')}
          </button>
        </form>

        <p className="text-center text-sm mt-4">
          {isRegister ? t('auth.hasAccount') : t('auth.noAccount')}{' '}
          <button
            onClick={() => { setIsRegister(!isRegister); setError(''); setSuccess(''); }}
            className="text-indigo-600 hover:underline"
          >
            {isRegister ? t('auth.loginButton') : t('auth.registerButton')}
          </button>
        </p>
      </div>
    </div>
  );
}
