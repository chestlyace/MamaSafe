import { useTranslation } from "react-i18next";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  Legend, ResponsiveContainer, ReferenceLine,
} from "recharts";

const PERCENTILE_LABELS = {
  below_3rd: "P3",
  "3rd_to_15th": "P15",
  "15th_to_50th": "P50",
  "50th_to_85th": "P85",
  "85th_to_97th": "P97",
  above_97th: ">P97",
};

export default function GrowthChart({ measurements, sex }) {
  const { t } = useTranslation();

  if (!measurements || measurements.length === 0) {
    return (
      <div className="flex items-center justify-center py-12 text-text-muted text-sm">
        {t("no_measurements")}
      </div>
    );
  }

  const data = measurements.map((m) => ({
    age_days: m.age_days,
    weight: Number(m.weight_kg.toFixed(2)),
    p3: Number(m.p3?.toFixed(2)),
    p15: Number(m.p15?.toFixed(2)),
    p50: Number(m.p50?.toFixed(2)),
    p85: Number(m.p85?.toFixed(2)),
    p97: Number(m.p97?.toFixed(2)),
    z: m.z_score?.toFixed(2),
  }));

  const TooltipContent = ({ active, payload, label }) => {
    if (!active || !payload) return null;
    return (
      <div className="bg-white rounded-lg border border-border shadow-lg p-3 text-xs">
        <p className="font-medium text-text-heading mb-1">
          {t("day")} {label}
        </p>
        {payload.map((entry, i) => (
          <p key={i} style={{ color: entry.color }} className="mb-0.5">
            {entry.name}: {entry.value} kg
          </p>
        ))}
      </div>
    );
  };

  return (
    <div className="w-full">
      <ResponsiveContainer width="100%" height={320}>
        <LineChart data={data} margin={{ top: 10, right: 20, left: 0, bottom: 10 }}>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis
            dataKey="age_days"
            tick={{ fontSize: 11, fill: "#6b7280" }}
            label={{ value: t("days_after_birth"), position: "insideBottom", offset: -5, style: { fontSize: 11, fill: "#6b7280" } }}
          />
          <YAxis
            tick={{ fontSize: 11, fill: "#6b7280" }}
            label={{ value: t("weight_kg"), angle: -90, position: "insideLeft", style: { fontSize: 11, fill: "#6b7280" } }}
            domain={["dataMin - 0.3", "dataMax + 0.3"]}
          />
          <Tooltip content={<TooltipContent />} />
          <Legend wrapperStyle={{ fontSize: 11 }} />

          <Line type="monotone" dataKey="p97" stroke="#d1d5db" strokeDasharray="4 2" dot={false} name="P97" />
          <Line type="monotone" dataKey="p85" stroke="#d1d5db" strokeDasharray="4 2" dot={false} name="P85" />
          <Line type="monotone" dataKey="p50" stroke="#9ca3af" strokeWidth={1} dot={false} name="P50" />
          <Line type="monotone" dataKey="p15" stroke="#d1d5db" strokeDasharray="4 2" dot={false} name="P15" />
          <Line type="monotone" dataKey="p3" stroke="#d1d5db" strokeDasharray="4 2" dot={false} name="P3" />

          <Line
            type="monotone"
            dataKey="weight"
            stroke="#e11d48"
            strokeWidth={2}
            dot={{ r: 4, fill: "#e11d48", strokeWidth: 0 }}
            activeDot={{ r: 6, fill: "#e11d48", strokeWidth: 2, stroke: "#fff" }}
            name={t("baby_weight")}
          />
        </LineChart>
      </ResponsiveContainer>

      <p className="text-[11px] text-text-muted mt-2 text-center">
        {t("who_percentile_reference")} ({sex === "male" ? t("male") : t("female")})
      </p>
    </div>
  );
}
