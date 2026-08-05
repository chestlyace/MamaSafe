import { useEffect } from "react";
import { View, Text, FlatList, TouchableOpacity } from "react-native";
import { useTranslation } from "react-i18next";
import { useRouter } from "expo-router";
import { useReferralStore } from "../../stores/referralStore";
import Card from "../../components/ui/Card";

const STATUS_COLORS: Record<string, string> = {
  sent: "bg-yellow-100 text-yellow-700",
  received: "bg-blue-100 text-blue-700",
  patient_arrived: "bg-green-100 text-green-700",
};

export default function ReferScreen() {
  const { t } = useTranslation();
  const router = useRouter();
  const referrals = useReferralStore((s) => s.referrals);
  const loadReferrals = useReferralStore((s) => s.loadReferrals);

  useEffect(() => {
    loadReferrals();
  }, []);

  const renderItem = ({ item }: { item: any }) => (
    <TouchableOpacity onPress={() => router.push({ pathname: "/(main)/result", params: { referralId: item.id } })}>
      <Card className="mb-3">
        <View className="flex-row justify-between items-start mb-2">
          <Text className="text-base font-semibold text-text-heading">{item.patient_name}</Text>
          <View className={`px-2 py-1 rounded-full ${STATUS_COLORS[item.status] || "bg-gray-100 text-gray-600"}`}>
            <Text className="text-[10px] font-bold uppercase">{item.status.replace("_", " ")}</Text>
          </View>
        </View>
        <Text className="text-sm text-text-body mb-1">→ {item.facility_name || "Unknown"}</Text>
        <Text className="text-xs text-text-muted" numberOfLines={2}>{item.clinical_summary}</Text>
        <View className="flex-row justify-between mt-2">
          <Text className="text-[10px] text-text-muted uppercase">{item.delivery_method}</Text>
          <Text className="text-[10px] text-text-muted">{new Date(item.created_at).toLocaleDateString()}</Text>
        </View>
      </Card>
    </TouchableOpacity>
  );

  return (
    <View className="flex-1 bg-canvas">
      <View className="px-5 pt-4 pb-3">
        <Text className="text-xl font-bold text-text-heading">{t("referral_history")}</Text>
      </View>
      <FlatList
        data={referrals}
        keyExtractor={(item) => String(item.id)}
        renderItem={renderItem}
        contentContainerStyle={{ padding: 20, paddingTop: 0 }}
        ListEmptyComponent={
          <View className="items-center justify-center py-20">
            <Text className="text-text-muted text-sm">{t("no_referrals")}</Text>
          </View>
        }
      />
    </View>
  );
}
