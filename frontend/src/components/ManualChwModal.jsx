import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { createChw, getMe } from '../api/client';

export default function ManualChwModal({ open, onClose, onSuccess }) {
  const { t } = useTranslation();
  const [fullName, setFullName] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [facility, setFacility] = useState('');
  const [district, setDistrict] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const inputClass = 'px-3 py-2 bg-surface border border-border rounded-lg text-sm text-text-heading w-full';

  useEffect(() => {
    if (open) {
      getMe().then((user) => {
        if (user.district) setDistrict(user.district);
      }).catch(() => {});
    }
  }, [open]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccess('');
    try {
      await createChw({
        username,
        password,
        full_name: fullName,
        facility: facility || undefined,
        district: district || undefined,
      });
      setSuccess(t('chw_created_successfully'));
      onSuccess?.();
      setFullName('');
      setUsername('');
      setPassword('');
      setFacility('');
      setDistrict('');
      setTimeout(() => {
        setSuccess('');
        onClose();
      }, 1500);
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setLoading(false);
    }
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center" onClick={onClose}>
      <div className="bg-white rounded-2xl max-w-md w-full p-6" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between mb-5">
          <h2 className="text-lg font-bold text-text-heading">{t('add_chw_manually')}</h2>
          <button onClick={onClose} className="text-text-muted hover:text-text-heading transition-colors">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        {success && (
          <div className="mb-4 p-3 bg-green-50 border border-green-200 rounded-lg text-sm text-green-700">
            {success}
          </div>
        )}

        {error && (
          <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded-lg text-sm text-red-700">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-text-muted mb-1.5">{t('full_name')}</label>
            <input
              type="text"
              required
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              className={inputClass}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-text-muted mb-1.5">{t('username')}</label>
            <input
              type="text"
              required
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              className={inputClass}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-text-muted mb-1.5">{t('temporary_password')}</label>
            <div className="relative">
              <input
                type={showPassword ? 'text' : 'password'}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={`${inputClass} pr-10`}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-heading"
              >
                <span className="material-symbols-outlined text-[20px]">
                  {showPassword ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-text-muted mb-1.5">{t('facility')}</label>
            <input
              type="text"
              value={facility}
              onChange={(e) => setFacility(e.target.value)}
              className={inputClass}
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-text-muted mb-1.5">{t('district')}</label>
            <input
              type="text"
              value={district}
              onChange={(e) => setDistrict(e.target.value)}
              className={inputClass}
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-rose-500 text-white py-2.5 rounded-lg text-sm font-semibold hover:bg-rose-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {loading ? (
              <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>
            ) : (
              t('create_chw')
            )}
          </button>

          <button
            type="button"
            onClick={onClose}
            className="w-full bg-gray-100 text-text-heading py-2.5 rounded-lg text-sm font-semibold hover:bg-gray-200 transition-colors"
          >
            {t('cancel')}
          </button>
        </form>
      </div>
    </div>
  );
}
