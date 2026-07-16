import { useState, useEffect } from 'react';
import { getFacilities } from '../api/client';
import { useTranslation } from 'react-i18next';

export default function FacilityPicker({ value, onChange, placeholder }) {
  const { t } = useTranslation();
  const [facilities, setFacilities] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getFacilities()
      .then(setFacilities)
      .catch(() => setFacilities([]))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <div className="text-sm text-gray-400">{t('loading')}</div>;

  return (
    <select
      value={value || ''}
      onChange={(e) => onChange(e.target.value || null)}
      className="w-full p-3 rounded-xl border border-gray-200 text-sm focus:outline-none focus:ring-2 focus:ring-rose-300"
    >
      <option value="">{placeholder || t('select_facility')}</option>
      {facilities.map((f) => (
        <option key={f.id} value={f.id}>
          {f.name} — {f.facility_type}
        </option>
      ))}
      <option value="__other__">{t('other_facility')}</option>
    </select>
  );
}
