import { useState, type FormEvent } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { InputText } from 'primereact/inputtext';
import { Password } from 'primereact/password';
import { Button } from 'primereact/button';
import { Message } from 'primereact/message';

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
            <i className="pi pi-bolt" style={{ fontSize: 28, color: '#fff' }} />
          </div>
          <h1>DevPulse Admin</h1>
          <p>Sign in to manage your platform</p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
          {error && (
            <Message severity="error" text={error} style={{ width: '100%' }} />
          )}

          <div>
            <label htmlFor="email" style={{ display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 8, letterSpacing: '0.3px' }}>
              USERNAME
            </label>
            <InputText
              id="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin"
              className="w-full"
              required
            />
          </div>

          <div>
            <label htmlFor="password" style={{ display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 8, letterSpacing: '0.3px' }}>
              PASSWORD
            </label>
            <Password
              id="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              feedback={false}
              toggleMask
              className="w-full"
              inputClassName="w-full"
              required
            />
          </div>

          <Button
            type="submit"
            label={loading ? 'Signing in...' : 'Sign in'}
            icon="pi pi-sign-in"
            loading={loading}
            className="w-full"
            size="large"
            style={{ marginTop: 8 }}
          />
        </form>
      </div>
    </div>
  );
}
