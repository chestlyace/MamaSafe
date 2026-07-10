import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { predict } from '../api/client';

const FIELDS = [
  { key: 'patient_ref', type: 'text', optional: true },
  { key: 'age', min: 10, max: 70 },
  { key: 'systolic_bp', min: 70, max: 180 },
  { key: 'diastolic_bp', min: 40, max: 120 },
  { key: 'blood_sugar', min: 4, max: 25 },
  { key: 'body_temp', min: 95, max: 105 },
  { key: 'heart_rate', min: 40, max: 100 },
];

export default function AssessmentPage() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [form, setForm] = useState({
    patient_ref: '', age: '', systolic_bp: '', diastolic_bp: '',
    blood_sugar: '', body_temp: '', heart_rate: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');

  const update = (key, val) => setForm((prev) => ({ ...prev, [key]: val }));

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError('');

    try {
      const payload = { ...form };
      delete payload.patient_ref;
      if (form.patient_ref) payload.patient_ref = form.patient_ref;
      Object.keys(payload).forEach((k) => {
        if (k !== 'patient_ref') payload[k] = parseFloat(payload[k]);
      });

      const data = await predict(payload);
      navigate('/result', { state: data });
    } catch {
      setError('Assessment failed. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  const inputClass = 'w-full border rounded px-3 py-2 text-sm';

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold mb-6">{t('assessment.title')}</h1>

      {error && <p className="text-red-500 text-sm mb-3">{error}</p>}

      <form onSubmit={handleSubmit} className="bg-white rounded-lg shadow p-6 space-y-4">
        {FIELDS.map((f) => (
          <div key={f.key}>
            <label className="block text-sm font-medium mb-1">
              {t(`assessment.${f.key}`)}
              {f.min !== undefined && (
                <span className="text-gray-400 ml-1">({f.min}–{f.max})</span>
              )}
            </label>
            <input
              type={f.type || 'number'}
              step={f.type === 'text' ? undefined : 'any'}
              value={form[f.key]}
              onChange={(e) => update(f.key, e.target.value)}
              required={!f.optional}
              min={f.min}
              max={f.max}
              className={inputClass}
            />
          </div>
        ))}

        <button
          type="submit"
          disabled={submitting}
          className="w-full bg-indigo-600 text-white rounded py-2 text-sm font-medium hover:bg-indigo-700 disabled:opacity-50 transition-colors"
        >
          {submitting ? t('assessment.submitting') : t('assessment.submit')}
        </button>
      </form>
    </div>
  );
}
