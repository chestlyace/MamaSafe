import { create } from "zustand";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as api from "../services/api";
import { isOnline } from "../services/network";
import type { PredictionResult, AssessmentPayload } from "../types";

interface QueuedAssessment {
  id: string;
  payload: AssessmentPayload;
  timestamp: number;
  status: "pending" | "synced" | "error";
}

interface AssessmentState {
  lastResult: PredictionResult | null;
  queue: QueuedAssessment[];
  isSubmitting: boolean;
  setLastResult: (result: PredictionResult | null) => void;
  submitAssessment: (payload: AssessmentPayload) => Promise<PredictionResult>;
  hydrateQueue: () => Promise<void>;
  syncQueue: () => Promise<void>;
}

export const useAssessmentStore = create<AssessmentState>((set, get) => ({
  lastResult: null,
  queue: [],
  isSubmitting: false,

  setLastResult: (result) => set({ lastResult: result }),

  submitAssessment: async (payload) => {
    set({ isSubmitting: true });
    try {
      if (await isOnline()) {
        const result = await api.predict(payload);
        set({ lastResult: result, isSubmitting: false });
        return result;
      } else {
        const queued: QueuedAssessment = {
          id: `${Date.now()}-${Math.random().toString(36).slice(2)}`,
          payload,
          timestamp: Date.now(),
          status: "pending",
        };
        const queue = [...get().queue, queued];
        set({ queue, isSubmitting: false });
        await AsyncStorage.setItem("assessment_queue", JSON.stringify(queue));
        throw new Error("OFFLINE_QUEUED");
      }
    } catch (err) {
      set({ isSubmitting: false });
      throw err;
    }
  },

  hydrateQueue: async () => {
    const raw = await AsyncStorage.getItem("assessment_queue");
    if (raw) set({ queue: JSON.parse(raw) });
  },

  syncQueue: async () => {
    const pending = get().queue.filter((q) => q.status === "pending");
    for (const item of pending) {
      try {
        await api.predict(item.payload);
        item.status = "synced";
      } catch {
        item.status = "error";
      }
    }
    set({ queue: [...get().queue] });
    await AsyncStorage.setItem("assessment_queue", JSON.stringify(get().queue));
  },
}));
