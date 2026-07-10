import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from 'recharts';
import { getDashboardSummary } from '../api/client';

const COLORS = { high: '#ef4444', mid: '#f59e0b', low: '#22c55e' };

export default function DashboardPage() {
  const { t } = useTranslation();
  const [summary, setSummary] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getDashboardSummary()
      .then((data) => setSummary(data))
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="text-center py-12 text-gray-400">Loading...</div>;
  }

  if (!summary) {
    return <div className="text-center py-12 text-gray-500">Failed to load dashboard.</div>;
  }

  const pieData = [
    { name: t('dashboard.highRisk'), value: summary.high_risk_count, color: COLORS.high },
    { name: t('dashboard.midRisk'), value: summary.mid_risk_count, color: COLORS.mid },
    { name: t('dashboard.lowRisk'), value: summary.low_risk_count, color: COLORS.low },
  ].filter((d) => d.value > 0);

  return (
    <div>
      <h1 className="text-2xl font-bold mb-6">{t('dashboard.title')}</h1>

      <div className="grid grid-cols-1 sm:grid-cols-4 gap-4 mb-8">
        {[
          { label: t('dashboard.total'), value: summary.total_assessments, color: 'text-indigo-600' },
          { label: t('dashboard.highRisk'), value: summary.high_risk_count, color: 'text-red-600' },
          { label: t('dashboard.midRisk'), value: summary.mid_risk_count, color: 'text-amber-600' },
          { label: t('dashboard.lowRisk'), value: summary.low_risk_count, color: 'text-green-600' },
        ].map((card) => (
          <div key={card.label} className="bg-white rounded-lg shadow p-4 text-center">
            <p className={`text-3xl font-bold ${card.color}`}>{card.value}</p>
            <p className="text-sm text-gray-500 mt-1">{card.label}</p>
          </div>
        ))}
      </div>

      {pieData.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold mb-4">Risk Distribution</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={100} label>
                {pieData.map((entry, idx) => (
                  <Cell key={idx} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}
