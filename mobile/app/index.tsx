import { useEffect } from "react";
import { View, ActivityIndicator } from "react-native";
import { useRouter } from "expo-router";
import { useAuthStore } from "../stores/authStore";

export default function RootIndex() {
  const router = useRouter();
  const token = useAuthStore((s) => s.token);

  useEffect(() => {
    if (token) {
      router.replace("/(main)/assess");
    } else {
      router.replace("/(auth)/login");
    }
  }, [token]);

  return (
    <View className="flex-1 items-center justify-center bg-canvas">
      <ActivityIndicator size="large" color="#E86A33" />
    </View>
  );
}
