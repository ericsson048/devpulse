import { NavLink, Outlet, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  if (!user) return <Navigate to="/login" replace />;

  const menuItems = [
    { to: '/', icon: 'pi pi-home', label: 'Dashboard', end: true },
    { to: '/courses', icon: 'pi pi-book', label: 'Courses', end: false },
    { to: '/users', icon: 'pi pi-users', label: 'Users', end: false },
    { to: '/quizzes', icon: 'pi pi-question-circle', label: 'Quizzes', end: false },
  ];

  return (
    <div className="layout">
      <aside className="sidebar">
        <div className="sidebar-brand" onClick={() => navigate('/')} style={{ cursor: 'pointer' }}>
          <i className="pi pi-bolt" />
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
              <i className={item.icon} />
              <span>{item.label}</span>
            </NavLink>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="user-info">
            <div className="user-avatar">{user.display_name[0]}</div>
            <div>
              <div className="user-name">{user.display_name}</div>
              <div className="user-role">{user.role}</div>
            </div>
          </div>
          <button className="btn-logout" onClick={logout} title="Logout">
            <i className="pi pi-sign-out" />
          </button>
        </div>
      </aside>

      <main className="main-content">
        <Outlet />
      </main>
    </div>
  );
}
