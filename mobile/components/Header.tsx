import { View, Text, Image } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

export default function Header() {
  const insets = useSafeAreaInsets();

  return (
    <View
      className="bg-white border-b border-border flex-row items-center justify-between px-5"
      style={{ paddingTop: insets.top, paddingBottom: 12, minHeight: insets.top + 52 }}
    >
      <View className="flex-row items-center gap-2.5">
        <Image
          source={require("../assets/icon.png")}
          style={{ width: 32, height: 32, borderRadius: 8 }}
          resizeMode="contain"
        />
        <Text className="text-lg font-bold text-text-heading tracking-tight">MamaSafe</Text>
      </View>
    </View>
  );
}
