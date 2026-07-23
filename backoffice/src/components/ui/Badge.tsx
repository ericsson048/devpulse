import type { ReactNode } from 'react';

interface BadgeProps {
  value: string;
  severity?: 'info' | 'success' | 'warning' | 'danger' | 'secondary';
  icon?: ReactNode;
  className?: string;
}

const severityClasses = {
  info: 'bg-[var(--accent-soft)] text-[var(--accent)]',
  success: 'bg-[var(--green-soft)] text-[var(--green)]',
  warning: 'bg-[var(--amber-soft)] text-[var(--amber)]',
  danger: 'bg-[var(--red-soft)] text-[var(--red)]',
  secondary: 'bg-[var(--bg-surface)] text-[var(--text-dim)]',
};

export default function Badge({ value, severity = 'info', icon, className = '' }: BadgeProps) {
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${severityClasses[severity]} ${className}`}>
      {icon}
      {value}
    </span>
  );
}
