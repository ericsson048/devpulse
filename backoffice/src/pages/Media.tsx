import { useEffect, useState } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { ConfirmDialog, confirmDialog } from 'primereact/confirmdialog';
import { api } from '../api';

interface MediaItem {
  id: number;
  filename: string;
  url: string;
  mime_type: string;
  file_size: number;
}

export default function Media() {
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
    confirmDialog({
      message: 'Delete this file permanently?',
      header: 'Confirm',
      icon: 'pi pi-exclamation-triangle',
      accept: async () => { await api.deleteMedia(id); load(); }
    });
  };

  const sizeBody = (row: MediaItem) => {
    if (!row.file_size) return '-';
    const kb = row.file_size / 1024;
    return kb > 1024 ? `${(kb / 1024).toFixed(1)} MB` : `${kb.toFixed(0)} KB`;
  };

  const previewBody = (row: MediaItem) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      {row.mime_type?.startsWith('image/')
        ? <img src={row.url} alt="" style={{ width: 36, height: 36, borderRadius: 6, objectFit: 'cover' }} />
        : <i className="pi pi-file" style={{ fontSize: 20, color: 'var(--text-dim)' }} />
      }
      <span style={{ fontWeight: 500 }}>{row.filename}</span>
    </div>
  );

  const actionsBody = (row: MediaItem) => (
    <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDelete(row.id)} />
  );

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

      <DataTable value={items} loading={loading} stripedRows paginator rows={20}
        emptyMessage="No media files uploaded yet."
        className="p-datatable-sm" dataKey="id">
        <Column header="File" body={previewBody} style={{ minWidth: 240 }} />
        <Column header="Type" field="mime_type" style={{ width: 150 }} />
        <Column header="Size" body={sizeBody} style={{ width: 100 }} />
        <Column header="Actions" body={actionsBody} style={{ width: 80 }} />
      </DataTable>
    </div>
  );
}
