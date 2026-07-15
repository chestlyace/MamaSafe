import { Tabs } from "expo-router";
import { useTranslation } from "react-i18next";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import Icon from "../../components/ui/Icon";

const TAB_ICONS: Record<string, { focused: keyof typeof import("@expo/vector-icons").Ionicons.glyphMap; unfocused: keyof typeof import("@expo/vector-icons").Ionicons.glyphMap }> = {
  assess: { focused: "document-text", unfocused: "document-text-outline" },
  history: { focused: "book", unfocused: "book-outline" },
  dashboard: { focused: "bar-chart", unfocused: "bar-chart-outline" },
};

function TabIcon({ name, focused }: { name: string; focused: boolean }) {
  const icons = TAB_ICONS[name];
  if (!icons) return null;
  return (
    <Icon
      name={focused ? icons.focused : icons.unfocused}
      size={22}
      color={focused ? "#E8637A" : "#8E8696"}
    />
  );
}

export default function MainLayout() {
  const { t } = useTranslation();
  const insets = useSafeAreaInsets();

  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: "#E8637A",
        tabBarInactiveTintColor: "#8E8696",
        tabBarStyle: { borderTopColor: "#E8E5EC", paddingTop: 1, paddingBottom: 20 },
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
