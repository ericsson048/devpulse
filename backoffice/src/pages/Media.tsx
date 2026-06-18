import { useEffect, useState } from 'react';
import Table, { type ColumnDef } from '../components/ui/Table';
import Button from '../components/ui/Button';
import ConfirmDialog, { confirmDialog } from '../components/ui/ConfirmDialog';
import { useToast } from '../components/Toast';
import { api } from '../api';
import { File, Trash2 } from 'lucide-react';

interface MediaItem {
  id: number;
  filename: string;
  url: string;
  mime_type: string;
  file_size: number;
}

export default function Media() {
  const { toast } = useToast();
  const [items, setItems] = useState<MediaItem[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const data = await api.listMedia();
      setItems(data);
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);

  const handleDelete = (id: number) => {
    confirmDialog({ message: 'Delete this file permanently?', header: 'Confirm', accept: async () => { try { await api.deleteMedia(id); load(); toast('File deleted', 'success'); } catch (e) { toast((e as Error).message, 'error'); } } });
  };

  const columns: ColumnDef<MediaItem>[] = [
    {
      header: 'File', style: { minWidth: 240 },
      body: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {row.mime_type?.startsWith('image/')
            ? <img src={row.url} alt="" style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
            : <File className="w-5 h-5 text-gray-500" />
          }
          <span style={{ fontWeight: 500 }}>{row.filename}</span>
        </div>
      ),
    },
    { header: 'Type', field: 'mime_type', style: { width: 150 } },
    {
      header: 'Size', style: { width: 100 },
      body: (row) => {
        if (!row.file_size) return '-';
        const kb = row.file_size / 1024;
        return kb > 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${kb.toFixed(0)} KB`;
      },
    },
    {
      header: 'Actions', style: { width: 80 },
      body: (row) => (
        <button className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors" onClick={() => handleDelete(row.id)} title="Delete">
          <Trash2 className="w-4 h-4" />
        </button>
      ),
    },
  ];

  return (
    <div className="page fade-in">
      <ConfirmDialog />
      <div className="page-header">
        <div>
          <h1>Media</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
            {items.length} file{items.length !== 1 ? 's' : ''}
          </p>
        </div>
      </div>

      <Table value={items} columns={columns} loading={loading} striped paginator rows={20}
        emptyMessage="No media files uploaded yet." dataKey="id" />
    </div>
  );
}
