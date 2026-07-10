import { useTranslation } from 'react-i18next';
import {
  BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, Cell,
} from 'recharts';

const BAR_COLORS = { positive: '#ef4444', negative: '#3b82f6' };

export default function SHAPChart({ values }) {
  const { t } = useTranslation();
  if (!values?.length) return null;

  const data = values.map((v) => ({
    name: v.feature,
    value: v.shap_value,
    raw: v.raw_value,
  }));

  return (
    <div className="mt-6">
      <h3 className="text-lg font-semibold mb-3">{t('result.shapTitle')}</h3>
      <ResponsiveContainer width="100%" height={300}>
        <BarChart data={data} layout="vertical" margin={{ left: 20 }}>
          <XAxis type="number" />
          <YAxis dataKey="name" type="category" width={100} />
          <Tooltip
            formatter={(val) => [val.toFixed(4), 'SHAP']}
          />
          <Bar dataKey="value" radius={[0, 4, 4, 0]}>
            {data.map((entry, idx) => (
              <Cell
                key={idx}
                fill={entry.value >= 0 ? BAR_COLORS.positive : BAR_COLORS.negative}
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
