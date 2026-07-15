import { Tabs } from "expo-router";
import { useTranslation } from "react-i18next";
import { Text } from "react-native";

function TabIcon({ name, focused }: { name: string; focused: boolean }) {
  return (
    <Text className={`text-xl ${focused ? "text-rose-primary" : "text-text-muted"}`}>
      {name === "assess" ? "📋" : name === "history" ? "📖" : "📊"}
    </Text>
  );
}

export default function MainLayout() {
  const { t } = useTranslation();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: "#E8637A",
        tabBarInactiveTintColor: "#8E8696",
        tabBarStyle: { borderTopColor: "#E8E5EC", paddingBottom: 4 },
      }}
    >
      <Tabs.Screen
        name="assess"
        options={{
          title: t("new_assessment"),
          tabBarIcon: ({ focused }) => <TabIcon name="assess" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="history"
        options={{
          title: t("history"),
          tabBarIcon: ({ focused }) => <TabIcon name="history" focused={focused} />,
        }}
      />
      <Tabs.Screen
        name="dashboard"
        options={{
          title: t("dashboard"),
          tabBarIcon: ({ focused }) => <TabIcon name="dashboard" focused={focused} />,
        }}
      />
      <Tabs.Screen name="result" options={{ href: null }} />
    </Tabs>
  );
}
