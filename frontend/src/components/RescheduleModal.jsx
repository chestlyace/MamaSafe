import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { rescheduleVisit } from '../api/client';

export default function RescheduleModal({ visit, onClose, onRescheduled }) {
  const { t } = useTranslation();
  const [newDate, setNewDate] = useState('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!newDate) {
      setError(t('select_date'));
      return;
    }
    setLoading(true);
    setError('');
    try {
      await rescheduleVisit(visit.id, newDate, reason || null);
      onRescheduled();
    } catch (err) {
      setError(err.response?.data?.detail || t('reschedule_failed'));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md p-6">
        <div className="flex items-center justify-between mb-5">
          <h3 className="text-lg font-bold text-gray-800">{t('reschedule_visit')}</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        <div className="bg-indigo-50 rounded-xl p-3 mb-4">
          <p className="text-sm font-medium text-indigo-800">
            {t('visit_number')} {visit.visit_number} — {visit.label}
          </p>
          <p className="text-xs text-indigo-600 mt-1">
            {t('currently_scheduled')}: {new Date(visit.scheduled_date).toLocaleDateString('en-GB', {
              day: 'numeric', month: 'long', year: 'numeric'
            })}
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1">
              {t('new_date')}
            </label>
            <input
              type="date"
              value={newDate}
              onChange={(e) => setNewDate(e.target.value)}
              min={new Date().toISOString().split('T')[0]}
              className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-400 focus:border-indigo-400 outline-none"
            />
          </div>

          <div>
            <label className="block text-sm font-semibold text-gray-700 mb-1">
              {t('reason_optional')}
            </label>
            <input
              type="text"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              placeholder={t('reschedule_reason_placeholder')}
              className="w-full border border-gray-300 rounded-xl px-4 py-2.5 text-sm focus:ring-2 focus:ring-indigo-400 focus:border-indigo-400 outline-none"
            />
          </div>

          {error && (
            <p className="text-red-500 text-sm">{error}</p>
          )}

          <div className="flex gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 rounded-xl text-sm font-semibold border border-gray-300 text-gray-600 hover:bg-gray-50 transition-colors"
            >
              {t('cancel')}
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 px-4 py-2.5 rounded-xl text-sm font-semibold bg-indigo-500 text-white hover:bg-indigo-600 transition-colors disabled:opacity-50"
            >
              {loading ? t('saving') : t('confirm_reschedule')}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
