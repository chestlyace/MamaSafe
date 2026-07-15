import { View, Text, TextInput, type TextInputProps } from "react-native";

interface InputProps extends TextInputProps {
  label?: string;
  error?: string;
}

export default function Input({ label, error, ...props }: InputProps) {
  return (
    <View className="mb-4">
      {label && (
        <Text className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">
          {label}
        </Text>
      )}
      <TextInput
        className={`w-full px-4 py-3 bg-surface border rounded-xl text-sm text-text-heading ${error ? "border-red-400" : "border-border"}`}
        placeholderTextColor="#8E8696"
        {...props}
      />
      {error && <Text className="text-xs text-red-500 mt-1">{error}</Text>}
    </View>
  );
}
