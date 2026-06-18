import { useState, useCallback } from 'react';
import { AlertTriangle, X } from 'lucide-react';
import Button from './Button';

interface ConfirmOptions {
  message: string;
  header?: string;
  accept?: () => void;
  reject?: () => void;
}

let globalConfirm: (opts: ConfirmOptions) => void = () => {};

export function confirmDialog(opts: ConfirmOptions) {
  globalConfirm(opts);
}

export default function ConfirmDialog() {
  const [open, setOpen] = useState(false);
  const [opts, setOpts] = useState<ConfirmOptions | null>(null);

  globalConfirm = useCallback((o: ConfirmOptions) => {
    setOpts(o);
    setOpen(true);
  }, []);

  const handleAccept = () => {
    opts?.accept?.();
    setOpen(false);
    setOpts(null);
  };

  const handleReject = () => {
    opts?.reject?.();
    setOpen(false);
    setOpts(null);
  };

  if (!open || !opts) return null;

  return (
    <div className="fixed inset-0 z-[60] flex items-center justify-center">
      <div className="fixed inset-0 bg-black/60 backdrop-blur-sm" onClick={handleReject} />
      <div className="relative bg-gray-900 border border-gray-700 rounded-xl shadow-2xl w-full max-w-sm mx-4">
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-700">
          <h3 className="font-semibold text-gray-100">{opts.header || 'Confirm'}</h3>
          <button type="button" onClick={handleReject} className="p-1 rounded-md text-gray-500 hover:text-white hover:bg-gray-700 transition-colors">
            <X className="w-4 h-4" />
          </button>
        </div>
        <div className="flex items-start gap-3 px-5 py-5">
          <div className="p-2 rounded-full bg-yellow-900/40 text-yellow-400 flex-shrink-0">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <p className="text-sm text-gray-300">{opts.message}</p>
        </div>
        <div className="flex justify-end gap-3 px-5 py-4 border-t border-gray-700">
          <Button variant="ghost" onClick={handleReject}>Cancel</Button>
          <Button variant="danger" onClick={handleAccept}>Delete</Button>
        </div>
      </div>
    </div>
  );
}
