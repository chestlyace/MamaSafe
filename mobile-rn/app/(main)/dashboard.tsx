import { useEffect, useState } from "react";
import { View, Text, ScrollView, RefreshControl } from "react-native";
import { useTranslation } from "react-i18next";
import { getDashboardSummary } from "../../services/api";
import Card from "../../components/ui/Card";
import Icon from "../../components/ui/Icon";
import type { DashboardSummary } from "../../types";

export default function DashboardPage() {
  const { t } = useTranslation();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const fetchData = async () => {
    try {
      const data = await getDashboardSummary();
      setSummary(data);
    } catch {}
    setLoading(false);
  };

  useEffect(() => { fetchData(); }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  };

  if (loading) {
    return <View className="flex-1 items-center justify-center bg-canvas"><Text className="text-text-muted">{t("loading")}</Text></View>;
  }

  if (!summary) {
    return <View className="flex-1 items-center justify-center bg-canvas"><Text className="text-text-muted">{t("error")}</Text></View>;
  }

  const { total_assessments, high_risk_count, mid_risk_count, low_risk_count } = summary;

  const statCards = [
    { label: t("total_assessments"), value: total_assessments, color: "text-rose-500", sub: null },
    { label: t("high_risk"), value: high_risk_count, color: "text-red-600", sub: t("requires_immediate"), dot: "bg-red-500" },
    { label: t("mid_risk"), value: mid_risk_count, color: "text-amber-600", sub: t("needs_followup"), dot: "bg-amber-500" },
    { label: t("low_risk"), value: low_risk_count, color: "text-green-600", sub: t("regular_monitoring"), dot: "bg-green-500" },
  ];

  return (
    <ScrollView className="flex-1 bg-canvas" contentContainerStyle={{ padding: 20 }} refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}>
      <Text className="text-2xl font-bold text-text-heading tracking-tight mb-1">{t("dashboard")}</Text>
      <Text className="text-sm text-text-muted mb-6">{t("clinical_summary")}</Text>

      <View className="flex-row flex-wrap gap-3 mb-6">
        {statCards.map((s) => (
          <View key={s.label} className="bg-white border border-border rounded-xl p-4 flex-1 min-w-[45%]">
            <View className="flex-row items-center justify-between mb-2">
              <Text className="text-[11px] font-semibold text-text-muted uppercase">{s.label}</Text>
              {s.dot && <View className={`w-2 h-2 rounded-full ${s.dot}`} />}
            </View>
            <Text className={`text-2xl font-bold ${s.color}`}>{s.value}</Text>
            {s.sub && <Text className="text-xs text-text-muted mt-0.5">{s.sub}</Text>}
          </View>
        ))}
      </View>

      {total_assessments > 0 && (
        <Card className="mb-6">
          <Text className="text-sm font-semibold text-text-heading mb-4">{t("risk_distribution")}</Text>
          <View className="h-7 rounded-full overflow-hidden flex-row bg-surface">
            {high_risk_count > 0 && <View className="bg-red-500 h-full items-center justify-center" style={{ width: `${(high_risk_count / total_assessments) * 100}%` as any }}><Text className="text-[10px] font-bold text-white">{high_risk_count}</Text></View>}
            {mid_risk_count > 0 && <View className="bg-amber-500 h-full items-center justify-center" style={{ width: `${(mid_risk_count / total_assessments) * 100}%` as any }}><Text className="text-[10px] font-bold text-white">{mid_risk_count}</Text></View>}
            {low_risk_count > 0 && <View className="bg-green-500 h-full items-center justify-center" style={{ width: `${(low_risk_count / total_assessments) * 100}%` as any }}><Text className="text-[10px] font-bold text-white">{low_risk_count}</Text></View>}
          </View>
          <View className="flex-row justify-between mt-3">
            {[{ label: t("high_risk"), pct: high_risk_count, dot: "bg-red-500" }, { label: t("mid_risk"), pct: mid_risk_count, dot: "bg-amber-500" }, { label: t("low_risk"), pct: low_risk_count, dot: "bg-green-500" }].map((i) => (
              <View key={i.label} className="flex-row items-center gap-1.5">
                <View className={`w-2 h-2 rounded-full ${i.dot}`} />
                <Text className="text-xs text-text-muted">{i.label} ({((i.pct / total_assessments) * 100).toFixed(0)}%)</Text>
              </View>
            ))}
          </View>
        </Card>
      )}

      <Card>
        <Text className="text-sm font-semibold text-text-heading mb-3">{t("critical_alerts")}</Text>
        {high_risk_count > 0 ? (
          <View className="flex-row items-center gap-3 p-4 bg-red-50 rounded-xl">
            <View className="w-9 h-9 rounded-full bg-red-100 items-center justify-center">
              <Icon name="alert-circle" size={20} color="#DC2626" />
            </View>
            <View className="flex-1">
              <Text className="text-sm font-semibold text-text-heading">{t("high_risk_count_alert", { count: high_risk_count })}</Text>
              <Text className="text-xs text-text-muted">{t("high_risk_alert_desc")}</Text>
            </View>
          </View>
        ) : (
          <View className="flex-row items-center gap-3 p-4 bg-green-50 rounded-xl">
            <View className="w-9 h-9 rounded-full bg-green-100 items-center justify-center">
              <Icon name="checkmark-circle" size={20} color="#16A34A" />
            </View>
            <View>
              <Text className="text-sm font-semibold text-text-heading">{t("no_critical_alerts")}</Text>
              <Text className="text-xs text-text-muted">{t("all_patients_safe")}</Text>
            </View>
          </View>
        )}
      </Card>
    </ScrollView>
  );
}
