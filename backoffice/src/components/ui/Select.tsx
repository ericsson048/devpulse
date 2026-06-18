interface SelectOption {
  label: string;
  value: string;
}

interface SelectProps {
  value?: string;
  options: SelectOption[];
  onChange?: (e: { value: string }) => void;
  className?: string;
}

export default function Select({ value, options, onChange, className = '' }: SelectProps) {
  return (
    <select
      value={value}
      onChange={e => onChange?.({ value: e.target.value })}
      className={`w-full bg-[var(--bg-input)] border border-[var(--border-default)] rounded-lg px-3 py-2 text-sm text-[var(--text-primary)] focus:outline-none focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]/40 transition-all duration-150 ${className}`}
    >
      {options.map(o => (
        <option key={o.value} value={o.value}>{o.label}</option>
      ))}
    </select>
  );
}
