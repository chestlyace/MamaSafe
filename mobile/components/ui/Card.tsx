import { View, type ViewProps } from "react-native";

export default function Card({ children, className = "", ...props }: ViewProps & { children: React.ReactNode }) {
  return (
    <View className={`bg-white border border-border rounded-2xl p-5 ${className}`} {...props}>
      {children}
    </View>
  );
}
