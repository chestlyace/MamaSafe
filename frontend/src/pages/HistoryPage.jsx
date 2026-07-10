import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { getAssessments } from '../api/client';
import RiskBadge from '../components/RiskBadge';

export default function HistoryPage() {
  const { t } = useTranslation();
  const [assessments, setAssessments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getAssessments()
      .then((data) => setAssessments(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="text-center py-12 text-gray-400">Loading...</div>;
  }

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">{t('history.title')}</h1>

      {assessments.length === 0 ? (
        <p className="text-gray-500">{t('history.empty')}</p>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="text-left px-4 py-3">{t('history.date')}</th>
                <th className="text-left px-4 py-3">{t('history.patient')}</th>
                <th className="text-left px-4 py-3">{t('history.risk')}</th>
                <th className="text-right px-4 py-3"></th>
              </tr>
            </thead>
            <tbody>
              {assessments.map((a) => (
                <tr key={a.id} className="border-b last:border-0 hover:bg-gray-50">
                  <td className="px-4 py-3">
                    {new Date(a.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-4 py-3">{a.patient_ref || '—'}</td>
                  <td className="px-4 py-3">
                    <RiskBadge level={a.risk_level} />
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Link
                      to="/result"
                      state={{
                        risk_level: a.risk_level,
                        confidence: a.prob_high,
                        recommendation: '',
                        shap_values: [],
                        assessment_id: a.id,
                      }}
                      className="text-indigo-600 hover:underline"
                    >
                      {t('history.view')}
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
