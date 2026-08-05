import { Navigate } from 'react-router-dom';

function getRoleFromToken() {
  const token = localStorage.getItem('token');
  if (!token) return null;
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.role;
  } catch {
    return null;
  }
}

export default function SupervisorRoute({ children }) {
  const role = getRoleFromToken();
  if (!role) return <Navigate to="/login" replace />;
  if (role === 'admin') return <Navigate to="/admin" replace />;
  if (role !== 'supervisor') return <Navigate to="/assess" replace />;
  return children;
}
