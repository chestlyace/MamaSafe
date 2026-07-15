import { useState } from "react";
import { View, Text, TextInput, TouchableOpacity, KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import { useTranslation } from "react-i18next";
import { useAuthStore } from "../../stores/authStore";
import LanguageToggle from "../../components/LanguageToggle";
import Button from "../../components/ui/Button";
import Icon from "../../components/ui/Icon";

export default function LoginPage() {
  const { t } = useTranslation();
  const login = useAuthStore((s) => s.login);
  const isLoading = useAuthStore((s) => s.isLoading);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async () => {
    setError("");
    try {
      await login(username, password);
    } catch (err: any) {
      setError(err.message);
    }
  };

  return (
    <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} className="flex-1 bg-canvas">
      <ScrollView contentContainerStyle={{ flexGrow: 1 }} keyboardShouldPersistTaps="handled">
        <View className="flex-1 items-center justify-center px-5 pb-12">
          <View className="w-full max-w-[380px]">
            <View className="items-center mb-8">
              <Text className="text-2xl font-bold text-text-heading tracking-tight">{t("app_name")}</Text>
              <Text className="text-sm text-text-muted mt-1">{t("tagline")}</Text>
            </View>

            <View className="bg-white rounded-2xl border border-border p-6 sm:p-8">
              {error ? (
                <View className="mb-5 bg-red-50 border border-red-200 rounded-xl px-4 py-3">
                  <Text className="text-red-700 text-sm">{error}</Text>
                </View>
              ) : null}

              <Text className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">{t("username")}</Text>
              <TextInput
                value={username}
                onChangeText={setUsername}
                placeholder={t("health_worker_id")}
                autoCapitalize="none"
                className="w-full px-4 py-3 bg-surface border border-border rounded-xl text-sm text-text-heading mb-4"
                placeholderTextColor="#8E8696"
              />

              <Text className="text-xs font-semibold text-text-muted uppercase tracking-wider mb-1.5">{t("password")}</Text>
              <View className="relative mb-6">
                <TextInput
                  value={password}
                  onChangeText={setPassword}
                  secureTextEntry={!showPassword}
                  placeholder="••••••••"
                  className="w-full px-4 py-3 pr-11 bg-surface border border-border rounded-xl text-sm text-text-heading"
                  placeholderTextColor="#8E8696"
                />
                <TouchableOpacity onPress={() => setShowPassword(!showPassword)} className="absolute right-3 top-3">
                  <Icon name={showPassword ? "eye-off" : "eye"} size={20} color="#8E8696" />
                </TouchableOpacity>
              </View>

              <Button onPress={handleSubmit} loading={isLoading}>
                {t("login")}
              </Button>
            </View>

            <View className="flex-row justify-center mt-5">
              <LanguageToggle />
            </View>

            <Text className="text-center text-xs text-text-muted mt-6">
              Developing Innovative Professionals — YIBS
            </Text>
          </View>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}
