import { useTranslation } from "react-i18next";

const CLASSIFICATION_COLORS = {
  severely_underweight: "bg-red-100 text-red-700 border-red-200",
  underweight: "bg-amber-100 text-amber-700 border-amber-200",
  normal: "bg-green-100 text-green-700 border-green-200",
  overweight: "bg-blue-100 text-blue-700 border-blue-200",
  obese: "bg-purple-100 text-purple-700 border-purple-200",
};

const PERCENTILE_LABELS = {
  below_3rd: "< P3",
  "3rd_to_15th": "P3–P15",
  "15th_to_50th": "P15–P50",
  "50th_to_85th": "P50–P85",
  "85th_to_97th": "P85–P97",
  above_97th: "> P97",
};

export default function GrowthStatus({ classification, percentile, zScore, weightKg, ageDays }) {
  const { t } = useTranslation();

  const colorClass = CLASSIFICATION_COLORS[classification] || "bg-gray-100 text-gray-700 border-gray-200";

  return (
    <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-full border text-xs font-medium ${colorClass}`}>
      <span>{PERCENTILE_LABELS[percentile] || percentile}</span>
      <span className="opacity-50">|</span>
      <span>{t(classification)}</span>
      {zScore != null && (
        <>
          <span className="opacity-50">|</span>
          <span>z: {zScore}</span>
        </>
      )}
    </div>
  );
}
