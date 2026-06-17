import { useEffect, useState, type FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api';
import type { Course, CourseCreate } from '../types';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { Dialog } from 'primereact/dialog';
import { InputText } from 'primereact/inputtext';
import { InputTextarea } from 'primereact/inputtextarea';
import { InputNumber } from 'primereact/inputnumber';
import { Dropdown } from 'primereact/dropdown';
import { ToggleButton } from 'primereact/togglebutton';
import { Tag } from 'primereact/tag';

const LEVELS = [
  { label: 'Beginner', value: 'beginner' },
  { label: 'Intermediate', value: 'intermediate' },
  { label: 'Advanced', value: 'advanced' },
];

const emptyForm: CourseCreate = {
  title: '', description: '', level: 'beginner', language: '', tag: '', icon: '', is_published: false, sort_order: 0, total_xp: 0,
};

export default function Courses() {
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);
  const [showDialog, setShowDialog] = useState(false);
  const [editing, setEditing] = useState<Course | null>(null);
  const [form, setForm] = useState<CourseCreate>({ ...emptyForm });

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
    if (editing) await api.updateCourse(editing.id, form);
    else await api.createCourse(form);
    setShowDialog(false);
    load();
  };

  const handleDelete = async (id: number) => {
    if (confirm('Delete this course?')) {
      await api.deleteCourse(id);
      load();
    }
  };

  const togglePublish = async (c: Course) => {
    await api.updateCourse(c.id, { is_published: !c.is_published });
    load();
  };

  const titleBody = (row: Course) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <Link to={`/courses/${row.id}`} style={{ fontWeight: 600, color: 'var(--accent)', textDecoration: 'none' }}>
        {row.icon && <span style={{ marginRight: 6 }}>{row.icon}</span>}
        {row.title}
      </Link>
      {row.tag && <Tag value={row.tag} severity="info" rounded style={{ fontSize: 10, padding: '2px 8px' }} />}
    </div>
  );

  const levelBody = (row: Course) => {
    const sev = row.level === 'beginner' ? 'success' : row.level === 'intermediate' ? 'warning' : 'danger';
    return <Tag value={row.level} severity={sev} rounded />;
  };

  const statusBody = (row: Course) => (
    <ToggleButton
      checked={row.is_published}
      onChange={() => togglePublish(row)}
      onLabel="Published"
      offLabel="Draft"
      onIcon="pi pi-check-circle"
      offIcon="pi pi-minus-circle"
      className="p-button-sm"
    />
  );

  const actionsBody = (row: Course) => (
    <div style={{ display: 'flex', gap: 4 }}>
      <Button icon="pi pi-pencil" severity="info" text rounded size="small" onClick={() => openEdit(row)} tooltip="Edit" tooltipOptions={{ position: 'top' }} />
      <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDelete(row.id)} tooltip="Delete" tooltipOptions={{ position: 'top' }} />
    </div>
  );

  const dialogFooter = (
    <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}>
      <Button label="Cancel" icon="pi pi-times" text onClick={() => setShowDialog(false)} />
      <Button label={editing ? 'Update' : 'Create'} icon="pi pi-check" onClick={handleSubmit} />
    </div>
  );

  return (
    <div className="page fade-in">
      <div className="page-header">
        <div>
          <h1>Courses</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
            {courses.length} course{courses.length !== 1 ? 's' : ''}
          </p>
        </div>
        <Button label="Add Course" icon="pi pi-plus" onClick={openCreate} />
      </div>

      <DataTable
        value={courses}
        loading={loading}
        stripedRows
        paginator
        rows={15}
        emptyMessage="No courses yet — create your first course!"
        className="p-datatable-sm"
        sortMode="single"
        sortField="sort_order"
        sortOrder={1}
      >
        <Column header="Title" body={titleBody} sortable sortField="title" style={{ minWidth: 220 }} />
        <Column header="Level" body={levelBody} sortable sortField="level" style={{ width: 130 }} />
        <Column field="language" header="Language" sortable style={{ width: 110 }} />
        <Column field="total_modules" header="Modules" sortable style={{ width: 95 }} />
        <Column field="total_xp" header="XP" sortable style={{ width: 90 }} />
        <Column header="Status" body={statusBody} style={{ width: 150 }} />
        <Column header="Actions" body={actionsBody} style={{ width: 100 }} />
      </DataTable>

      <Dialog
        header={editing ? 'Edit Course' : 'New Course'}
        visible={showDialog}
        onHide={() => setShowDialog(false)}
        style={{ width: 540 }}
        footer={dialogFooter}
        modal
        draggable={false}
      >
        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 16, paddingTop: 12 }}>
          <div>
            <label style={labelStyle}>Title *</label>
            <InputText value={form.title} onChange={e => setForm({ ...form, title: e.target.value })} className="w-full" required />
          </div>
          <div>
            <label style={labelStyle}>Description</label>
            <InputTextarea value={form.description || ''} onChange={e => setForm({ ...form, description: e.target.value })} className="w-full" rows={3} />
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Level</label>
              <Dropdown value={form.level} options={LEVELS} onChange={e => setForm({ ...form, level: e.value })} className="w-full" />
            </div>
            <div>
              <label style={labelStyle}>Language</label>
              <InputText value={form.language || ''} onChange={e => setForm({ ...form, language: e.target.value })} className="w-full" placeholder="python, dart..." />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Icon</label>
              <InputText value={form.icon || ''} onChange={e => setForm({ ...form, icon: e.target.value })} className="w-full" placeholder="emoji or name" />
            </div>
            <div>
              <label style={labelStyle}>Tag</label>
              <InputText value={form.tag || ''} onChange={e => setForm({ ...form, tag: e.target.value })} className="w-full" placeholder="New, Popular..." />
            </div>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div>
              <label style={labelStyle}>Total XP</label>
              <InputNumber value={form.total_xp || 0} onValueChange={e => setForm({ ...form, total_xp: e.value || 0 })} className="w-full" />
            </div>
            <div>
              <label style={labelStyle}>Sort Order</label>
              <InputNumber value={form.sort_order || 0} onValueChange={e => setForm({ ...form, sort_order: e.value || 0 })} className="w-full" />
            </div>
          </div>
          <div>
            <ToggleButton
              checked={form.is_published || false}
              onChange={e => setForm({ ...form, is_published: e.value })}
              onLabel="Published"
              offLabel="Draft"
              onIcon="pi pi-check"
              offIcon="pi pi-times"
            />
          </div>
        </form>
      </Dialog>
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  display: 'block',
  fontSize: 12,
  fontWeight: 600,
  color: 'var(--text-secondary)',
  marginBottom: 6,
  letterSpacing: '0.3px',
};
