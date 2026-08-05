import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import SupervisorRoute from './components/SupervisorRoute';
import AdminRoute from './components/AdminRoute';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import ChwSignupPage from './pages/ChwSignupPage';
import AssessmentPage from './pages/AssessmentPage';
import ResultPage from './pages/ResultPage';
import HistoryPage from './pages/HistoryPage';
import DashboardPage from './pages/DashboardPage';
import PatientListPage from './pages/PatientListPage';
import PatientRegisterPage from './pages/PatientRegisterPage';
import PatientDetailPage from './pages/PatientDetailPage';
import PregnancyRegisterPage from './pages/PregnancyRegisterPage';
import VisitLogPage from './pages/VisitLogPage';
import ReferralListPage from './pages/ReferralListPage';
import SchedulePage from './pages/SchedulePage';
import GrowthPage from './pages/GrowthPage';
import SupervisorDashboardPage from './pages/SupervisorDashboardPage';
import CHWListPage from './pages/CHWListPage';
import CHWDetailPage from './pages/CHWDetailPage';
import HighRiskPatientsPage from './pages/HighRiskPatientsPage';
import ReferralAnalyticsPage from './pages/ReferralAnalyticsPage';
import MonthlyReportPage from './pages/MonthlyReportPage';
import FacilitiesPage from './pages/FacilitiesPage';
import InviteCodesPage from './pages/InviteCodesPage';
import ChwPatientsPage from './pages/ChwPatientsPage';
import AdminOverviewPage from './pages/AdminOverviewPage';
import AdminDistrictsPage from './pages/AdminDistrictsPage';
import AdminSupervisorsPage from './pages/AdminSupervisorsPage';
import AdminChwsPage from './pages/AdminChwsPage';
import AdminFacilitiesPage from './pages/AdminFacilitiesPage';
import ProfilePage from './pages/ProfilePage';
import LandingPage from './pages/LandingPage';
import DownloadPage from './pages/DownloadPage';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/download" element={<DownloadPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />
        <Route path="/chw-signup" element={<ChwSignupPage />} />

        <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/assess" element={<AssessmentPage />} />
          <Route path="/result" element={<ResultPage />} />
          <Route path="/history" element={<HistoryPage />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/patients" element={<PatientListPage />} />
          <Route path="/patients/new" element={<PatientRegisterPage />} />
          <Route path="/patients/:id" element={<PatientDetailPage />} />
          <Route path="/patients/:id/pregnancies/new" element={<PregnancyRegisterPage />} />
          <Route path="/patients/:id/pregnancies/:pregnancyId/visits/new" element={<VisitLogPage />} />
          <Route path="/patients/:id/growth" element={<GrowthPage />} />
          <Route path="/patients/:id/growth/:newbornId" element={<GrowthPage />} />
          <Route path="/referrals" element={<ReferralListPage />} />
          <Route path="/schedule" element={<SchedulePage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Route>

        {/* Supervisor routes — separate Layout to avoid double navbar */}
        <Route element={<ProtectedRoute><SupervisorRoute><Layout /></SupervisorRoute></ProtectedRoute>}>
          <Route path="/supervisor" element={<SupervisorDashboardPage />} />
          <Route path="/supervisor/chws" element={<CHWListPage />} />
          <Route path="/supervisor/chws/:chwId" element={<CHWDetailPage />} />
          <Route path="/supervisor/chws/:chwId/patients" element={<ChwPatientsPage />} />
          <Route path="/supervisor/high-risk" element={<HighRiskPatientsPage />} />
          <Route path="/supervisor/referrals" element={<ReferralAnalyticsPage />} />
          <Route path="/supervisor/report" element={<MonthlyReportPage />} />
          <Route path="/supervisor/facilities" element={<FacilitiesPage />} />
          <Route path="/supervisor/invites" element={<InviteCodesPage />} />
        </Route>

        {/* Admin routes — admin-only */}
        <Route element={<ProtectedRoute><AdminRoute><Layout /></AdminRoute></ProtectedRoute>}>
          <Route path="/admin" element={<AdminOverviewPage />} />
          <Route path="/admin/districts" element={<AdminDistrictsPage />} />
          <Route path="/admin/supervisors" element={<AdminSupervisorsPage />} />
          <Route path="/admin/chws" element={<AdminChwsPage />} />
          <Route path="/admin/facilities" element={<AdminFacilitiesPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
