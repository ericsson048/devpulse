import { useState, type FormEvent } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Input } from '../components/ui/Input';
import Button from '../components/ui/Button';
import { Zap, LogIn, AlertCircle } from 'lucide-react';

export default function Login() {
  const { user, login, loading } = useAuth();
  const [email, setEmail] = useState('admin');
  const [password, setPassword] = useState('devpulse2024');
  const [error, setError] = useState('');

  if (user) return <Navigate to="/" replace />;

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    try {
      await login(email, password);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Login failed');
    }
  };

  return (
    <div className="login-page">
      <div className="login-card">
        <div className="login-header">
          <div style={{
            width: 56, height: 56, borderRadius: 16,
            background: 'linear-gradient(135deg, var(--accent), #a78bfa)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto',
            boxShadow: '0 8px 24px rgba(124,92,252,0.3)',
          }}>
            <Zap className="w-7 h-7 text-white" />
          </div>
          <h1>DevPulse Admin</h1>
          <p>Sign in to manage your platform</p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {error && (
            <div className="flex items-center gap-2 p-3 rounded-md bg-red-900/30 border border-red-800 text-red-300 text-sm">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <div>
            <label htmlFor="email" style={{ display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 8, letterSpacing: '0.3px' }}>
              USERNAME
            </label>
            <Input
              id="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin"
              required
            />
          </div>

          <div>
            <label htmlFor="password" style={{ display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 8, letterSpacing: '0.3px' }}>
              PASSWORD
            </label>
            <Input
              id="password"
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          <Button
            type="submit"
            loading={loading}
            size="lg"
            icon={<LogIn className="w-4 h-4" />}
            style={{ marginTop: 8 }}
          >
            {loading ? 'Signing in...' : 'Sign in'}
          </Button>
        </form>
      </div>
    </div>
  );
}
