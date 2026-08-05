import { create } from "zustand";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as api from "../services/api";
import { isOnline } from "../services/network";
import type { Referral, QuickReferralPayload } from "../types";

interface QueuedReferral {
  id: string;
  payload: QuickReferralPayload;
  timestamp: number;
  status: "pending" | "synced" | "error";
}

interface ReferralState {
  referrals: Referral[];
  queue: QueuedReferral[];
  isSubmitting: boolean;
  lastResult: Referral | null;

  setLastResult: (r: Referral | null) => void;
  submitReferral: (payload: QuickReferralPayload) => Promise<Referral>;
  loadReferrals: () => Promise<void>;
  hydrateQueue: () => Promise<void>;
  syncQueue: () => Promise<void>;
}

export const useReferralStore = create<ReferralState>((set, get) => ({
  referrals: [],
  queue: [],
  isSubmitting: false,
  lastResult: null,

  setLastResult: (r) => set({ lastResult: r }),

  submitReferral: async (payload) => {
    set({ isSubmitting: true });
    try {
      if (await isOnline()) {
        const result = await api.quickReferral(payload);
        set({ lastResult: result, isSubmitting: false });
        return result;
      } else {
        const queued: QueuedReferral = {
          id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
          payload,
          timestamp: Date.now(),
          status: "pending",
        };
        const queue = [...get().queue, queued];
        set({ queue, isSubmitting: false });
        await AsyncStorage.setItem("referral_queue", JSON.stringify(queue));
        throw new Error("OFFLINE_QUEUED");
      }
    } catch (err) {
      set({ isSubmitting: false });
      throw err;
    }
  },

  loadReferrals: async () => {
    try {
      const referrals = await api.getReferrals();
      set({ referrals });
    } catch {
      // offline or error — keep existing state
    }
  },

  hydrateQueue: async () => {
    const raw = await AsyncStorage.getItem("referral_queue");
    if (raw) set({ queue: JSON.parse(raw) });
  },

  syncQueue: async () => {
    const pending = get().queue.filter((q) => q.status === "pending");
    for (const item of pending) {
      try {
        await api.quickReferral(item.payload);
        item.status = "synced";
      } catch {
        item.status = "error";
      }
    }
    set({ queue: [...get().queue] });
    await AsyncStorage.setItem("referral_queue", JSON.stringify(get().queue));
  },
}));
