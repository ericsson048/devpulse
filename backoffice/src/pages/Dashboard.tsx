import { useEffect, useState, useRef } from 'react';
import { api } from '../api';
import type { BackofficeDashboard, AdminDashboardCharts } from '../types';
import { Users, BookOpen, GitBranch, HelpCircle, TrendingUp, Trophy, Loader2 } from 'lucide-react';
import Highcharts from 'highcharts';

const iconMap: Record<string, React.ReactNode> = {
  'Total Users': <Users className="w-5 h-5" />,
  'Courses': <BookOpen className="w-5 h-5" />,
  'Modules': <GitBranch className="w-5 h-5" />,
  'Quizzes': <HelpCircle className="w-5 h-5" />,
  'Active Today': <TrendingUp className="w-5 h-5" />,
  'Quiz Attempts': <Trophy className="w-5 h-5" />,
};

function Chart({ options }: { options: Highcharts.Options }) {
  const ref = useRef<HTMLDivElement>(null);
  const chartRef = useRef<Highcharts.Chart | null>(null);

  useEffect(() => {
    if (!ref.current) return;
    chartRef.current = Highcharts.chart(ref.current, options);
    return () => { chartRef.current?.destroy(); };
  }, [options]);

  return <div ref={ref} />;
}

export default function Dashboard() {
  const [data, setData] = useState<BackofficeDashboard | null>(null);
  const [charts, setCharts] = useState<AdminDashboardCharts | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Highcharts.setOptions({
      chart: { backgroundColor: 'transparent', style: { fontFamily: 'Inter, sans-serif' } },
      title: { style: { color: '#9498b0', fontSize: '13px', fontWeight: 600 }, align: 'left' as const },
      legend: { itemStyle: { color: '#9498b0' }, itemHoverStyle: { color: '#f1f3f7' } },
      xAxis: { labels: { style: { color: '#5d6180', fontSize: '11px' } }, lineColor: 'rgba(255,255,255,0.06)', tickColor: 'rgba(255,255,255,0.06)' },
      yAxis: { labels: { style: { color: '#5d6180', fontSize: '11px' } }, gridLineColor: 'rgba(255,255,255,0.04)', title: { enabled: false } },
      tooltip: { backgroundColor: '#1a1d2b', borderColor: 'rgba(255,255,255,0.08)', style: { color: '#f1f3f7' } },
      plotOptions: {
        series: { dataLabels: { style: { color: '#f1f3f7', fontSize: '11px' } } },
        pie: { borderColor: 'transparent', dataLabels: { style: { color: '#f1f3f7', fontSize: '11px' } } },
      },
      credits: { enabled: false },
    });

    Promise.all([
      api.getDashboard(),
      api.getDashboardCharts(),
    ]).then(([d, c]) => {
      setData(d);
      setCharts(c);
    }).finally(() => setLoading(false));
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

  const gradeColors: Record<string, string> = { S: '#a78bfa', A: '#34d399', B: '#fbbf24', C: '#f97316', F: '#ef4444' };
  const gradeData = charts ? Object.entries(charts.quiz_grades).map(([name, y]) => ({ name, y, color: gradeColors[name] || '#6366f1' })) : [];

  const regChart: Highcharts.Options = {
    chart: { type: 'areaspline', height: 240 },
    title: { text: 'Registrations (12 weeks)' },
    xAxis: { categories: charts?.weekly_registrations.map(w => w.week.slice(5)) || [], crosshair: true },
    yAxis: { allowDecimals: false, min: 0 },
    series: [{
      type: 'areaspline',
      name: 'Users',
      data: charts?.weekly_registrations.map(w => w.count) || [],
      color: '#7c5cfc',
      fillColor: { linearGradient: [0, 0, 0, 1], stops: [[0, 'rgba(124,92,252,0.3)'], [1, 'rgba(124,92,252,0)']] } as any,
      marker: { radius: 4, fillColor: '#7c5cfc', lineColor: '#fff', lineWidth: 1 },
    }],
  };

  const quizAttemptChart: Highcharts.Options = {
    chart: { type: 'spline', height: 240 },
    title: { text: 'Quiz Attempts (12 weeks)' },
    xAxis: { categories: charts?.weekly_quiz_attempts.map(w => w.week.slice(5)) || [], crosshair: true },
    yAxis: { allowDecimals: false, min: 0 },
    series: [{
      type: 'spline',
      name: 'Attempts',
      data: charts?.weekly_quiz_attempts.map(w => w.count) || [],
      color: '#22d3ee',
      marker: { radius: 4, fillColor: '#22d3ee', lineColor: '#fff', lineWidth: 1 },
    }],
  };

  const gradeChart: Highcharts.Options = {
    chart: { type: 'pie', height: 240 },
    title: { text: 'Quiz Grades' },
    plotOptions: { pie: { innerSize: '55%', dataLabels: { enabled: true, format: '<b>{point.name}</b>: {point.y}' }, showInLegend: true } },
    series: [{ type: 'pie', name: 'Grade', data: gradeData }],
  };

  const levelChart: Highcharts.Options = {
    chart: { type: 'column', height: 240 },
    title: { text: 'Level Distribution' },
    xAxis: { categories: charts?.level_distribution.map(l => `Lv ${l.level}`) || [] },
    yAxis: { allowDecimals: false, min: 0 },
    series: [{
      type: 'column',
      name: 'Users',
      data: charts?.level_distribution.map(l => ({ y: l.count, color: '#6366f1' })) || [],
      borderRadius: 4,
    }],
  };

  const courses = charts?.course_progress || [];
  const progressChart: Highcharts.Options = {
    chart: { type: 'bar', height: 280 },
    title: { text: 'Course Progress' },
    xAxis: { categories: courses.map(c => c.course) },
    yAxis: { allowDecimals: false, min: 0, title: { text: 'Users' } as any },
    plotOptions: { bar: { stacking: 'normal' } },
    series: [
      { type: 'bar', name: 'Completed', data: courses.map(c => c.completed), color: '#34d399' },
      { type: 'bar', name: 'In Progress', data: courses.map(c => c.in_progress), color: '#fbbf24' },
      { type: 'bar', name: 'Not Started', data: courses.map(c => c.not_started), color: '#5d6180' },
    ],
  };

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

      {charts && (
        <>
          <div className="charts-grid">
            <div className="chart-card"><Chart options={regChart} /></div>
            <div className="chart-card"><Chart options={quizAttemptChart} /></div>
          </div>
          <div className="charts-grid">
            <div className="chart-card"><Chart options={gradeChart} /></div>
            <div className="chart-card"><Chart options={levelChart} /></div>
          </div>
          {courses.length > 0 && (
            <div className="charts-grid">
              <div className="chart-card full"><Chart options={progressChart} /></div>
            </div>
          )}
        </>
      )}
    </div>
  );
}
