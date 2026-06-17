import { useEffect, useState, type FormEvent } from 'react';
import { useParams, Link } from 'react-router-dom';
import { api } from '../api';
import type { Course, Module, Lesson, ModuleCreate, LessonCreate } from '../types';
import { Button } from 'primereact/button';
import { Dialog } from 'primereact/dialog';
import { InputText } from 'primereact/inputtext';
import { InputTextarea } from 'primereact/inputtextarea';
import { InputNumber } from 'primereact/inputnumber';
import { Dropdown } from 'primereact/dropdown';
import { ToggleButton } from 'primereact/togglebutton';
import { Tag } from 'primereact/tag';
import { ConfirmDialog, confirmDialog } from 'primereact/confirmdialog';

const LESSON_TYPES = [
  { label: 'Theory', value: 'theory' },
  { label: 'Code', value: 'code' },
  { label: 'Quiz', value: 'quiz' },
];

const labelStyle: React.CSSProperties = {
  display: 'block', fontSize: 12, fontWeight: 600,
  color: 'var(--text-secondary)', marginBottom: 6, letterSpacing: '0.3px',
};

export default function CourseDetail() {
  const { id } = useParams<{ id: string }>();
  const [course, setCourse] = useState<Course | null>(null);
  const [modules, setModules] = useState<Module[]>([]);
  const [lessons, setLessons] = useState<Record<number, Lesson[]>>({});
  const [expanded, setExpanded] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(true);

  const [showModuleDialog, setShowModuleDialog] = useState(false);
  const [editingModule, setEditingModule] = useState<Module | null>(null);
  const [moduleForm, setModuleForm] = useState<ModuleCreate>({ title: '', description: '', sort_order: 0, total_xp: 0, is_published: false });

  const [showLessonDialog, setShowLessonDialog] = useState(false);
  const [editingLesson, setEditingLesson] = useState<Lesson | null>(null);
  const [lessonModuleId, setLessonModuleId] = useState(0);
  const [lessonForm, setLessonForm] = useState<LessonCreate>({ title: '', lesson_type: 'theory', content: '', resources: '', video_url: '', sort_order: 0, xp_reward: 25, is_published: false });

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const [c, m] = await Promise.all([api.getCourse(+id), api.getCourseModules(+id)]);
      setCourse(c); setModules(m);
      const lm: Record<number, Lesson[]> = {};
      await Promise.all(m.map(async mod => { lm[mod.id] = await api.getModuleLessons(mod.id); }));
      setLessons(lm);
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, [id]);

  const toggleExpand = (modId: number) => {
    setExpanded(prev => { const n = new Set(prev); n.has(modId) ? n.delete(modId) : n.add(modId); return n; });
  };

  const openCreateModule = () => { setEditingModule(null); setModuleForm({ title: '', description: '', sort_order: modules.length, total_xp: 0, is_published: false }); setShowModuleDialog(true); };
  const openEditModule = (m: Module) => { setEditingModule(m); setModuleForm({ title: m.title, description: m.description || '', sort_order: m.sort_order, total_xp: m.total_xp, is_published: m.is_published }); setShowModuleDialog(true); };
  const handleModuleSubmit = async (e: FormEvent) => { e.preventDefault(); if (editingModule) await api.updateModule(editingModule.id, moduleForm); else await api.createModule(+id!, moduleForm); setShowModuleDialog(false); load(); };
  const handleDeleteModule = (modId: number) => { confirmDialog({ message: 'Delete this module and all its lessons?', header: 'Confirm', icon: 'pi pi-exclamation-triangle', accept: async () => { await api.deleteModule(modId); load(); } }); };
  const toggleModulePublish = async (m: Module) => { await api.updateModule(m.id, { is_published: !m.is_published }); load(); };

  const openCreateLesson = (modId: number) => { setEditingLesson(null); setLessonModuleId(modId); setLessonForm({ title: '', lesson_type: 'theory', content: '', resources: '', video_url: '', sort_order: (lessons[modId] || []).length, xp_reward: 25, is_published: false }); setShowLessonDialog(true); };
  const openEditLesson = (l: Lesson) => { setEditingLesson(l); setLessonModuleId(l.module_id); setLessonForm({ title: l.title, lesson_type: l.lesson_type, content: l.content || '', resources: l.resources || '', video_url: l.video_url || '', code_template: l.code_template || '', code_language: l.code_language || '', has_editor: l.has_editor, sort_order: l.sort_order, xp_reward: l.xp_reward, is_published: l.is_published }); setShowLessonDialog(true); };
  const handleLessonSubmit = async (e: FormEvent) => { e.preventDefault(); if (editingLesson) await api.updateLesson(editingLesson.id, lessonForm); else await api.createLesson(lessonModuleId, lessonForm); setShowLessonDialog(false); load(); };
  const handleDeleteLesson = (lid: number) => { confirmDialog({ message: 'Delete this lesson?', header: 'Confirm', icon: 'pi pi-exclamation-triangle', accept: async () => { await api.deleteLesson(lid); load(); } }); };
  const toggleLessonPublish = async (l: Lesson) => { await api.updateLesson(l.id, { is_published: !l.is_published }); load(); };

  const lessonIcon = (t: string) => t === 'code' ? 'pi pi-code' : t === 'quiz' ? 'pi pi-question-circle' : 'pi pi-file';

  if (loading) return <div className="page"><div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 200 }}><i className="pi pi-spin pi-spinner" style={{ fontSize: 32, color: 'var(--accent)' }} /></div></div>;
  if (!course) return <div className="page page-error">Course not found</div>;

  const modFooter = <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}><Button label="Cancel" icon="pi pi-times" text onClick={() => setShowModuleDialog(false)} /><Button label={editingModule ? 'Update' : 'Create'} icon="pi pi-check" onClick={handleModuleSubmit} /></div>;
  const lesFooter = <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 8 }}><Button label="Cancel" icon="pi pi-times" text onClick={() => setShowLessonDialog(false)} /><Button label={editingLesson ? 'Update' : 'Create'} icon="pi pi-check" onClick={handleLessonSubmit} /></div>;

  return (
    <div className="page fade-in">
      <ConfirmDialog />

      <Link to="/courses" style={{ display: 'inline-flex', alignItems: 'center', gap: 6, color: 'var(--text-dim)', fontSize: 13, textDecoration: 'none', marginBottom: 16 }}>
        <i className="pi pi-arrow-left" style={{ fontSize: 12 }} /> Back to Courses
      </Link>

      <div className="page-header">
        <div>
          <h1>{course.icon && <span style={{ marginRight: 8 }}>{course.icon}</span>}{course.title}</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>{course.description || 'No description'}</p>
        </div>
        <Button label="Add Module" icon="pi pi-plus" onClick={openCreateModule} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {modules.map(mod => (
          <div key={mod.id} style={{ background: 'var(--bg-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', overflow: 'hidden' }}>
            <div onClick={() => toggleExpand(mod.id)} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '14px 18px', cursor: 'pointer', transition: 'background 0.15s' }}
              onMouseOver={e => (e.currentTarget.style.background = 'var(--bg-card-hover)')}
              onMouseOut={e => (e.currentTarget.style.background = 'transparent')}>
              <i className={`pi ${expanded.has(mod.id) ? 'pi-chevron-down' : 'pi-chevron-right'}`} style={{ color: 'var(--text-dim)', fontSize: 13 }} />
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{mod.title}</div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12, color: 'var(--text-dim)', marginTop: 3 }}>
                  <span>{mod.total_lessons} lesson{mod.total_lessons !== 1 ? 's' : ''}</span>
                  <span>·</span>
                  <span>{mod.total_xp} XP</span>
                  {!mod.is_published && <Tag value="Draft" severity="secondary" rounded style={{ fontSize: 10 }} />}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 4 }} onClick={e => e.stopPropagation()}>
                <Button icon={mod.is_published ? 'pi pi-eye' : 'pi pi-eye-slash'} severity={mod.is_published ? 'success' : 'secondary'} text rounded size="small" onClick={() => toggleModulePublish(mod)} />
                <Button icon="pi pi-pencil" severity="info" text rounded size="small" onClick={() => openEditModule(mod)} />
                <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDeleteModule(mod.id)} />
              </div>
            </div>

            {expanded.has(mod.id) && (
              <div style={{ padding: '0 18px 14px 52px', display: 'flex', flexDirection: 'column', gap: 2 }}>
                {(lessons[mod.id] || []).map(l => (
                  <div key={l.id} style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px 14px', borderRadius: 'var(--radius)', transition: 'background 0.15s' }}
                    onMouseOver={e => (e.currentTarget.style.background = 'var(--bg-card-hover)')}
                    onMouseOut={e => (e.currentTarget.style.background = 'transparent')}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10, flex: 1 }}>
                      <i className={`pi ${lessonIcon(l.lesson_type)}`} style={{ fontSize: 13, color: 'var(--text-dim)' }} />
                      <span style={{ fontSize: 13 }}>{l.title}</span>
                      <Tag value={l.lesson_type} severity="info" rounded style={{ fontSize: 10, padding: '1px 6px' }} />
                      <span style={{ fontSize: 11, color: 'var(--text-dim)' }}>+{l.xp_reward} XP</span>
                    </div>
                    <div style={{ display: 'flex', gap: 2 }}>
                      <Button icon={l.is_published ? 'pi pi-eye' : 'pi pi-eye-slash'} severity={l.is_published ? 'success' : 'secondary'} text rounded size="small" onClick={() => toggleLessonPublish(l)} />
                      <Button icon="pi pi-pencil" severity="info" text rounded size="small" onClick={() => openEditLesson(l)} />
                      <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDeleteLesson(l.id)} />
                    </div>
                  </div>
                ))}
                <Button label="Add Lesson" icon="pi pi-plus" text size="small" className="mt-2" onClick={() => openCreateLesson(mod.id)} />
              </div>
            )}
          </div>
        ))}
        {modules.length === 0 && (
          <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', padding: '40px', textAlign: 'center', color: 'var(--text-dim)' }}>
            No modules yet. Add your first module!
          </div>
        )}
      </div>

      {/* Module Dialog */}
      <Dialog header={editingModule ? 'Edit Module' : 'New Module'} visible={showModuleDialog} onHide={() => setShowModuleDialog(false)} style={{ width: 480 }} footer={modFooter} modal draggable={false}>
        <form onSubmit={handleModuleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14, paddingTop: 12 }}>
          <div><label style={labelStyle}>Title *</label><InputText value={moduleForm.title} onChange={e => setModuleForm({ ...moduleForm, title: e.target.value })} className="w-full" required /></div>
          <div><label style={labelStyle}>Description</label><InputTextarea value={moduleForm.description || ''} onChange={e => setModuleForm({ ...moduleForm, description: e.target.value })} className="w-full" rows={2} /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div><label style={labelStyle}>Total XP</label><InputNumber value={moduleForm.total_xp || 0} onValueChange={e => setModuleForm({ ...moduleForm, total_xp: e.value || 0 })} className="w-full" /></div>
            <div><label style={labelStyle}>Sort Order</label><InputNumber value={moduleForm.sort_order || 0} onValueChange={e => setModuleForm({ ...moduleForm, sort_order: e.value || 0 })} className="w-full" /></div>
          </div>
          <div><ToggleButton checked={moduleForm.is_published || false} onChange={e => setModuleForm({ ...moduleForm, is_published: e.value })} onLabel="Published" offLabel="Draft" onIcon="pi pi-check" offIcon="pi pi-times" /></div>
        </form>
      </Dialog>

      {/* Lesson Dialog */}
      <Dialog header={editingLesson ? 'Edit Lesson' : 'New Lesson'} visible={showLessonDialog} onHide={() => setShowLessonDialog(false)} style={{ width: 620 }} footer={lesFooter} modal draggable={false}>
        <form onSubmit={handleLessonSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14, paddingTop: 12 }}>
          <div><label style={labelStyle}>Title *</label><InputText value={lessonForm.title} onChange={e => setLessonForm({ ...lessonForm, title: e.target.value })} className="w-full" required /></div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div><label style={labelStyle}>Type</label><Dropdown value={lessonForm.lesson_type} options={LESSON_TYPES} onChange={e => setLessonForm({ ...lessonForm, lesson_type: e.value })} className="w-full" /></div>
            <div><label style={labelStyle}>XP Reward</label><InputNumber value={lessonForm.xp_reward || 25} onValueChange={e => setLessonForm({ ...lessonForm, xp_reward: e.value || 25 })} className="w-full" /></div>
          </div>
          <div><label style={labelStyle}>Content (Markdown)</label><InputTextarea value={lessonForm.content || ''} onChange={e => setLessonForm({ ...lessonForm, content: e.target.value })} className="w-full" rows={5} /></div>
          <div><label style={labelStyle}>Video URL (optional)</label><InputText value={lessonForm.video_url || ''} onChange={e => setLessonForm({ ...lessonForm, video_url: e.target.value })} className="w-full" placeholder="https://youtube.com/embed/..." /></div>
          <div>
            <label style={labelStyle}>Resources (JSON) <span style={{ fontWeight: 400, color: 'var(--text-dim)' }}>— [{"title": "...", "url": "...", "type": "link|pdf|github"}]
              <Button icon="pi pi-plus" text rounded size="small" type="button" style={{ float: 'right' }}
                onClick={() => {
                  const current = (() => { try { return JSON.parse(lessonForm.resources || '[]'); } catch { return []; } })();
                  current.push({ title: '', url: '', type: 'link' });
                  setLessonForm({ ...lessonForm, resources: JSON.stringify(current) });
                }}
              />
            </span></label>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6, marginBottom: 8 }}>
              {(() => {
                try {
                  const items = JSON.parse(lessonForm.resources || '[]');
                  if (!Array.isArray(items) || items.length === 0) return null;
                  return items.map((r: any, i: number) => (
                    <div key={i} style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
                      <InputText value={r.title || ''} onChange={e => {
                        const copy = [...items]; copy[i] = { ...copy[i], title: e.target.value };
                        setLessonForm({ ...lessonForm, resources: JSON.stringify(copy) });
                      }} placeholder="Title" style={{ flex: 2 }} />
                      <InputText value={r.url || ''} onChange={e => {
                        const copy = [...items]; copy[i] = { ...copy[i], url: e.target.value };
                        setLessonForm({ ...lessonForm, resources: JSON.stringify(copy) });
                      }} placeholder="URL" style={{ flex: 3 }} />
                      <Dropdown value={r.type || 'link'} options={[{ label: 'Link', value: 'link' }, { label: 'PDF', value: 'pdf' }, { label: 'GitHub', value: 'github' }]} onChange={e => {
                        const copy = [...items]; copy[i] = { ...copy[i], type: e.value };
                        setLessonForm({ ...lessonForm, resources: JSON.stringify(copy) });
                      }} style={{ width: 100 }} />
                      <Button icon="pi pi-trash" text rounded severity="danger" size="small" type="button" onClick={() => {
                        const copy = items.filter((_: any, j: number) => j !== i);
                        setLessonForm({ ...lessonForm, resources: JSON.stringify(copy) });
                      }} />
                    </div>
                  ));
                } catch { return null; }
              })()}
            </div>
            <InputTextarea value={lessonForm.resources || ''} onChange={e => setLessonForm({ ...lessonForm, resources: e.target.value })} className="w-full" rows={2} placeholder='[{"title": "Express Docs", "url": "https://expressjs.com", "type": "link"}]' style={{ fontSize: 11, fontFamily: 'monospace' }} />
          </div>
          {lessonForm.lesson_type === 'code' && (
            <>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div><label style={labelStyle}>Code Language</label><InputText value={lessonForm.code_language || ''} onChange={e => setLessonForm({ ...lessonForm, code_language: e.target.value })} className="w-full" placeholder="python, javascript..." /></div>
                <div style={{ display: 'flex', alignItems: 'flex-end' }}><ToggleButton checked={lessonForm.has_editor || false} onChange={e => setLessonForm({ ...lessonForm, has_editor: e.value })} onLabel="Editor ON" offLabel="Editor OFF" /></div>
              </div>
              <div><label style={labelStyle}>Code Template</label><InputTextarea value={lessonForm.code_template || ''} onChange={e => setLessonForm({ ...lessonForm, code_template: e.target.value })} className="w-full" rows={4} style={{ fontFamily: 'monospace', fontSize: 12 }} /></div>
            </>
          )}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <div><label style={labelStyle}>Sort Order</label><InputNumber value={lessonForm.sort_order || 0} onValueChange={e => setLessonForm({ ...lessonForm, sort_order: e.value || 0 })} className="w-full" /></div>
            <div style={{ display: 'flex', alignItems: 'flex-end' }}><ToggleButton checked={lessonForm.is_published || false} onChange={e => setLessonForm({ ...lessonForm, is_published: e.value })} onLabel="Published" offLabel="Draft" /></div>
          </div>
        </form>
      </Dialog>
    </div>
  );
}
