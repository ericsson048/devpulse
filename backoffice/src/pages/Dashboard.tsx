import { useEffect, useState } from 'react';
import { api } from '../api';
import type { BackofficeDashboard } from '../types';
import { Users, BookOpen, GitBranch, HelpCircle, TrendingUp, Trophy, Loader2 } from 'lucide-react';

const iconMap: Record<string, React.ReactNode> = {
  'Total Users': <Users className="w-5 h-5" />,
  'Courses': <BookOpen className="w-5 h-5" />,
  'Modules': <GitBranch className="w-5 h-5" />,
  'Quizzes': <HelpCircle className="w-5 h-5" />,
  'Active Today': <TrendingUp className="w-5 h-5" />,
  'Quiz Attempts': <Trophy className="w-5 h-5" />,
};

export default function Dashboard() {
  const [data, setData] = useState<BackofficeDashboard | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.getDashboard().then(setData).finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div className="page">
      <div className="page-header"><h1>Dashboard</h1></div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 200 }}>
        <Loader2 className="w-8 h-8 text-[var(--accent)] animate-spin" />
      </div>
    </div>
  );
  if (!data) return <div className="page page-error">Failed to load dashboard</div>;

  const cards = [
    { label: 'Total Users', value: data.total_users, color: '#7c5cfc', bg: 'rgba(124,92,252,0.12)' },
    { label: 'Courses', value: data.total_courses, color: '#34d399', bg: 'rgba(52,211,153,0.12)' },
    { label: 'Modules', value: data.total_modules, color: '#fbbf24', bg: 'rgba(251,191,36,0.12)' },
    { label: 'Quizzes', value: data.total_quizzes, color: '#f87171', bg: 'rgba(248,113,113,0.12)' },
    { label: 'Active Today', value: data.active_users_today, color: '#a78bfa', bg: 'rgba(167,139,250,0.12)' },
    { label: 'Quiz Attempts', value: data.total_quiz_attempts, color: '#22d3ee', bg: 'rgba(34,211,238,0.12)' },
  ];

  return (
    <div className="page fade-in">
      <div className="page-header">
        <div>
          <h1>Dashboard</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>Overview of your learning platform</p>
        </div>
      </div>

      <div className="stats-grid">
        {cards.map((c, i) => (
          <div key={c.label} className="stat-card" style={{ animationDelay: `${i * 60}ms` }}>
            <div className="stat-icon" style={{ background: c.bg, color: c.color }}>
              {iconMap[c.label]}
            </div>
            <div>
              <div className="stat-value">{c.value.toLocaleString()}</div>
              <div className="stat-label">{c.label}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
