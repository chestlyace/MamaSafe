import { useTranslation } from 'react-i18next';

export default function ReferralCard({ referral }) {
  const { t } = useTranslation();
  const created = new Date(referral.created_at).toLocaleString();
  const statusColors = {
    sent: 'bg-yellow-100 text-yellow-800',
    received: 'bg-blue-100 text-blue-800',
    patient_arrived: 'bg-green-100 text-green-800',
  };

  return (
    <div className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100 space-y-2">
      <div className="flex items-center justify-between">
        <span className="font-semibold text-gray-800 text-sm">
          {referral.patient_name}
        </span>
        <span
          className={`text-xs font-medium px-2 py-1 rounded-full ${
            statusColors[referral.status] || 'bg-gray-100 text-gray-600'
          }`}
        >
          {referral.status.replace('_', ' ').toUpperCase()}
        </span>
      </div>

      <p className="text-xs text-gray-500">
        <span className="material-symbols-outlined text-[14px] align-middle mr-1">local_hospital</span>
        {referral.facility_name || 'Unknown facility'}
      </p>

      <p className="text-xs text-gray-500">
        <span className="material-symbols-outlined text-[14px] align-middle mr-1">description</span>
        {referral.clinical_summary}
      </p>

      <div className="flex items-center justify-between text-xs text-gray-400">
        <span>{referral.delivery_method.toUpperCase()}</span>
        <span>{created}</span>
      </div>
    </div>
  );
}
