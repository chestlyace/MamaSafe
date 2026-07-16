import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
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
          <Route path="/referrals" element={<ReferralListPage />} />
          <Route path="*" element={<Navigate to="/assess" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
