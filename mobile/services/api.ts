import axios from "axios";
import AsyncStorage from "@react-native-async-storage/async-storage";
import type { LoginResponse, PredictionResult, Assessment, DashboardSummary, AssessmentPayload } from "../types";

const BASE_URL = process.env.EXPO_PUBLIC_API_URL || "http://localhost:8000";

const client = axios.create({
  baseURL: BASE_URL,
  headers: { "Content-Type": "application/json" },
});

client.interceptors.request.use(async (config) => {
  const token = await AsyncStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

client.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      await AsyncStorage.removeItem("token");
    }
    return Promise.reject(error);
  }
);

export const login = async (username: string, password: string): Promise<LoginResponse> => {
  const form = new URLSearchParams();
  form.append("username", username);
  form.append("password", password);
  const res = await client.post("/api/v1/auth/login", form, {
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  return res.data;
};

export const predict = async (payload: AssessmentPayload): Promise<PredictionResult> => {
  const res = await client.post("/api/v1/predict", payload);
  return res.data;
};

export const getAssessments = async (skip = 0, limit = 20): Promise<Assessment[]> => {
  const res = await client.get(`/api/v1/assessments?skip=${skip}&limit=${limit}`);
  return res.data;
};

export const getDashboardSummary = async (): Promise<DashboardSummary> => {
  const res = await client.get("/api/v1/dashboard/summary");
  return res.data;
};
