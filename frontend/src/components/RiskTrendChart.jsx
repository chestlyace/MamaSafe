import {
  LineChart, Line, XAxis, YAxis, CartesianGrid,
  Tooltip, ReferenceLine, ResponsiveContainer,
} from 'recharts';

const RISK_LABELS = { 1: 'Low', 2: 'Mid', 3: 'High' };
const RISK_COLORS = { 1: '#22C55E', 2: '#F59E0B', 3: '#EF4444' };

const CustomDot = ({ cx, cy, payload }) => {
  const color = RISK_COLORS[payload.risk_numeric] || '#6366F1';
  return (
    <circle cx={cx} cy={cy} r={6} fill={color} stroke="white" strokeWidth={2} />
  );
};

const CustomTooltip = ({ active, payload }) => {
  if (!active || !payload?.length) return null;
  const d = payload[0].payload;
  return (
    <div className="bg-white border border-gray-200 rounded-xl p-3 shadow-lg text-sm">
      <p className="font-bold text-gray-800 mb-1">{d.date}</p>
      <p className="font-semibold" style={{ color: RISK_COLORS[d.risk_numeric] }}>
        {d.risk_level?.toUpperCase()}
      </p>
      <p className="text-gray-500 text-xs">
        Confidence: {Math.round(d.confidence * 100)}%
      </p>
      {d.systolic_bp && (
        <p className="text-gray-500 text-xs">SBP: {d.systolic_bp} mmHg</p>
      )}
      {d.blood_sugar && (
        <p className="text-gray-500 text-xs">BS: {d.blood_sugar} mmol/L</p>
      )}
    </div>
  );
};

export default function RiskTrendChart({ assessments, trend }) {
  if (!assessments || assessments.length === 0) {
    return (
      <div className="bg-white rounded-2xl border border-border p-6 text-center">
        <span className="material-symbols-outlined text-[40px] text-text-muted/30 mb-2">show_chart</span>
        <p className="text-text-muted text-sm">
          No assessments yet. Run the first assessment to begin tracking this patient's risk trend.
        </p>
      </div>
    );
  }

  const trendColor = trend === 'escalating' ? '#EF4444'
    : trend === 'improving' ? '#22C55E'
    : '#6366F1';

  const trendLabel = trend === 'escalating' ? '↑ Escalating'
    : trend === 'improving' ? '↓ Improving'
    : trend === 'stable' ? '→ Stable'
    : 'Insufficient data';

  return (
    <div className="bg-white rounded-2xl border border-border p-5">
      <div className="flex items-center justify-between mb-4">
        <h3 className="font-bold text-text-heading text-sm">Risk Trend</h3>
        <span
          className="text-xs font-semibold px-3 py-1 rounded-full"
          style={{ color: trendColor, background: trendColor + '18' }}
        >
          {trendLabel}
        </span>
      </div>

      <ResponsiveContainer width="100%" height={220}>
        <LineChart data={assessments} margin={{ top: 8, right: 16, left: 0, bottom: 0 }}>
          <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#F1F5F9" />
          <XAxis
            dataKey="date"
            tick={{ fontSize: 11 }}
            tickFormatter={(d) => {
              const date = new Date(d);
              return `${date.getDate()}/${date.getMonth() + 1}`;
            }}
          />
          <YAxis
            domain={[0.5, 3.5]}
            ticks={[1, 2, 3]}
            tickFormatter={(v) => RISK_LABELS[v] || ''}
            tick={{ fontSize: 10 }}
            width={40}
          />
          <Tooltip content={<CustomTooltip />} />
          <ReferenceLine y={2} stroke="#F59E0B" strokeDasharray="4 4" strokeOpacity={0.5} />
          <ReferenceLine y={3} stroke="#EF4444" strokeDasharray="4 4" strokeOpacity={0.5} />
          <Line
            type="monotone"
            dataKey="risk_numeric"
            stroke="#6366F1"
            strokeWidth={2.5}
            dot={<CustomDot />}
            activeDot={{ r: 8 }}
            name="Risk level"
          />
          <Line
            type="monotone"
            dataKey="confidence"
            stroke="#94A3B8"
            strokeWidth={1.5}
            strokeDasharray="4 4"
            dot={false}
            name="Confidence"
          />
        </LineChart>
      </ResponsiveContainer>

      <p className="text-xs text-text-muted mt-2 text-center">
        {assessments.length} assessment{assessments.length !== 1 ? 's' : ''} · Dashed line = confidence
      </p>
    </div>
  );
}
