import { NavLink, Outlet, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { Zap, Home, BookOpen, Users, HelpCircle, Star, Image, LogOut, Menu, Sun, Moon } from 'lucide-react';
import { useState } from 'react';

const iconMap: Record<string, React.ReactNode> = {
  '/': <Home className="w-4.5 h-4.5" />,
  '/courses': <BookOpen className="w-4.5 h-4.5" />,
  '/users': <Users className="w-4.5 h-4.5" />,
  '/quizzes': <HelpCircle className="w-4.5 h-4.5" />,
  '/achievements': <Star className="w-4.5 h-4.5" />,
  '/media': <Image className="w-4.5 h-4.5" />,
};

const pageTitles: Record<string, string> = {
  '/': 'Dashboard',
  '/courses': 'Courses',
  '/users': 'Users',
  '/quizzes': 'Quizzes',
  '/achievements': 'Achievements',
  '/media': 'Media',
};

export default function Layout() {
  const { user, logout } = useAuth();
  const { theme, toggle: toggleTheme } = useTheme();
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  if (!user) return <Navigate to="/login" replace />;

  const basePath = '/' + location.pathname.split('/')[1];
  const pageTitle = pageTitles[basePath] || 'DevPulse';

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
      <aside className={`sidebar ${sidebarOpen ? 'sidebar-open' : ''}`}>
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
              onClick={() => setSidebarOpen(false)}
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

      {sidebarOpen && <div className="sidebar-overlay" onClick={() => setSidebarOpen(false)} />}

      <div className="main-wrapper">
        <header className="navbar">
          <button className="navbar-menu-btn" onClick={() => setSidebarOpen(v => !v)}>
            <Menu className="w-5 h-5" />
          </button>
          <h2 className="navbar-title">{pageTitle}</h2>
          <div className="navbar-spacer" />
          <button className="navbar-theme-btn" onClick={toggleTheme} title={theme === 'dark' ? 'Light mode' : 'Dark mode'}>
            {theme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <div className="navbar-user">
            <div className="user-avatar">{(user.display_name || '?')[0]}</div>
            <div className="navbar-user-info">
              <div className="user-name">{user.display_name}</div>
              <div className="user-role">{user.role}</div>
            </div>
          </div>
        </header>

        <main className="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
