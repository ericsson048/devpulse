interface InputNumberProps {
  value?: number | null;
  onValueChange?: (e: { value?: number | null }) => void;
  min?: number;
  max?: number;
  className?: string;
  placeholder?: string;
}

export default function InputNumber({ value, onValueChange, min, max, className = '', placeholder }: InputNumberProps) {
  return (
    <input
      type="number"
      value={value ?? ''}
      onChange={e => onValueChange?.({ value: e.target.value === '' ? null : Number(e.target.value) })}
      min={min}
      max={max}
      placeholder={placeholder}
      className={`w-full bg-[var(--bg-input)] border border-[var(--border-default)] rounded-lg px-3 py-2 text-sm text-[var(--text-primary)] placeholder-[var(--text-dim)] focus:outline-none focus:border-[var(--accent)] focus:ring-1 focus:ring-[var(--accent)]/40 transition-all duration-150 ${className}`}
    />
  );
}
