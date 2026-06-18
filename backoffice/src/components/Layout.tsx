import { NavLink, Outlet, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Zap, Home, BookOpen, Users, HelpCircle, Star, Image, LogOut } from 'lucide-react';

const iconMap: Record<string, React.ReactNode> = {
  '/': <Home className="w-4.5 h-4.5" />,
  '/courses': <BookOpen className="w-4.5 h-4.5" />,
  '/users': <Users className="w-4.5 h-4.5" />,
  '/quizzes': <HelpCircle className="w-4.5 h-4.5" />,
  '/achievements': <Star className="w-4.5 h-4.5" />,
  '/media': <Image className="w-4.5 h-4.5" />,
};

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  if (!user) return <Navigate to="/login" replace />;

  const menuItems = [
    { to: '/', label: 'Dashboard', end: true },
    { to: '/courses', label: 'Courses', end: false },
    { to: '/users', label: 'Users', end: false },
    { to: '/quizzes', label: 'Quizzes', end: false },
    { to: '/achievements', label: 'Achievements', end: false },
    { to: '/media', label: 'Media', end: false },
  ];

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-brand" onClick={() => navigate('/')} style={{ cursor: 'pointer' }}>
          <Zap className="w-5 h-5" />
          <span>DevPulse</span>
        </div>

        <nav className="sidebar-nav">
          {menuItems.map(item => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
            >
              {iconMap[item.to]}
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">{(user.display_name || '?')[0]}</div>
            <div>
              <div className="user-name">{user.display_name}</div>
              <div className="user-role">{user.role}</div>
            </div>
          </div>
          <button className="btn-logout" onClick={logout} title="Logout">
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>
    </div>
  );
}
