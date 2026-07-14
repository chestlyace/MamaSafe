import { Outlet } from 'react-router-dom';
import NavBar from './NavBar';

export default function Layout() {
  return (
    <div className="min-h-screen" style={{ background: 'linear-gradient(135deg, #f5f2fe 0%, #ffffff 100%)' }}>
      <NavBar />
      <Outlet />
    </div>
  );
}
