import { useEffect, useState } from "react";
import { View, ActivityIndicator } from "react-native";
import { Stack, useRouter } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import Header from "../components/Header";
import "../i18n";
import "../global.css";
import { useAuthStore } from "../stores/authStore";
import { useAssessmentStore } from "../stores/assessmentStore";
import { initNetworkListener } from "../services/network";

export default function RootLayout() {
  const router = useRouter();
  const hydrate = useAuthStore((s) => s.hydrate);
  const hydrateQueue = useAssessmentStore((s) => s.hydrateQueue);
  const syncQueue = useAssessmentStore((s) => s.syncQueue);
  const token = useAuthStore((s) => s.token);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    hydrate();
    hydrateQueue();
    initNetworkListener((online) => {
      if (online) syncQueue();
    });
    setReady(true);
  }, []);

  useEffect(() => {
    if (!ready) return;
    if (token) {
      router.replace("/(main)/assess");
    } else {
      router.replace("/(auth)/login");
    }
  }, [ready, token]);

  return (
    <SafeAreaProvider>
      <Header />
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(main)" />
      </Stack>
      <StatusBar style="dark" />
    </SafeAreaProvider>
  );
}
