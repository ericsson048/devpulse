import type { ReactNode } from 'react';

interface BadgeProps {
  value: string;
  severity?: 'info' | 'success' | 'warning' | 'danger' | 'secondary';
  icon?: ReactNode;
  className?: string;
}

const severityClasses = {
  info: 'bg-blue-900/40 text-blue-300',
  success: 'bg-green-900/40 text-green-300',
  warning: 'bg-yellow-900/40 text-yellow-300',
  danger: 'bg-red-900/40 text-red-300',
  secondary: 'bg-gray-700 text-gray-400',
};

export default function Badge({ value, severity = 'info', icon, className = '' }: BadgeProps) {
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${severityClasses[severity]} ${className}`}>
      {icon}
      {value}
    </span>
  );
}
