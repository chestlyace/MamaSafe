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

export default function AdminRoute({ children }) {
  const role = getRoleFromToken();
  if (role !== 'admin') return <Navigate to="/supervisor" replace />;
  return children;
}
