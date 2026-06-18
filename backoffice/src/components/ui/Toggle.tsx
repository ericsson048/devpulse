interface ToggleProps {
  checked?: boolean;
  onChange?: (e: { value: boolean }) => void;
  onLabel?: string;
  offLabel?: string;
}

export default function Toggle({ checked, onChange, onLabel, offLabel }: ToggleProps) {
  return (
    <button
      type="button"
      onClick={() => onChange?.({ value: !checked })}
      className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all duration-150 ${
        checked
          ? 'bg-[var(--accent)] text-white shadow-sm shadow-[var(--accent-glow)]'
          : 'bg-[var(--bg-surface)] text-[var(--text-secondary)] border border-[var(--border-default)] hover:border-[var(--border-hover)]'
      }`}
    >
      {checked ? onLabel || 'On' : offLabel || 'Off'}
    </button>
  );
}
