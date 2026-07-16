import { useState } from 'react';
import { quickReferral } from '../api/client';
import FacilityPicker from './FacilityPicker';
import { useTranslation } from 'react-i18next';

export default function ReferralModal({ patientId, patientName, assessmentId, onClose }) {
  const { t } = useTranslation();
  const [facilityId, setFacilityId] = useState(null);
  const [clinicalSummary, setClinicalSummary] = useState('');
  const [deliveryMethod, setDeliveryMethod] = useState('sms');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async () => {
    if (!clinicalSummary.trim()) return;
    setLoading(true);
    setError(null);
    try {
      await quickReferral({
        patient_id: patientId,
        assessment_id: assessmentId,
        facility_id: facilityId || null,
        clinical_summary: clinicalSummary,
        delivery_method: deliveryMethod,
      });
      setSuccess(true);
    } catch (err) {
      setError(err.response?.data?.detail || t('error'));
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
        <div className="bg-white rounded-2xl p-8 max-w-sm w-full text-center space-y-4">
          <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto">
            <span className="material-symbols-outlined text-green-600 text-3xl">check_circle</span>
          </div>
          <h2 className="text-lg font-bold text-gray-800">{t('referral_sent')}</h2>
          <p className="text-sm text-gray-500">{t('referral_sent_desc')}</p>
          <button
            onClick={onClose}
            className="w-full py-3 bg-green-600 text-white rounded-xl font-semibold text-sm hover:bg-green-700 transition-colors"
          >
            {t('close')}
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl p-6 max-w-md w-full space-y-4 max-h-[85vh] overflow-y-auto">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-gray-800">{t('emergency_referral')}</h2>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600">
            <span className="material-symbols-outlined">close</span>
          </button>
        </div>

        {patientName && (
          <p className="text-sm text-gray-600">
            {t('referring_patient')}: <strong>{patientName}</strong>
          </p>
        )}

        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-500 uppercase">{t('select_facility')}</label>
          <FacilityPicker value={facilityId} onChange={setFacilityId} />
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-500 uppercase">{t('clinical_summary')}</label>
          <textarea
            rows={3}
            value={clinicalSummary}
            onChange={(e) => setClinicalSummary(e.target.value)}
            placeholder={t('clinical_summary_placeholder')}
            className="w-full p-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-rose-300 resize-none"
          />
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-500 uppercase">{t('send_via')}</label>
          <div className="grid grid-cols-3 gap-2">
            {['sms', 'whatsapp', 'app'].map((m) => (
              <button
                key={m}
                onClick={() => setDeliveryMethod(m)}
                className={`py-2 rounded-xl text-xs font-semibold uppercase border transition-colors ${
                  deliveryMethod === m
                    ? 'bg-rose-600 text-white border-rose-600'
                    : 'bg-white text-gray-600 border-gray-200 hover:border-rose-300'
                }`}
              >
                {m === 'app' ? t('in_app') : m}
              </button>
            ))}
          </div>
        </div>

        {error && (
          <div className="bg-red-50 text-red-700 text-xs rounded-xl p-3">{error}</div>
        )}

        <button
          onClick={handleSubmit}
          disabled={!clinicalSummary.trim() || loading}
          className="w-full py-3 bg-rose-600 text-white rounded-xl font-semibold text-sm hover:bg-rose-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? t('sending') : t('send_referral')}
        </button>
      </div>
    </div>
  );
}
