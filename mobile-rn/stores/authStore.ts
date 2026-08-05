import { create } from "zustand";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { router } from "expo-router";
import * as api from "../services/api";

interface AuthState {
  token: string | null;
  isLoading: boolean;
  hydrate: () => Promise<void>;
  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: null,
  isLoading: false,

  hydrate: async () => {
    const token = await AsyncStorage.getItem("token");
    set({ token });
  },

  login: async (username, password) => {
    set({ isLoading: true });
    try {
      const data = await api.login(username, password);
      await AsyncStorage.setItem("token", data.access_token);
      set({ token: data.access_token, isLoading: false });
      router.replace("/(main)/assess");
    } catch (err: any) {
      set({ isLoading: false });
      throw new Error(err.response?.data?.detail || "Login failed");
    }
  },

  logout: async () => {
    await AsyncStorage.removeItem("token");
    set({ token: null });
    router.replace("/(auth)/login");
  },
}));
