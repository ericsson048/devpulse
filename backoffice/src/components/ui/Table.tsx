import { useState, useMemo, type ReactNode } from 'react';
import { ChevronUp, ChevronDown, ChevronLeft, ChevronRight, ChevronsLeft, ChevronsRight, Loader2, Inbox } from 'lucide-react';

export interface ColumnDef<T> {
  header?: string;
  field?: string;
  body?: (row: T) => ReactNode;
  sortable?: boolean;
  sortField?: string;
  style?: React.CSSProperties;
  className?: string;
}

interface TableProps<T> {
  value: T[];
  columns: ColumnDef<T>[];
  loading?: boolean;
  striped?: boolean;
  paginator?: boolean;
  rows?: number;
  emptyMessage?: string;
  sortField?: string;
  sortOrder?: 1 | -1;
  dataKey?: string;
}

export default function Table<T extends Record<string, unknown>>({
  value, columns, loading, striped, paginator, rows = 20, emptyMessage = 'No data',
  sortField: initialSortField, sortOrder: initialSortOrder, dataKey,
}: TableProps<T>) {
  const [sortField, setSortField] = useState(initialSortField || '');
  const [sortOrder, setSortOrder] = useState<1 | -1>(initialSortOrder || 1);
  const [page, setPage] = useState(0);

  const sorted = useMemo(() => {
    if (!sortField) return value;
    return [...value].sort((a, b) => {
      const av = a[sortField];
      const bv = b[sortField];
      if (av == null) return 1;
      if (bv == null) return -1;
      const cmp = typeof av === 'string'
        ? (av as string).localeCompare(String(bv))
        : Number(av) - Number(bv);
      return cmp * sortOrder;
    });
  }, [value, sortField, sortOrder]);

  const totalPages = Math.max(1, Math.ceil(sorted.length / rows));
  const paged = paginator ? sorted.slice(page * rows, (page + 1) * rows) : sorted;

  const handleSort = (col: ColumnDef<T>) => {
    const field = col.sortField || col.field || '';
    if (!field || !col.sortable) return;
    if (sortField === field) {
      setSortOrder(prev => prev === 1 ? -1 : 1);
    } else {
      setSortField(field);
      setSortOrder(1);
    }
  };

  const SortIcon = ({ col }: { col: ColumnDef<T> }) => {
    const field = col.sortField || col.field || '';
    if (!col.sortable) return null;
    if (sortField !== field) return <ChevronUp className="w-3 h-3 inline ml-1.5 opacity-0 group-hover:opacity-40 transition-opacity" />;
    return sortOrder === 1
      ? <ChevronUp className="w-3 h-3 inline ml-1.5 text-[var(--accent)]" />
      : <ChevronDown className="w-3 h-3 inline ml-1.5 text-[var(--accent)]" />;
  };

  const pageWindow = () => {
    const maxVisible = 5;
    if (totalPages <= maxVisible) return Array.from({ length: totalPages }, (_, i) => i);
    const half = Math.floor(maxVisible / 2);
    let start = page - half;
    let end = page + half + 1;
    if (start < 0) { start = 0; end = maxVisible; }
    if (end > totalPages) { end = totalPages; start = Math.max(0, end - maxVisible); }
    return Array.from({ length: end - start }, (_, i) => start + i);
  };

  return (
    <div className="rounded-xl border border-[var(--border-subtle)] bg-[var(--bg-card)] overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-[var(--border-subtle)] bg-black/20">
              {columns.map((col, i) => (
                <th
                  key={i}
                  onClick={() => handleSort(col)}
                  className={`group px-5 py-3.5 text-left text-xs font-semibold text-[var(--text-dim)] uppercase tracking-wider whitespace-nowrap ${
                    col.sortable ? 'cursor-pointer hover:text-[var(--text-primary)] select-none' : ''
                  } ${col.className || ''}`}
                  style={col.style}
                >
                  <span className="inline-flex items-center">
                    {col.header}
                    <SortIcon col={col} />
                  </span>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {loading ? (
              Array.from({ length: 6 }).map((_, i) => (
                <tr key={`skel-${i}`} className="border-b border-[var(--border-subtle)]">
                  {columns.map((_, j) => (
                    <td key={j} className="px-5 py-3.5">
                      <div
                        className="h-4 rounded-md animate-pulse"
                        style={{
                          width: `${40 + Math.random() * 50}%`,
                          background: 'var(--bg-card-hover)',
                        }}
                      />
                    </td>
                  ))}
                </tr>
              ))
            ) : paged.length === 0 ? (
              <tr>
                <td colSpan={columns.length}>
                  <div className="flex flex-col items-center justify-center py-16 text-[var(--text-dim)]">
                    <Inbox className="w-10 h-10 mb-3 opacity-40" />
                    <span className="text-sm">{emptyMessage}</span>
                  </div>
                </td>
              </tr>
            ) : (
              paged.map((row, ri) => (
                <tr
                  key={dataKey ? String(row[dataKey]) : ri}
                  className={`border-b border-[var(--border-subtle)] transition-colors ${
                    striped && ri % 2 === 1 ? 'bg-white/[0.015]' : ''
                  } hover:bg-[var(--accent-soft)]/40 hover:border-[var(--accent)]/20`}
                  style={striped && ri % 2 === 1 ? { background: 'rgba(255,255,255,0.015)' } : undefined}
                >
                  {columns.map((col, ci) => (
                    <td
                      key={ci}
                      className="px-5 py-3.5 text-[var(--text-primary)] text-sm"
                      style={col.style}
                    >
                      {col.body ? col.body(row) : col.field ? String(row[col.field] ?? '') : ''}
                    </td>
                  ))}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {paginator && !loading && sorted.length > 0 && (
        <div className="flex items-center justify-between px-5 py-3.5 border-t border-[var(--border-subtle)] bg-black/10">
          <span className="text-xs text-[var(--text-dim)] font-medium">
            {sorted.length} result{sorted.length !== 1 ? 's' : ''}
            {' — Page '}{page + 1}/{totalPages}
          </span>

          <div className="flex items-center gap-1">
            <PageBtn disabled={page === 0} onClick={() => setPage(0)} label={<ChevronsLeft className="w-3.5 h-3.5" />} />
            <PageBtn disabled={page === 0} onClick={() => setPage(p => p - 1)} label={<ChevronLeft className="w-3.5 h-3.5" />} />

            {pageWindow().map(i => (
              <button
                key={i}
                onClick={() => setPage(i)}
                className={`w-8 h-8 rounded-lg text-xs font-semibold transition-all ${
                  i === page
                    ? 'bg-[var(--accent)] text-white shadow-md shadow-[var(--accent)]/20 scale-105'
                    : 'text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-white/[0.06]'
                }`}
              >
                {i + 1}
              </button>
            ))}

            <PageBtn disabled={page >= totalPages - 1} onClick={() => setPage(p => p + 1)} label={<ChevronRight className="w-3.5 h-3.5" />} />
            <PageBtn disabled={page >= totalPages - 1} onClick={() => setPage(totalPages - 1)} label={<ChevronsRight className="w-3.5 h-3.5" />} />
          </div>
        </div>
      )}
    </div>
  );
}

function PageBtn({ disabled, onClick, label }: { disabled: boolean; onClick: () => void; label: ReactNode }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className="w-8 h-8 rounded-lg flex items-center justify-center text-[var(--text-secondary)] hover:text-[var(--text-primary)] hover:bg-white/[0.06] disabled:opacity-20 disabled:cursor-not-allowed transition-all"
    >
      {label}
    </button>
  );
}
