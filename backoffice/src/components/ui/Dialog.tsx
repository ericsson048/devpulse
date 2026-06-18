import type { ReactNode } from 'react';
import { X } from 'lucide-react';

interface DialogProps {
  header?: ReactNode;
  visible: boolean;
  onHide: () => void;
  children: ReactNode;
  footer?: ReactNode;
  width?: string;
}

export default function Dialog({ header, visible, onHide, children, footer, width = '540px' }: DialogProps) {
  if (!visible) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/[0.55] backdrop-blur-sm" onClick={onHide} />
      <div
        className="relative bg-[var(--bg-card)] border border-[var(--border-default)] rounded-xl shadow-2xl max-h-[85vh] overflow-y-auto animate-[fadeIn_0.15s_ease]"
        style={{ width, maxWidth: '92vw' }}
      >
        {header && (
          <div className="flex items-center justify-between px-5 py-4 border-b border-[var(--border-subtle)]">
            <h2 className="text-base font-semibold text-[var(--text-primary)]">{header}</h2>
            <button
              type="button"
              onClick={onHide}
              className="p-1.5 rounded-lg text-[var(--text-dim)] hover:text-[var(--text-primary)] hover:bg-white/[0.04] transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}
        <div className="px-5 py-4">{children}</div>
        {footer && (
          <div className="flex justify-end gap-3 px-5 py-4 border-t border-[var(--border-subtle)]">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
