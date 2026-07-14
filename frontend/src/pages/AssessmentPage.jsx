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
        if (k !== 'patient_ref' && form[k] !== '') payload[k] = parseFloat(form[k]);
      });
      const data = await predict(payload);
      navigate('/result', { state: data });
    } catch {
      setError(t('error'));
    } finally {
      setSubmitting(false);
    }
  };

  const fields = [
    { key: 'age', min: 10, max: 60, step: 'any', placeholder: '25', icon: 'cake' },
    { key: 'systolic_bp', min: 70, max: 200, step: 'any', placeholder: '120', icon: 'monitor_heart' },
    { key: 'diastolic_bp', min: 40, max: 120, step: 'any', placeholder: '80', icon: 'favorite' },
    { key: 'blood_sugar', min: 4, max: 25, step: 0.1, placeholder: '7.0', icon: 'water_drop' },
    { key: 'body_temp', min: 95, max: 105, step: 0.1, placeholder: '98.6', icon: 'thermostat' },
    { key: 'heart_rate', min: 40, max: 100, step: 'any', placeholder: '72', icon: 'ecg' },
  ];

  const inputClass =
    'w-full pl-10 pr-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all';

  return (
    <main className="max-w-[720px] mx-auto px-5 pt-8 pb-24 md:pb-8">
      {/* Header */}
      <header className="mb-8">
        <h1 className="text-2xl font-bold text-text-heading tracking-tight">{t('new_assessment')}</h1>
        <p className="text-sm text-text-muted mt-1">{t('enter_patient_data')}</p>
      </header>

      {/* Error */}
      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        {/* Patient Reference */}
        <div className="mb-6">
          <label htmlFor="patient_ref" className="block text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
            {t('patient_ref')}
          </label>
          <div className="relative">
            <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-text-muted text-[20px]">
              badge
            </span>
            <input
              id="patient_ref"
              type="text"
              value={form.patient_ref}
              onChange={(e) => update('patient_ref', e.target.value)}
              placeholder={t('enter_patient_id')}
              className={inputClass}
            />
          </div>
        </div>

        {/* Clinical Fields */}
        <div className="bg-white rounded-2xl border border-border p-5 sm:p-6 mb-6">
          <h2 className="text-sm font-semibold text-text-heading mb-5">{t('enter_patient_data')}</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {fields.map((f) => (
              <div key={f.key}>
                <label className="block text-xs font-medium text-text-muted mb-1.5">
                  {t(f.key)}
                </label>
                <div className="relative">
                  <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-[18px]">
                    {f.icon}
                  </span>
                  <input
                    type="number"
                    min={f.min}
                    max={f.max}
                    step={f.step}
                    value={form[f.key]}
                    onChange={(e) => update(f.key, e.target.value)}
                    placeholder={f.placeholder}
                    required
                    className="w-full pl-10 pr-4 py-2.5 bg-surface border border-border rounded-xl text-sm text-text-heading placeholder:text-text-muted/50 focus:outline-none focus:ring-2 focus:ring-rose-primary/30 focus:border-rose-primary transition-all"
                  />
                </div>
                <span className="text-[11px] text-text-muted mt-1 block">
                  {f.min} – {f.max}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={submitting}
          className="w-full py-3.5 bg-rose-500 text-white text-sm font-semibold rounded-xl hover:bg-rose-600 active:scale-[0.98] transition-all flex items-center justify-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {submitting ? (
            <>
              <span className="material-symbols-outlined text-xl animate-spin">progress_activity</span>
              <span>{t('assessing')}</span>
            </>
          ) : (
            <>
              <span className="material-symbols-outlined text-[20px]" style={{ fontVariationSettings: "'FILL' 1" }}>analytics</span>
              <span>{t('assess_risk')}</span>
            </>
          )}
        </button>

        {/* Disclaimer */}
        <div className="mt-5 flex items-start gap-2.5 px-1">
          <span className="material-symbols-outlined text-amber-500 text-[18px] mt-0.5">info</span>
          <p className="text-xs text-text-muted leading-relaxed">
            {t('clinical_summary')}
          </p>
        </div>
      </form>
    </main>
  );
}
