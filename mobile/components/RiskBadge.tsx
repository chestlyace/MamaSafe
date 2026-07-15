import { View, Text } from "react-native";
import { useTranslation } from "react-i18next";

const STYLES = {
  high: { bg: "bg-red-100", text: "text-red-800", dot: "bg-red-500", i18nKey: "high_risk" as const },
  mid: { bg: "bg-amber-100", text: "text-amber-800", dot: "bg-amber-500", i18nKey: "moderate_risk" as const },
  low: { bg: "bg-green-100", text: "text-green-800", dot: "bg-green-500", i18nKey: "low_risk" as const },
};

function riskKey(level: string) {
  if (level === "high risk") return "high";
  if (level === "mid risk") return "mid";
  return "low";
}

export default function RiskBadge({ level }: { level: string }) {
  const { t } = useTranslation();
  const key = riskKey(level);
  const s = STYLES[key];
  return (
    <View className={`flex-row items-center gap-1.5 px-3 py-1 rounded-full ${s.bg}`}>
      <View className={`w-1.5 h-1.5 rounded-full ${s.dot}`} />
      <Text className={`text-xs font-semibold ${s.text}`}>{t(s.i18nKey)}</Text>
    </View>
  );
}
