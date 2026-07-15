import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import AsyncStorage from "@react-native-async-storage/async-storage";
import en from "./en.json";
import fr from "./fr.json";

const languageDetector = {
  type: "languageDetector" as const,
  async: true,
  detect: async (callback: (lng: string) => void) => {
    const stored = await AsyncStorage.getItem("lang");
    callback(stored || "en");
  },
  init: () => {},
  cacheUserLanguage: async (lng: string) => {
    await AsyncStorage.setItem("lang", lng);
  },
};

i18n.use(languageDetector).use(initReactI18next).init({
  resources: { en: { translation: en }, fr: { translation: fr } },
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

export default i18n;
