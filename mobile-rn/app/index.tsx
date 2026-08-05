import { View, ActivityIndicator } from "react-native";

export default function RootIndex() {
  return (
    <View className="flex-1 items-center justify-center bg-canvas">
      <ActivityIndicator size="large" color="#E86A33" />
    </View>
  );
}
