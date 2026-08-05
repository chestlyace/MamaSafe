import { TouchableOpacity, Text } from "react-native";
import { useTranslation } from "react-i18next";
import AsyncStorage from "@react-native-async-storage/async-storage";

export default function LanguageToggle() {
  const { i18n } = useTranslation();
  const isEn = i18n.language === "en";

  const toggle = async () => {
    const next = isEn ? "fr" : "en";
    i18n.changeLanguage(next);
    await AsyncStorage.setItem("lang", next);
  };

  return (
    <TouchableOpacity
      onPress={toggle}
      className="flex-row items-center gap-1.5 px-2.5 py-1.5 rounded-lg border border-border bg-white"
    >
      <Text className="text-xs font-medium text-text-body">{isEn ? "EN" : "FR"}</Text>
    </TouchableOpacity>
  );
}
