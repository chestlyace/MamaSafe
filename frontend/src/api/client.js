import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const client = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Attach JWT token to every request automatically
client.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// If token expires, redirect to login automatically
client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// ── AUTH ──────────────────────────────────────────────────
export const login = async (username, password) => {
  const form = new URLSearchParams();
  form.append('username', username);
  form.append('password', password);
  const res = await client.post('/api/v1/auth/login', form, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
  });
  return res.data;
};

export const register = async (username, password) => {
  const res = await client.post('/api/v1/auth/register', { username, password });
  return res.data;
};

// ── PREDICTION ────────────────────────────────────────────
export const predict = async (formData) => {
  const res = await client.post('/api/v1/predict', formData);
  return res.data;
};

// ── ASSESSMENTS ───────────────────────────────────────────
export const getAssessments = async (skip = 0, limit = 20) => {
  const res = await client.get(`/api/v1/assessments?skip=${skip}&limit=${limit}`);
  return res.data;
};

export const getAssessment = async (id) => {
  const res = await client.get(`/api/v1/assessments/${id}`);
  return res.data;
};

// ── DASHBOARD ─────────────────────────────────────────────
export const getDashboardSummary = async () => {
  const res = await client.get('/api/v1/dashboard/summary');
  return res.data;
};
