import { useEffect, useState } from 'react';
import { api } from '../api';
import Table, { type ColumnDef } from '../components/ui/Table';
import Button from '../components/ui/Button';
import Dialog from '../components/ui/Dialog';
import { Input, Textarea } from '../components/ui/Input';
import InputNumber from '../components/ui/InputNumber';
import ConfirmDialog, { confirmDialog } from '../components/ui/ConfirmDialog';
import { useToast } from '../components/Toast';
import { Plus, Pencil, Trash2, Star } from 'lucide-react';

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
  const { toast } = useToast();
  const [items, setItems] = useState<Achievement[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialog, setDialog] = useState(false);
  const [editing, setEditing] = useState<Achievement | null>(null);
  const [saving, setSaving] = useState(false);

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
    setSaving(true);
    try {
      if (editing) { await api.updateAchievement(editing.id, form); toast('Achievement updated', 'success'); }
      else { await api.createAchievement(form); toast('Achievement created', 'success'); }
      setDialog(false);
      load();
    } catch (e) { toast((e as Error).message, 'error'); }
    finally { setSaving(false); }
  };

  const handleDelete = (id: number) => {
    confirmDialog({ message: 'Delete this achievement?', header: 'Confirm', accept: async () => { try { await api.deleteAchievement(id); load(); toast('Achievement deleted', 'success'); } catch (e) { toast((e as Error).message, 'error'); } } });
  };

  const columns: ColumnDef<Achievement>[] = [
    {
      header: '', style: { width: 60 },
      body: (row) => (
        <div style={{ width: 32, height: 32, borderRadius: 8, backgroundColor: row.icon_bg || '#1E3A5F', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <Star className="w-3.5 h-3.5" style={{ color: row.icon_color || '#60A5FA' }} />
        </div>
      ),
    },
    { header: 'Title', field: 'title', sortable: true, style: { minWidth: 180 } },
    { header: 'Description', field: 'description', style: { minWidth: 220 } },
    { header: 'XP', field: 'xp_reward', sortable: true, style: { width: 80 } },
    {
      header: 'Condition', style: { minWidth: 140 },
      body: (r) => r.condition_type ? `${r.condition_type} >= ${r.condition_value}` : '-',
    },
    {
      header: 'Actions', style: { width: 110 },
      body: (row) => (
        <div style={{ display: 'flex', gap: 4 }}>
          <button className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors" onClick={() => openEdit(row)} title="Edit">
            <Pencil className="w-4 h-4" />
          </button>
          <button className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors" onClick={() => handleDelete(row.id)} title="Delete">
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      ),
    },
  ];

  return (
    <div className="page fade-in">
      <ConfirmDialog />
      <div className="page-header">
        <div>
          <h1>Achievements</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>{items.length} achievements</p>
        </div>
        <Button icon={<Plus className="w-4 h-4" />} onClick={openNew}>New Achievement</Button>
      </div>

      <Table value={items} columns={columns} loading={loading} striped paginator rows={20}
        emptyMessage="No achievements yet." dataKey="id" />

      <Dialog header={editing ? 'Edit Achievement' : 'New Achievement'} visible={dialog} width="480px" onHide={() => setDialog(false)}
        footer={<><Button variant="ghost" onClick={() => setDialog(false)} disabled={saving}>Cancel</Button><Button onClick={save} loading={saving}>{editing ? 'Save' : 'Create'}</Button></>}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>TITLE</label>
            <Input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} placeholder="Achievement title" />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>DESCRIPTION</label>
            <Input value={form.description || ''} onChange={e => setForm({ ...form, description: e.target.value })} placeholder="Brief description" />
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>ICON (Material icon name)</label>
            <Input value={form.icon || ''} onChange={e => setForm({ ...form, icon: e.target.value })} placeholder="e.g. shield_rounded" />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>BG COLOR</label>
              <Input value={form.icon_bg || ''} onChange={e => setForm({ ...form, icon_bg: e.target.value })} placeholder="#1E3A5F" />
            </div>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>ICON COLOR</label>
              <Input value={form.icon_color || ''} onChange={e => setForm({ ...form, icon_color: e.target.value })} placeholder="#60A5FA" />
            </div>
          </div>
          <div>
            <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>XP REWARD</label>
            <InputNumber value={form.xp_reward} onValueChange={e => setForm({ ...form, xp_reward: e.value ?? 100 })} min={0} max={9999} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <div>
              <label style={{ display: 'block', marginBottom: 4, fontSize: 12, color: 'var(--text-dim)' }}>CONDITION TYPE</label>
              <Input value={form.condition_type || ''} onChange={e => setForm({ ...form, condition_type: e.target.value })} placeholder="e.g. lessons_complete" />
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
