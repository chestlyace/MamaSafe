import { View, Text, ScrollView } from "react-native";
import { useTranslation } from "react-i18next";
import { useRouter } from "expo-router";
import { useAssessmentStore } from "../../stores/assessmentStore";
import Button from "../../components/ui/Button";
import Card from "../../components/ui/Card";
import RiskBadge from "../../components/RiskBadge";

const RISK_STYLES = {
  "high risk": { bg: "bg-red-50", border: "border-red-200", accent: "text-red-600", barBg: "bg-red-500", titleKey: "critical_result_title", descKey: "critical_result_desc" },
  "mid risk": { bg: "bg-amber-50", border: "border-amber-200", accent: "text-amber-700", barBg: "bg-amber-500", titleKey: "moderate_result_title", descKey: "moderate_result_desc" },
  "low risk": { bg: "bg-green-50", border: "border-green-200", accent: "text-green-700", barBg: "bg-green-500", titleKey: "low_result_title", descKey: "low_result_desc" },
};

export default function ResultPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const lastResult = useAssessmentStore((s) => s.lastResult);

  if (!lastResult) {
    return (
      <View className="flex-1 items-center justify-center bg-canvas px-5">
        <Text className="text-lg font-semibold text-text-heading mb-1">{t("no_result_data")}</Text>
        <Text className="text-sm text-text-muted mb-6">{t("no_result_hint")}</Text>
        <Button onPress={() => router.push("/(main)/assess")}>{t("new_assessment")}</Button>
      </View>
    );
  }

  const cfg = RISK_STYLES[lastResult.risk_level] || RISK_STYLES["low risk"];
  const confidence = ((lastResult.confidence || 0) * 100).toFixed(0);
  const shapValues = (lastResult.shap_values || []).map((v) => ({ ...v, pct: Math.abs(v.shap_value) * 100 }));
  const maxPct = Math.max(...shapValues.map((v) => v.pct), 1);

  return (
    <ScrollView className="flex-1 bg-canvas" contentContainerStyle={{ padding: 20, paddingBottom: 40 }}>
      <View className={`rounded-2xl ${cfg.bg} border ${cfg.border} p-6 mb-6`}>
        <RiskBadge level={lastResult.risk_level} />
        <Text className="text-xl font-bold text-text-heading mt-3">{t(cfg.titleKey)}</Text>
        <Text className="text-sm text-text-body mt-1">{t(cfg.descKey)}</Text>
        <View className="bg-white rounded-xl px-5 py-3 mt-4 items-center border border-border">
          <Text className="text-[11px] font-semibold text-text-muted uppercase">{t("confidence")}</Text>
          <Text className={`text-3xl font-bold ${cfg.accent}`}>{confidence}%</Text>
        </View>
      </View>

      <Card className="mb-5">
        <Text className="text-base font-semibold text-text-heading mb-2">{t("recommendation")}</Text>
        <Text className="text-sm text-text-body leading-relaxed">{lastResult.recommendation || t("no_recommendation")}</Text>
      </Card>

      {shapValues.length > 0 && (
        <Card className="mb-5">
          <Text className="text-base font-semibold text-text-heading mb-1">{t("feature_contributions")}</Text>
          <Text className="text-xs text-text-muted mb-4">{t("shap_explanation")}</Text>
          {shapValues.map((v, i) => {
            const isPos = v.shap_value >= 0;
            const widthPct = (v.pct / maxPct) * 100;
            return (
              <View key={i} className="mb-3">
                <View className="flex-row justify-between mb-1">
                  <Text className="text-sm text-text-heading">{v.feature} {v.raw_value !== undefined ? `(${v.raw_value})` : ""}</Text>
                  <Text className={`text-xs font-semibold ${isPos ? "text-red-600" : "text-green-600"}`}>
                    {isPos ? "+" : ""}{v.pct.toFixed(1)}%
                  </Text>
                </View>
                <View className="h-1.5 bg-surface rounded-full overflow-hidden flex-row">
                  <View className={`h-full rounded-full ${isPos ? "bg-red-500" : "bg-green-500"}`} style={{ width: `${widthPct}%` }} />
                </View>
              </View>
            );
          })}
        </Card>
      )}

      <Card className="mb-5">
        <Text className="text-base font-semibold text-text-heading mb-4">{t("prob_distribution")}</Text>
        {[
          { label: t("high_risk"), val: ((lastResult.prob_high || 0) * 100).toFixed(0), color: "bg-red-500" },
          { label: t("mid_risk"), val: ((lastResult.prob_mid || 0) * 100).toFixed(0), color: "bg-amber-500" },
          { label: t("low_risk"), val: ((lastResult.prob_low || 0) * 100).toFixed(0), color: "bg-green-500" },
        ].map((p) => (
          <View key={p.label} className="mb-4">
            <View className="flex-row justify-between mb-1.5">
              <Text className="text-xs font-semibold text-text-heading">{p.label}</Text>
              <Text className="text-lg font-bold text-text-heading">{p.val}%</Text>
            </View>
            <View className="h-2.5 bg-surface rounded-full overflow-hidden">
              <View className={`h-full rounded-full ${p.color}`} style={{ width: `${p.val}%` }} />
            </View>
          </View>
        ))}
      </Card>

      <Button variant="secondary" onPress={() => router.push("/(main)/assess")}>
        {t("start_new_assessment")}
      </Button>
    </ScrollView>
  );
}
