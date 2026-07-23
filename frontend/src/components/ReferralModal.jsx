import { useState } from 'react';
import { quickReferral } from '../api/client';
import FacilityPicker from './FacilityPicker';
import { useTranslation } from 'react-i18next';

const COMPLICATION_OPTIONS = [
  { value: 'hypertension', label: 'Hypertension' },
  { value: 'hemorrhage', label: 'Hemorrhage' },
  { value: 'eclampsia', label: 'Eclampsia' },
  { value: 'sepsis', label: 'Sepsis' },
  { value: 'obstruction', label: 'Obstruction' },
  { value: 'anemia', label: 'Anemia' },
  { value: 'other', label: 'Other' },
];

export default function ReferralModal({ patientId, patientName, assessmentId, onClose }) {
  const { t } = useTranslation();
  const [facilityId, setFacilityId] = useState(null);
  const [complicationType, setComplicationType] = useState('');
  const [chwNotes, setChwNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);

  const handleSubmit = async () => {
    if (!facilityId) return;
    setLoading(true);
    setError(null);
    try {
      await quickReferral({
        assessment_id: assessmentId,
        facility_id: parseInt(facilityId),
        complication_type: complicationType || null,
        chw_notes: chwNotes || null,
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
          <label className="text-xs font-medium text-gray-500 uppercase">{t('complication_type')}</label>
          <select
            value={complicationType}
            onChange={(e) => setComplicationType(e.target.value)}
            className="w-full p-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-rose-300"
          >
            <option value="">{t('select_complication')}</option>
            {COMPLICATION_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>

        <div className="space-y-1">
          <label className="text-xs font-medium text-gray-500 uppercase">{t('chw_notes')}</label>
          <textarea
            rows={3}
            value={chwNotes}
            onChange={(e) => setChwNotes(e.target.value)}
            placeholder={t('chw_notes_placeholder')}
            className="w-full p-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-rose-300 resize-none"
          />
        </div>

        <div className="bg-blue-50 text-blue-700 text-xs rounded-xl p-3 flex items-start gap-2">
          <span className="material-symbols-outlined text-[16px] mt-0.5">info</span>
          <span>{t('whatsapp_auto_note')}</span>
        </div>

        {error && (
          <div className="bg-red-50 text-red-700 text-xs rounded-xl p-3">{error}</div>
        )}

        <button
          onClick={handleSubmit}
          disabled={!facilityId || loading}
          className="w-full py-3 bg-rose-600 text-white rounded-xl font-semibold text-sm hover:bg-rose-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          {loading ? t('sending') : t('send_referral')}
        </button>
      </div>
    </div>
  );
}
