import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { predict } from '../api/client';

export default function AssessmentPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    patient_ref: '',
    age: '',
    systolic_bp: '',
    diastolic_bp: '',
    blood_sugar: '',
    body_temp: '',
    heart_rate: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const update = (key, val) => setForm((prev) => ({ ...prev, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    try {
      const payload = {};
      if (form.patient_ref) payload.patient_ref = form.patient_ref;
      Object.keys(form).forEach((k) => {
        if (k !== 'patient_ref' && form[k] !== '') {
          payload[k] = parseFloat(form[k]);
        }
      });

      const data = await predict(payload);
      navigate('/result', { state: data });
    } catch {
      setError(t('error'));
    } finally {
      setSubmitting(false);
    }
  };

  const inputBase =
    'w-full p-3 bg-white border border-gray-200 rounded-xl text-sm text-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all';

  return (
    <main className="max-w-[800px] mx-auto px-4 md:px-0 pt-6 pb-24">
      {/* Header */}
      <header className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-1">{t('new_assessment')}</h1>
        <p className="text-base text-gray-500">Enter patient clinical data for risk analysis</p>
      </header>

      {/* Patient Reference */}
      <div className="mb-8">
        <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1 ml-1"
          htmlFor="patient_ref">
          {t('patient_ref')}
        </label>
        <div className="relative">
          <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-xl">
            badge
          </span>
          <input
            id="patient_ref"
            type="text"
            value={form.patient_ref}
            onChange={(e) => update('patient_ref', e.target.value)}
            placeholder="Enter patient ID or name"
            className="w-full pl-10 pr-4 py-3 bg-white border border-gray-200 rounded-xl text-sm text-gray-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-all"
          />
        </div>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3 text-center">
          {error}
        </div>
      )}

      {/* Form Card */}
      <form onSubmit={handleSubmit}>
        <div className="bg-white rounded-2xl p-6 md:p-8 border border-gray-100 shadow-[0_4px_12px_rgba(0,0,0,0.05)]">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-y-5 gap-x-6">
            {/* Age */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('age')}
              </label>
              <input
                type="number"
                min="10"
                max="60"
                step="any"
                value={form.age}
                onChange={(e) => update('age', e.target.value)}
                placeholder="25"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 10 - 60</span>
            </div>

            {/* Systolic BP */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('systolic_bp')}
              </label>
              <input
                type="number"
                min="70"
                max="200"
                step="any"
                value={form.systolic_bp}
                onChange={(e) => update('systolic_bp', e.target.value)}
                placeholder="120"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 70 - 200</span>
            </div>

            {/* Diastolic BP */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('diastolic_bp')}
              </label>
              <input
                type="number"
                min="40"
                max="120"
                step="any"
                value={form.diastolic_bp}
                onChange={(e) => update('diastolic_bp', e.target.value)}
                placeholder="80"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 40 - 120</span>
            </div>

            {/* Blood Sugar */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('blood_sugar')}
              </label>
              <input
                type="number"
                min="4"
                max="25"
                step="0.1"
                value={form.blood_sugar}
                onChange={(e) => update('blood_sugar', e.target.value)}
                placeholder="7.0"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 4 - 25</span>
            </div>

            {/* Body Temperature */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('body_temp')}
              </label>
              <input
                type="number"
                min="95"
                max="105"
                step="0.1"
                value={form.body_temp}
                onChange={(e) => update('body_temp', e.target.value)}
                placeholder="98.6"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 95 - 105</span>
            </div>

            {/* Heart Rate */}
            <div className="flex flex-col gap-1">
              <label className="text-xs font-semibold text-gray-500 uppercase tracking-wider">
                {t('heart_rate')}
              </label>
              <input
                type="number"
                min="40"
                max="100"
                step="any"
                value={form.heart_rate}
                onChange={(e) => update('heart_rate', e.target.value)}
                placeholder="72"
                required
                className={inputBase}
              />
              <span className="text-xs text-gray-400">Range: 40 - 100</span>
            </div>
          </div>

          {/* Submit */}
          <div className="mt-8">
            <button
              type="submit"
              disabled={submitting}
              className="w-full bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 rounded-xl shadow-lg transition-all active:scale-[0.98] flex justify-center items-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {submitting ? (
                <>
                  <span className="material-symbols-outlined text-xl animate-spin">
                    progress_activity
                  </span>
                  <span>{t('assessing')}</span>
                </>
              ) : (
                <>
                  <span className="material-symbols-outlined text-xl"
                    style={{ fontVariationSettings: "'FILL' 1" }}>
                    analytics
                  </span>
                  <span>{t('assess_risk')}</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Disclaimer */}
        <div className="mt-6 p-4 bg-gray-50 rounded-xl flex items-start gap-3">
          <span className="material-symbols-outlined text-amber-600 mt-0.5">info</span>
          <p className="text-sm text-gray-500">
            This clinical assessment tool is designed for healthcare professionals.
            Please ensure all data points are verified before submitting for risk analysis.
          </p>
        </div>
      </form>
    </main>
  );
}
