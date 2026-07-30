import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import SupervisorRoute from './components/SupervisorRoute';
import LoginPage from './pages/LoginPage';
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

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<ProtectedRoute><Layout /></ProtectedRoute>}>
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
          <Route path="*" element={<Navigate to="/assess" replace />} />
        </Route>

        {/* Supervisor routes — separate Layout to avoid double navbar */}
        <Route element={<ProtectedRoute><SupervisorRoute><Layout /></SupervisorRoute></ProtectedRoute>}>
          <Route path="/supervisor" element={<SupervisorDashboardPage />} />
          <Route path="/supervisor/chws" element={<CHWListPage />} />
          <Route path="/supervisor/chws/:chwId" element={<CHWDetailPage />} />
          <Route path="/supervisor/high-risk" element={<HighRiskPatientsPage />} />
          <Route path="/supervisor/referrals" element={<ReferralAnalyticsPage />} />
          <Route path="/supervisor/report" element={<MonthlyReportPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
