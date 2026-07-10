import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import LoginPage from './pages/LoginPage';
import AssessmentPage from './pages/AssessmentPage';
import ResultPage from './pages/ResultPage';
import HistoryPage from './pages/HistoryPage';
import DashboardPage from './pages/DashboardPage';

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
          <Route path="*" element={<Navigate to="/assess" replace />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
