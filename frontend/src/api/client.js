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

// ── PATIENTS ─────────────────────────────────────────────
export const getPatients = async (search = '', skip = 0, limit = 50) => {
  const params = { skip, limit };
  if (search) params.search = search;
  const res = await client.get('/api/v1/patients', { params });
  return res.data;
};

export const getPatient = async (id) => {
  const res = await client.get(`/api/v1/patients/${id}`);
  return res.data;
};

export const getPatientCard = async (id) => {
  const res = await client.get(`/api/v1/patients/${id}/card`);
  return res.data;
};

export const createPatient = async (data) => {
  const res = await client.post('/api/v1/patients', data);
  return res.data;
};

// ── PREGNANCIES ──────────────────────────────────────────
export const registerPregnancy = async (data) => {
  const res = await client.post('/api/v1/pregnancies', data);
  return res.data;
};

export const recordDelivery = async (pregnancyId, data) => {
  const res = await client.patch(`/api/v1/pregnancies/${pregnancyId}/delivery`, data);
  return res.data;
};

// ── ANC VISITS ───────────────────────────────────────────
export const recordVisit = async (data) => {
  const res = await client.post('/api/v1/anc-visits', data);
  return res.data;
};

export const getVisit = async (id) => {
  const res = await client.get(`/api/v1/anc-visits/${id}`);
  return res.data;
};

export const listVisits = async (pregnancyId) => {
  const res = await client.get(`/api/v1/pregnancies/${pregnancyId}/visits`);
  return res.data;
};

// ── FACILITIES ──────────────────────────────────────────
export const getFacilities = async () => {
  const res = await client.get('/api/v1/facilities');
  return res.data;
};

export const suggestFacility = async (data) => {
  const res = await client.post('/api/v1/facilities', data);
  return res.data;
};

export const approveFacility = async (id) => {
  const res = await client.post(`/api/v1/facilities/${id}/approve`);
  return res.data;
};

// ── REFERRALS ──────────────────────────────────────────
export const createReferral = async (data) => {
  const res = await client.post('/api/v1/referrals', data);
  return res.data;
};

export const quickReferral = async (data) => {
  const res = await client.post('/api/v1/referrals/quick', data);
  return res.data;
};

export const getReferrals = async (params = {}) => {
  const res = await client.get('/api/v1/referrals', { params });
  return res.data;
};

export const getReferral = async (id) => {
  const res = await client.get(`/api/v1/referrals/${id}`);
  return res.data;
};

export const updateReferralStatus = async (id, status) => {
  const res = await client.patch(`/api/v1/referrals/${id}/status`, { status });
  return res.data;
};

export const getReferralStats = async () => {
  const res = await client.get('/api/v1/referrals/stats');
  return res.data;
};
