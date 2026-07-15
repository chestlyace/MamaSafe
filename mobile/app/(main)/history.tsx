import { useEffect, useState, useMemo } from "react";
import { View, Text, TextInput, FlatList, TouchableOpacity, RefreshControl } from "react-native";
import { useTranslation } from "react-i18next";
import { useRouter } from "expo-router";
import { getAssessments } from "../../services/api";
import { useAssessmentStore } from "../../stores/assessmentStore";
import RiskBadge from "../../components/RiskBadge";
import type { Assessment } from "../../types";

export default function HistoryPage() {
  const { t } = useTranslation();
  const router = useRouter();
  const setLastResult = useAssessmentStore((s) => s.setLastResult);
  const [assessments, setAssessments] = useState<Assessment[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [search, setSearch] = useState("");

  const fetchData = async () => {
    try {
      const data = await getAssessments(0, 100);
      setAssessments(data);
    } catch {}
    setLoading(false);
  };

  useEffect(() => { fetchData(); }, []);

  const onRefresh = async () => {
    setRefreshing(true);
    await fetchData();
    setRefreshing(false);
  };

  const filtered = useMemo(() => {
    if (!search.trim()) return assessments;
    const term = search.toLowerCase();
    return assessments.filter((a) => a.patient_ref?.toLowerCase().includes(term));
  }, [assessments, search]);

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return `${d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" })} • ${d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit" })}`;
  };

  if (loading) {
    return (
      <View className="flex-1 items-center justify-center bg-canvas">
        <Text className="text-text-muted">{t("loading")}</Text>
      </View>
    );
  }

  return (
    <View className="flex-1 bg-canvas">
      <View className="px-5 pt-8 pb-4">
        <Text className="text-2xl font-bold text-text-heading tracking-tight mb-1">{t("assessment_history")}</Text>
        <Text className="text-sm text-text-muted mb-4">{t("manage_history")}</Text>
        <TextInput
          value={search}
          onChangeText={setSearch}
          placeholder={t("search_patient_id")}
          className="px-4 py-2.5 border border-border rounded-xl bg-white text-sm"
          placeholderTextColor="#8E8696"
        />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(item) => String(item.id)}
        contentContainerStyle={{ padding: 20, paddingTop: 0 }}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        renderItem={({ item }) => (
          <TouchableOpacity
            className="bg-white border border-border rounded-2xl p-5 mb-3"
            onPress={() => {
              setLastResult({ risk_level: item.risk_level as "high risk" | "mid risk" | "low risk", confidence: item.prob_high, prob_high: item.prob_high, prob_mid: item.prob_mid, prob_low: item.prob_low, recommendation: "", shap_values: [], assessment_id: item.id });
              router.push("/(main)/result");
            }}
          >
            <View className="flex-row justify-between items-start mb-3">
              <View>
                <Text className="text-[11px] font-semibold text-text-muted uppercase">{t("patient_id")}</Text>
                <Text className="text-lg font-semibold text-text-heading mt-0.5">{item.patient_ref || "—"}</Text>
              </View>
              <View className="items-end gap-2">
                <Text className="text-xs text-text-muted">{formatDate(item.created_at)}</Text>
                <RiskBadge level={item.risk_level} />
              </View>
            </View>
            <View className="flex-row justify-between bg-surface rounded-xl p-3">
              <View><Text className="text-[11px] text-text-muted">{t("age")}</Text><Text className="text-sm font-semibold text-text-heading">{item.age}</Text></View>
              <View className="items-center"><Text className="text-[11px] text-text-muted">{t("systolic_bp")}</Text><Text className="text-sm font-semibold text-text-heading">{item.systolic_bp}</Text></View>
              <View className="items-end"><Text className="text-[11px] text-text-muted">{t("blood_sugar")}</Text><Text className="text-sm font-semibold text-text-heading">{item.blood_sugar}</Text></View>
            </View>
          </TouchableOpacity>
        )}
        ListEmptyComponent={
          <View className="items-center py-24">
            <Text className="text-lg font-semibold text-text-heading mb-1">{t("no_assessments")}</Text>
            <Text className="text-sm text-text-muted mb-6">{t("history_empty_hint")}</Text>
          </View>
        }
      />
    </View>
  );
}
