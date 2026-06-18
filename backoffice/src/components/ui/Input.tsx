import type { InputHTMLAttributes, TextareaHTMLAttributes } from 'react';

const base = 'w-full bg-[var(--bg-input)] border border-[var(--border-default)] rounded-lg px-3 py-2 text-sm text-[var(--text-primary)] placeholder-[var(--text-dim)] focus:outline-none focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]/40 transition-all duration-150';

export function Input(props: InputHTMLAttributes<HTMLInputElement>) {
  return <input className={base} {...props} />;
}

export function Textarea(props: TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return <textarea className={base + ' resize-vertical min-h-[80px]'} {...props} />;
}
