import { useEffect, useState } from 'react';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { Dialog } from 'primereact/dialog';
import { InputText } from 'primereact/inputtext';
import { InputNumber } from 'primereact/inputnumber';
import { ConfirmDialog, confirmDialog } from 'primereact/confirmdialog';
import { api } from '../api';

interface Achievement {
  id: number;
  title: string;
  description: string | null;
  icon: string | null;
  icon_bg: string | null;
  icon_color: string | null;
  xp_reward: number;
  condition_type: string | null;
  condition_value: number | null;
}

export default function Achievements() {
  const [items, setItems] = useState<Achievement[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialog, setDialog] = useState(false);
  const [editing, setEditing] = useState<Achievement | null>(null);

  const empty: Achievement = { id: 0, title: '', description: '', icon: '', icon_bg: '#1E3A5F', icon_color: '#60A5FA', xp_reward: 100, condition_type: null, condition_value: null };
  const [form, setForm] = useState<Achievement>({ ...empty });

  const load = async () => {
    setLoading(true);
    try {
      const data = await api.listAchievements();
      setItems(data);
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);

  const openNew = () => { setForm({ ...empty }); setEditing(null); setDialog(true); };
  const openEdit = (ach: Achievement) => { setForm({ ...ach }); setEditing(ach); setDialog(true); };

  const save = async () => {
    try {
      if (editing) {
        await api.updateAchievement(editing.id, form);
      } else {
        await api.createAchievement(form);
      }
      setDialog(false);
      load();
    } catch (e) { alert(e); }
  };

  const handleDelete = (id: number) => {
    confirmDialog({
      message: 'Delete this achievement?',
      header: 'Confirm', icon: 'pi pi-exclamation-triangle',
      accept: async () => { await api.deleteAchievement(id); load(); }
    });
  };

  const iconBody = (row: Achievement) => (
    <div style={{ width: 32, height: 32, borderRadius: 8, backgroundColor: row.icon_bg || '#1E3A5F', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <i className="pi pi-star" style={{ fontSize: 14, color: row.icon_color || '#60A5FA' }} />
    </div>
  );

  const actionsBody = (row: Achievement) => (
    <div style={{ display: 'flex', gap: 4 }}>
      <Button icon="pi pi-pencil" text rounded size="small" onClick={() => openEdit(row)} />
      <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDelete(row.id)} />
    </div>
  );

  const dialogFooter = () => (
    <div>
      <Button label="Cancel" severity="secondary" text onClick={() => setDialog(false)} />
      <Button label={editing ? 'Save' : 'Create'} onClick={save} />
    </div>
  );

  return (
    <div className="page fade-in">
      <ConfirmDialog />
      <div className="page-header">
        <div>
          <h1>Achievements</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>{items.length} achievements</p>
        </div>
        <Button label="New Achievement" icon="pi pi-plus" onClick={openNew} />
      </div>

      <DataTable value={items} loading={loading} stripedRows paginator rows={20}
        emptyMessage="No achievements yet." className="p-datatable-sm" dataKey="id">
        <Column header="" body={iconBody} style={{ width: 60 }} />
        <Column header="Title" field="title" sortable style={{ minWidth: 180 }} />
        <Column header="Description" field="description" style={{ minWidth: 220 }} />
        <Column header="XP" field="xp_reward" sortable style={{ width: 80 }} />
        <Column header="Condition" body={(r: Achievement) => r.condition_type ? `${r.condition_type} >= ${r.condition_value}` : '-'} style={{ minWidth: 140 }} />
        <Column header="Actions" body={actionsBody} style={{ width: 110 }} />
      </DataTable>

      <Dialog header={editing ? 'Edit Achievement' : 'New Achievement'} visible={dialog} style={{ width: 480 }} onHide={() => setDialog(false)} footer={dialogFooter}>
        <div className="p-fluid" style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>TITLE</label>
            <InputText value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Achievement title" />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>DESCRIPTION</label>
            <InputText value={form.description || ''} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Brief description" />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>ICON (Material icon name)</label>
            <InputText value={form.icon || ''} onChange={e => setForm({ ...form, icon: e.target.value })} placeholder="e.g. shield_rounded" />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>BG COLOR</label>
              <InputText value={form.icon_bg || ''} onChange={e => setForm({ ...form, icon_bg: e.target.value })} placeholder="#1E3A5F" />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>ICON COLOR</label>
              <InputText value={form.icon_color || ''} onChange={e => setForm({ ...form, icon_color: e.target.value })} placeholder="#60A5FA" />
            </div>
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>XP REWARD</label>
            <InputNumber value={form.xp_reward} onValueChange={e => setForm({ ...form, xp_reward: e.value ?? 100 })}
              min={0} max={9999} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>CONDITION TYPE</label>
              <InputText value={form.condition_type || ''} onChange={e => setForm({ ...form, condition_type: e.target.value })} placeholder="e.g. lessons_complete" />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>CONDITION VALUE</label>
              <InputNumber value={form.condition_value} onValueChange={e => setForm({ ...form, condition_value: e.value })} min={0} />
            </div>
          </div>
        </div>
      </Dialog>
    </div>
  );
}
