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

export const supervisorSignup = async (data) => {
  const res = await client.post('/api/v1/auth/supervisor-signup', data);
  return res.data;
};

export const chwSignup = async (data) => {
  const res = await client.post('/api/v1/auth/chw-signup', data);
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

export const recordDelivery = async (data) => {
  const res = await client.post('/api/v1/deliveries', data);
  return res.data;
};

// ── DELIVERIES ──────────────────────────────────────────
export const getDelivery = async (id) => {
  const res = await client.get(`/api/v1/deliveries/${id}`);
  return res.data;
};

export const getPatientDeliveries = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/deliveries`);
  return res.data;
};

// ── POSTNATAL VISITS ────────────────────────────────────
export const recordPostnatalVisit = async (data) => {
  const res = await client.post('/api/v1/postnatal-visits', data);
  return res.data;
};

export const getPostnatalVisit = async (id) => {
  const res = await client.get(`/api/v1/postnatal-visits/${id}`);
  return res.data;
};

export const listPostnatalVisits = async (deliveryId) => {
  const res = await client.get(`/api/v1/deliveries/${deliveryId}/visits`);
  return res.data;
};

// ── POSTNATAL SCHEDULE ──────────────────────────────────
export const getPostnatalSchedule = async (deliveryId) => {
  const res = await client.get(`/api/v1/deliveries/${deliveryId}/schedule`);
  return res.data;
};

export const updateScheduledPNCVisit = async (visitId, status) => {
  const res = await client.patch(`/api/v1/postnatal-scheduled-visits/${visitId}/status`,
    null, { params: { status } });
  return res.data;
};

export const reschedulePNCVisit = async (visitId, newDate, reason = '') => {
  const res = await client.patch(`/api/v1/postnatal-scheduled-visits/${visitId}/reschedule`,
    null, { params: { new_date: newDate, reason } });
  return res.data;
};

// ── MENTAL HEALTH ───────────────────────────────────────
export const createMentalHealthScreening = async (data) => {
  const res = await client.post('/api/v1/mental-health-screens', data);
  return res.data;
};

export const listPatientScreenings = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/mental-health-screens`);
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

export const getPendingFacilities = async () => {
  const res = await client.get('/api/v1/facilities/pending');
  return res.data;
};

export const addFacility = async (data) => {
  const res = await client.post('/api/v1/facilities', data);
  return res.data;
};

export const approveFacility = async (id) => {
  const res = await client.post(`/api/v1/facilities/${id}/approve`);
  return res.data;
};

export const rejectFacility = async (id) => {
  const res = await client.post(`/api/v1/facilities/${id}/reject`);
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

// ── SCHEDULE ───────────────────────────────────────────
export const getSchedule = async (pregnancyId) => {
  const res = await client.get(`/api/v1/schedule/${pregnancyId}`);
  return res.data;
};

export const rescheduleVisit = async (visitId, newDate, reason) => {
  const res = await client.patch(`/api/v1/schedule/${visitId}/reschedule`,
    { new_date: newDate, reason });
  return res.data;
};

export const completeScheduledVisit = async (visitId, ancVisitId) => {
  const res = await client.patch(`/api/v1/schedule/${visitId}/complete`,
    { anc_visit_id: ancVisitId });
  return res.data;
};

export const cancelScheduledVisit = async (visitId) => {
  const res = await client.patch(`/api/v1/schedule/${visitId}/cancel`);
  return res.data;
};

export const getTodaysVisits = async () => {
  const res = await client.get('/api/v1/schedule/today/list');
  return res.data;
};

export const getUpcomingVisits = async (days = 7) => {
  const res = await client.get(`/api/v1/schedule/upcoming/list?days=${days}`);
  return res.data;
};

export const getScheduleAnalytics = async () => {
  const res = await client.get('/api/v1/schedule/analytics/summary');
  return res.data;
};

export const manualReminder = async (visitId) => {
  const res = await client.post(`/api/v1/schedule/send-reminder/${visitId}`);
  return res.data;
};

// ── RISK TREND ────────────────────────────────────────────
export const getRiskTrend = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/risk-trend`);
  return res.data;
};

export const getRiskSummary = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/risk-summary`);
  return res.data;
};

export const getPatientEscalations = async (patientId) => {
  const res = await client.get(`/api/v1/patients/${patientId}/escalations`);
  return res.data;
};

// ── GROWTH TRACKER ──────────────────────────────────────
export const getNewbornGrowth = async (newbornId) => {
  const res = await client.get(`/api/v1/growth/newborns/${newbornId}`);
  return res.data;
};

export const getNewbornGrowthSummary = async (newbornId) => {
  const res = await client.get(`/api/v1/growth/newborns/${newbornId}/summary`);
  return res.data;
};

export const getPatientGrowthSummaries = async (patientId) => {
  const res = await client.get(`/api/v1/growth/patients/${patientId}/summary`);
  return res.data;
};

export const listGrowthAlerts = async () => {
  const res = await client.get('/api/v1/growth/alerts');
  return res.data;
};

export const resolveGrowthAlert = async (alertId) => {
  const res = await client.patch(`/api/v1/growth/alerts/${alertId}/resolve`);
  return res.data;
};

export const getRecentEscalations = async (days = 7) => {
  const res = await client.get(`/api/v1/risk-escalations/recent?days=${days}`);
  return res.data;
};

export const getEscalationAnalytics = async () => {
  const res = await client.get('/api/v1/risk-escalations/analytics');
  return res.data;
};

// ── ADMIN / SUPERVISOR ────────────────────────────────────
export const getAdminDashboard = async () => {
  const res = await client.get('/api/v1/admin/dashboard');
  return res.data;
};

export const listChws = async () => {
  const res = await client.get('/api/v1/admin/chws');
  return res.data;
};

export const getChwStats = async (chwId) => {
  const res = await client.get(`/api/v1/admin/chws/${chwId}/stats`);
  return res.data;
};

export const getHighRiskPatients = async (daysSince = 7) => {
  const res = await client.get(`/api/v1/admin/high-risk-patients?days_since_assessment=${daysSince}`);
  return res.data;
};

export const getReferralAnalytics = async () => {
  const res = await client.get('/api/v1/admin/referral-analytics');
  return res.data;
};

export const getMonthlyReport = async (year, month) => {
  const res = await client.get(`/api/v1/admin/report/monthly?year=${year}&month=${month}`);
  return res.data;
};

export const downloadMonthlyReportCsv = async (year, month) => {
  const res = await client.get(`/api/v1/admin/report/monthly/csv?year=${year}&month=${month}`, {
    responseType: 'blob',
  });
  const url = window.URL.createObjectURL(new Blob([res.data]));
  const a = document.createElement('a');
  a.href = url;
  a.download = `mamasafe-monthly-report-${year}-${String(month).padStart(2, '0')}.csv`;
  document.body.appendChild(a);
  a.click();
  a.remove();
  window.URL.revokeObjectURL(url);
};

export const listAdminUsers = async () => {
  const res = await client.get('/api/v1/admin/users');
  return res.data;
};

export const createChw = async (data) => {
  const res = await client.post('/api/v1/admin/users', data);
  return res.data;
};

export const deactivateUser = async (userId) => {
  const res = await client.patch(`/api/v1/admin/users/${userId}/deactivate`);
  return res.data;
};

export const activateUser = async (userId) => {
  const res = await client.patch(`/api/v1/admin/users/${userId}/activate`);
  return res.data;
};

// ── INVITE CODES ──────────────────────────────────────────
export const listInviteCodes = async () => {
  const res = await client.get('/api/v1/admin/invite-codes');
  return res.data;
};

export const createInviteCode = async (data) => {
  const res = await client.post('/api/v1/admin/invite-codes', data);
  return res.data;
};

export const revokeInviteCode = async (inviteId) => {
  const res = await client.post(`/api/v1/admin/invite-codes/${inviteId}/revoke`);
  return res.data;
};

// ── SUPERVISOR PATIENT MANAGEMENT ─────────────────────────
export const listChwPatients = async (chwId) => {
  const res = await client.get(`/api/v1/admin/chws/${chwId}/patients`);
  return res.data;
};

export const listSupervisorPatients = async () => {
  const res = await client.get('/api/v1/admin/patients');
  return res.data;
};

export const transferPatient = async (patientId, data) => {
  const res = await client.post(`/api/v1/admin/patients/${patientId}/transfer`, data);
  return res.data;
};

// ── ADMIN OVERVIEW ────────────────────────────────────────
export const listAdminDistricts = async () => {
  const res = await client.get('/api/v1/admin/districts');
  return res.data;
};

export const listAdminSupervisors = async () => {
  const res = await client.get('/api/v1/admin/supervisors');
  return res.data;
};

export const listAdminChws = async () => {
  const res = await client.get('/api/v1/admin/chws/roster');
  return res.data;
};

export const listAdminFacilities = async () => {
  const res = await client.get('/api/v1/admin/facilities');
  return res.data;
};

// ── MY PROFILE ────────────────────────────────────────────
export const getMe = async () => {
  const res = await client.get('/api/v1/users/me');
  return res.data;
};

export const updateMe = async (data) => {
  const res = await client.patch('/api/v1/users/me', data);
  return res.data;
};

export const changePassword = async (currentPassword, newPassword) => {
  const res = await client.post('/api/v1/users/me/password', {
    current_password: currentPassword,
    new_password: newPassword,
  });
  return res.data;
};
