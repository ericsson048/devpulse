import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import type { Course, CourseCreate } from '../types';
import Table, { type ColumnDef } from '../components/ui/Table';
import Button from '../components/ui/Button';
import Dialog from '../components/ui/Dialog';
import { Input, Textarea } from '../components/ui/Input';
import InputNumber from '../components/ui/InputNumber';
import Select from '../components/ui/Select';
import Toggle from '../components/ui/Toggle';
import Badge from '../components/ui/Badge';
import ConfirmDialog, { confirmDialog } from '../components/ui/ConfirmDialog';
import { useToast } from '../components/Toast';
import { Plus, Pencil, Trash2, CheckCircle, XCircle } from 'lucide-react';

const LEVELS = [
  { label: 'Beginner', value: 'beginner' },
  { label: 'Intermediate', value: 'intermediate' },
  { label: 'Advanced', value: 'advanced' },
];

const emptyForm: CourseCreate = {
  title: '', description: '', level: 'beginner', language: '', tag: '', icon: '', is_published: false, sort_order: 0, total_xp: 0,
};

const labelStyle: React.CSSProperties = {
  display: 'block', fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', marginBottom: 6, letterSpacing: '0.3px',
};

export default function Courses() {
  const { toast } = useToast();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [showDialog, setShowDialog] = useState(false);
  const [editing, setEditing] = useState<Course | null>(null);
  const [form, setForm] = useState<CourseCreate>({ ...emptyForm });
  const [saving, setSaving] = useState(false);
  const [publishingId, setPublishingId] = useState<number | null>(null);

  const load = () => {
    setLoading(true);
    api.getCourses(false).then(setCourses).finally(() => setLoading(false));
  };
  useEffect(load, []);

  const openCreate = () => {
    setEditing(null);
    setForm({ ...emptyForm });
    setShowDialog(true);
  };

  const openEdit = (c: Course) => {
    setEditing(c);
    setForm({
      title: c.title, description: c.description || '', level: c.level,
      language: c.language || '', tag: c.tag || '', icon: c.icon || '',
      is_published: c.is_published, sort_order: c.sort_order, total_xp: c.total_xp,
    });
    setShowDialog(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (editing) { await api.updateCourse(editing.id, form); toast('Course updated', 'success'); }
      else { await api.createCourse(form); toast('Course created', 'success'); }
      setShowDialog(false);
      load();
    } catch (e) { toast((e as Error).message, 'error'); }
    finally { setSaving(false); }
  };

  const handleDelete = (id: number) => {
    confirmDialog({ message: 'Delete this course?', header: 'Confirm', accept: async () => { try { await api.deleteCourse(id); load(); toast('Course deleted', 'success'); } catch (e) { toast((e as Error).message, 'error'); } } });
  };

  const togglePublish = async (c: Course) => {
    setPublishingId(c.id);
    try {
      await api.updateCourse(c.id, { is_published: !c.is_published });
      load();
      toast(c.is_published ? 'Course unpublished' : 'Course published', 'success');
    } catch (e) { toast((e as Error).message, 'error'); }
    finally { setPublishingId(null); }
  };

  const columns: ColumnDef<Course>[] = [
    {
      header: 'Title', sortable: true, sortField: 'title', style: { minWidth: 220 },
      body: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Link to={`/courses/${row.id}`} style={{ fontWeight: 600, color: 'var(--accent)', textDecoration: 'none' }}>
            {/* {row.icon && <span style={{ marginRight: 6 }}>{row.icon}</span>} */}
            {row.title}
          </Link>
          {row.tag && <Badge value={row.tag} severity="info" className="text-[10px] px-1.5 py-0.5" />}
        </div>
      ),
    },
    {
      header: 'Level', sortable: true, sortField: 'level', style: { width: 130 },
      body: (row) => {
        const sev = row.level === 'beginner' ? 'success' : row.level === 'intermediate' ? 'warning' : 'danger';
        return <Badge value={row.level} severity={sev} />;
      },
    },
    { header: 'Language', field: 'language', sortable: true, style: { width: 110 } },
    { header: 'Modules', field: 'total_modules', sortable: true, style: { width: 95 } },
    { header: 'XP', field: 'total_xp', sortable: true, style: { width: 90 } },
    {
      header: 'Status', style: { width: 150 },
      body: (row) => (
        <button
          onClick={() => togglePublish(row)}
          disabled={publishingId === row.id}
          className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
            row.is_published ? 'bg-green-900/40 text-green-300 hover:bg-green-800/50' : 'bg-gray-700 text-gray-400 hover:bg-gray-600'
          } ${publishingId === row.id ? 'opacity-50 pointer-events-none' : ''}`}
        >
          {row.is_published ? <CheckCircle className="w-3.5 h-3.5" /> : <XCircle className="w-3.5 h-3.5" />}
          {row.is_published ? 'Published' : 'Draft'}
        </button>
      ),
    },
    {
      header: 'Actions', style: { width: 100 },
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
          <h1>Courses</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
            {courses.length} course{courses.length !== 1 ? 's' : ''}
          </p>
        </div>
        <Button icon={<Plus className="w-4 h-4" />} onClick={openCreate}>Add Course</Button>
      </div>

      <Table
        value={courses}
        columns={columns}
        loading={loading}
        striped
        paginator
        rows={15}
        emptyMessage="No courses yet — create your first course!"
        sortField="sort_order"
        sortOrder={1}
      />

      <Dialog
        header={editing ? 'Edit Course' : 'New Course'}
        visible={showDialog}
        onHide={() => setShowDialog(false)}
        width="540px"
        footer={<><Button variant="ghost" onClick={() => setShowDialog(false)} disabled={saving}>Cancel</Button><Button onClick={handleSubmit} loading={saving}>{editing ? 'Update' : 'Create'}</Button></>}
      >
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16, paddingTop: 12 }}>
          <div>
            <label style={labelStyle}>Title *</label>
            <Input value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} required />
          </div>
          <div>
            <label style={labelStyle}>Description</label>
            <Textarea value={form.description || ''} onChange={e => setForm({ ...form, description: e.target.value })} rows={3} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Level</label>
              <Select value={form.level} options={LEVELS} onChange={e => setForm({ ...form, level: e.value })} />
            </div>
            <div>
              <label style={labelStyle}>Language</label>
              <Input value={form.language || ''} onChange={e => setForm({ ...form, language: e.target.value })} placeholder="python, dart..." />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Icon</label>
              <Input value={form.icon || ''} onChange={e => setForm({ ...form, icon: e.target.value })} placeholder="emoji or name" />
            </div>
            <div>
              <label style={labelStyle}>Tag</label>
              <Input value={form.tag || ''} onChange={e => setForm({ ...form, tag: e.target.value })} placeholder="New, Popular..." />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Total XP</label>
              <InputNumber value={form.total_xp || 0} onValueChange={e => setForm({ ...form, total_xp: e.value || 0 })} />
            </div>
            <div>
              <label style={labelStyle}>Sort Order</label>
              <InputNumber value={form.sort_order || 0} onValueChange={e => setForm({ ...form, sort_order: e.value || 0 })} />
            </div>
          </div>
          <div>
            <Toggle
              checked={form.is_published || false}
              onChange={e => setForm({ ...form, is_published: e.value })}
              onLabel="Published"
              offLabel="Draft"
            />
          </div>
        </form>
      </Dialog>
    </div>
  );
}
