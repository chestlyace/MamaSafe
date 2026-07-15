import { useEffect } from "react";
import { Stack } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider } from "react-native-safe-area-context";
import "../i18n";
import { useAuthStore } from "../stores/authStore";
import { useAssessmentStore } from "../stores/assessmentStore";
import { initNetworkListener } from "../services/network";

export default function RootLayout() {
  const hydrate = useAuthStore((s) => s.hydrate);
  const hydrateQueue = useAssessmentStore((s) => s.hydrateQueue);
  const syncQueue = useAssessmentStore((s) => s.syncQueue);

  useEffect(() => {
    hydrate();
    hydrateQueue();
    initNetworkListener((online) => {
      if (online) syncQueue();
    });
  }, []);

  return (
    <SafeAreaProvider>
      <Stack screenOptions={{ headerShown: false }} />
      <StatusBar style="dark" />
    </SafeAreaProvider>
  );
}
