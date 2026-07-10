import { useLocation, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import RiskBadge from '../components/RiskBadge';
import SHAPChart from '../components/SHAPChart';

export default function ResultPage() {
  const { t } = useTranslation();
  const { state } = useLocation();

  if (!state) {
    return (
      <div className="text-center py-12">
        <p className="text-gray-500 mb-4">No result data.</p>
        <Link to="/assess" className="text-indigo-600 hover:underline">
          {t('result.newAssessment')}
        </Link>
      </div>
    );
  }

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold mb-6">{t('result.title')}</h1>

      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <span className="text-sm text-gray-500">{t('result.riskLevel')}</span>
          <RiskBadge level={state.risk_level} />
        </div>

        <div className="flex items-center justify-between mb-4">
          <span className="text-sm text-gray-500">{t('result.confidence')}</span>
          <span className="font-medium">{(state.confidence * 100).toFixed(1)}%</span>
        </div>

        <div className="border-t pt-4 mt-4">
          <p className="text-sm text-gray-500 mb-1">{t('result.recommendation')}</p>
          <p className="text-sm">{state.recommendation}</p>
        </div>

        <SHAPChart values={state.shap_values} />
      </div>

      <div className="flex gap-3 mt-6">
        <Link
          to="/assess"
          className="flex-1 text-center bg-indigo-600 text-white rounded py-2 text-sm font-medium hover:bg-indigo-700 transition-colors"
        >
          {t('result.newAssessment')}
        </Link>
        <Link
          to="/history"
          className="flex-1 text-center border border-gray-300 rounded py-2 text-sm font-medium hover:bg-gray-50 transition-colors"
        >
          {t('result.backToHistory')}
        </Link>
      </div>
    </div>
  );
}
