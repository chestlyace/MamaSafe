const FEATURES = [
  { key: 'systolic_bp',  label: 'Systolic BP',  unit: 'mmHg',   danger: (v) => v >= 140 },
  { key: 'diastolic_bp', label: 'Diastolic BP', unit: 'mmHg',   danger: (v) => v >= 90 },
  { key: 'blood_sugar',  label: 'Blood Sugar',  unit: 'mmol/L', danger: (v) => v >= 11 },
  { key: 'body_temp',    label: 'Body Temp',    unit: '°F',     danger: (v) => v >= 101 },
  { key: 'heart_rate',   label: 'Heart Rate',   unit: 'bpm',    danger: (v) => v >= 90 },
];

export default function FeatureTrendTable({ assessments }) {
  if (!assessments || assessments.length < 2) return null;

  return (
    <div className="bg-white rounded-2xl border border-border p-5">
      <h3 className="font-bold text-text-heading text-sm mb-4">
        Clinical Feature Trends
      </h3>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-border">
              <th className="text-left text-[11px] text-text-muted font-medium pb-2 pr-4">
                Feature
              </th>
              {assessments.map((a, i) => (
                <th key={a.id} className="text-center text-[11px] text-text-muted font-medium pb-2 px-2">
                  Visit {i + 1}
                  <br />
                  <span className="text-text-muted/50 font-normal">{a.date}</span>
                </th>
              ))}
              <th className="text-center text-[11px] text-text-muted font-medium pb-2 px-2">
                Change
              </th>
            </tr>
          </thead>
          <tbody>
            {FEATURES.map((feat) => {
              const values = assessments.map((a) => a[feat.key]);
              const first = values[0];
              const last = values[values.length - 1];
              const change = last !== null && first !== null
                ? (last - first).toFixed(1)
                : null;
              const isRising = change > 0;
              const isDanger = last !== null && feat.danger(last);

              return (
                <tr key={feat.key} className="border-b border-border/50 last:border-0">
                  <td className="py-2 pr-4 font-medium text-text-heading text-xs whitespace-nowrap">
                    {feat.label}
                    <span className="text-text-muted ml-1">({feat.unit})</span>
                  </td>
                  {assessments.map((a, i) => {
                    const val = a[feat.key];
                    const danger = val !== null && feat.danger(val);
                    return (
                      <td key={i} className="text-center py-2 px-2 text-xs">
                        <span className={`font-medium ${danger ? 'text-red-600' : 'text-text-heading'}`}>
                          {val !== null ? val : '—'}
                        </span>
                      </td>
                    );
                  })}
                  <td className="text-center py-2 px-2">
                    {change !== null ? (
                      <span className={`text-xs font-bold ${
                        isRising
                          ? isDanger ? 'text-red-600' : 'text-amber-600'
                          : 'text-green-600'
                      }`}>
                        {isRising ? '↑' : '↓'} {Math.abs(change)}
                      </span>
                    ) : '—'}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
