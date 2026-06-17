import { useState, useEffect, useRef } from 'react'
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom'
import { Terminal, LayoutDashboard, BookOpen, Users, LogOut, ChevronRight, Plus, Trash2, Pencil, Eye, Code2, Video, FileText, Link2, X, Check, ChevronDown, ChevronUp, Image, Upload, FolderOpen } from 'lucide-react'
import {
  login as apiLogin,
  getDashboard,
  getCourses,
  getCourseModules,
  getModuleLessons,
  createModule,
  updateModule,
  deleteModule,
  createLesson,
  updateLesson,
  deleteLesson,
  getUsers,
  uploadMedia,
  listMedia,
  deleteMedia,
  type BackofficeDashboard,
  type CourseOut,
  type ModuleOut,
  type LessonOut,
  type LessonCreate,
  type UserOut,
  type MediaItem,
} from './api'

// ── Auth Context ─────────────────────────────────────────────────
function useAuth() {
  const [token, setToken] = useState(localStorage.getItem('token'))
  const [user, setUser] = useState<UserOut | null>(null)

  useEffect(() => {
    const stored = localStorage.getItem('token')
    if (stored) {
      setToken(stored)
      try {
        const u = localStorage.getItem('user')
        if (u) setUser(JSON.parse(u))
      } catch {}
    }
  }, [])

  const signIn = async (email: string, password: string) => {
    const res = await apiLogin(email, password)
    localStorage.setItem('token', res.access_token)
    localStorage.setItem('user', JSON.stringify(res.user))
    setToken(res.access_token)
    setUser(res.user)
  }

  const signOut = () => {
    localStorage.removeItem('token')
    localStorage.removeItem('user')
    setToken(null)
    setUser(null)
  }

  return { token, user, signIn, signOut }
}

// ── Login Page ───────────────────────────────────────────────────
function LoginPage({ onLogin }: { onLogin: (e: string, p: string) => Promise<void> }) {
  const [email, setEmail] = useState('admin')
  const [password, setPassword] = useState('devpulse2024')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try { await onLogin(email, password) }
    catch (err: any) { setError(err.message || 'Login failed') }
    setLoading(false)
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <h1>DevPulse</h1>
        <p>BACKOFFICE ADMIN PANEL</p>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Username</label>
            <input value={email} onChange={e => setEmail(e.target.value)} placeholder="admin" />
          </div>
          <div className="form-group">
            <label>Password</label>
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" />
          </div>
          <button className="btn" type="submit" disabled={loading}>
            {loading ? 'Authenticating...' : 'INITIALIZE SESSION'}
          </button>
          {error && <div className="error-msg">{error}</div>}
        </form>
      </div>
    </div>
  )
}

// ── Sidebar ──────────────────────────────────────────────────────
function Sidebar({ onLogout }: { onLogout: () => void }) {
  const navigate = useNavigate()
  const location = useLocation()

  const items = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/' },
    { icon: BookOpen, label: 'Courses', path: '/courses' },
    { icon: Image, label: 'Media', path: '/media' },
    { icon: Users, label: 'Users', path: '/users' },
  ]

  return (
    <div className="sidebar">
      <div className="sidebar-brand">
        <Terminal size={24} />
        <span>DevPulse</span>
      </div>
      <nav className="sidebar-nav">
        {items.map(item => (
          <button
            key={item.path}
            className={`nav-item ${location.pathname.startsWith(item.path) && (item.path === '/' ? location.pathname === '/' : true) ? 'active' : ''}`}
            onClick={() => navigate(item.path)}
          >
            <item.icon size={18} />
            {item.label}
          </button>
        ))}
      </nav>
      <div style={{ marginTop: 'auto', paddingTop: 24 }}>
        <button className="nav-item" onClick={onLogout} style={{ color: 'var(--coral)' }}>
          <LogOut size={18} />
          Sign Out
        </button>
      </div>
    </div>
  )
}

// ── Dashboard Page ───────────────────────────────────────────────
function DashboardPage() {
  const [data, setData] = useState<BackofficeDashboard | null>(null)

  useEffect(() => { getDashboard().then(setData).catch(() => {}) }, [])

  if (!data) return <div className="loading">Loading…</div>

  const stats = [
    { label: 'Total Users', value: data.total_users, color: 'var(--accent)' },
    { label: 'Total Courses', value: data.total_courses, color: 'var(--green)' },
    { label: 'Total Modules', value: data.total_modules, color: 'var(--gold)' },
    { label: 'Total Quizzes', value: data.total_quizzes, color: 'var(--coral)' },
    { label: 'Quiz Attempts', value: data.total_quiz_attempts, color: 'var(--accent)' },
    { label: 'Active Today', value: data.active_users_today, color: 'var(--green)' },
  ]

  return (
    <div>
      <h1 className="page-title">Dashboard</h1>
      <div className="stats-grid">
        {stats.map(s => (
          <div className="stat-card" key={s.label}>
            <div className="label">{s.label}</div>
            <div className="value" style={{ color: s.color }}>{s.value.toLocaleString()}</div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ── Markdown Preview ─────────────────────────────────────────────
function MarkdownPreview({ content }: { content: string }) {
  // Simple markdown renderer for preview — headings, bold, italic, code blocks, lists
  const html = content
    .replace(/^### (.+)$/gm, '<h3>$1</h3>')
    .replace(/^## (.+)$/gm, '<h2>$1</h2>')
    .replace(/^# (.+)$/gm, '<h1>$1</h1>')
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.+?)\*/g, '<em>$1</em>')
    .replace(/`([^`\n]+)`/g, '<code>$1</code>')
    .replace(/```[\w]*\n([\s\S]*?)```/g, '<pre><code>$1</code></pre>')
    .replace(/^> (.+)$/gm, '<blockquote>$1</blockquote>')
    .replace(/^- (.+)$/gm, '<li>$1</li>')
    .replace(/(<li>.*<\/li>\n?)+/g, '<ul>$&</ul>')
    .replace(/\n\n/g, '</p><p>')
    .replace(/^(?!<[h|u|b|p|l|c])(.+)$/gm, '<p>$1</p>')

  return (
    <div
      className="md-preview"
      dangerouslySetInnerHTML={{ __html: html }}
    />
  )
}

// ── Lesson Form Modal ─────────────────────────────────────────────
interface LessonFormProps {
  moduleId: number
  lesson?: LessonOut | null
  onSave: () => void
  onClose: () => void
}

function LessonFormModal({ moduleId, lesson, onSave, onClose }: LessonFormProps) {
  const isEdit = !!lesson
  const [tab, setTab] = useState<'content' | 'video' | 'resources' | 'editor'>('content')
  const [mdTab, setMdTab] = useState<'write' | 'preview'>('write')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const [title, setTitle] = useState(lesson?.title ?? '')
  const [lessonType, setLessonType] = useState(lesson?.lesson_type ?? 'theory')
  const [content, setContent] = useState(lesson?.content ?? '')
  const [videoUrl, setVideoUrl] = useState(lesson?.video_url ?? '')
  const [resources, setResources] = useState<{ title: string; url: string; type: string }[]>(
    () => {
      try { return JSON.parse(lesson?.resources ?? '[]') }
      catch { return [] }
    }
  )
  const [codeTemplate, setCodeTemplate] = useState(lesson?.code_template ?? '')
  const [codeLang, setCodeLang] = useState(lesson?.code_language ?? 'python')
  const [hasEditor, setHasEditor] = useState(lesson?.has_editor ?? false)
  const [xpReward, setXpReward] = useState(lesson?.xp_reward ?? 25)
  const [isPublished, setIsPublished] = useState(lesson?.is_published ?? false)

  const addResource = () =>
    setResources(r => [...r, { title: '', url: '', type: 'link' }])

  const updateResource = (i: number, field: string, val: string) =>
    setResources(r => r.map((item, idx) => idx === i ? { ...item, [field]: val } : item))

  const removeResource = (i: number) =>
    setResources(r => r.filter((_, idx) => idx !== i))

  const handleSave = async () => {
    if (!title.trim()) { setError('Title is required'); return }
    setSaving(true)
    setError('')
    const data: LessonCreate = {
      title: title.trim(),
      lesson_type: lessonType,
      content: content || undefined,
      video_url: videoUrl || undefined,
      resources: resources.length ? JSON.stringify(resources) : undefined,
      code_template: codeTemplate || undefined,
      code_language: codeLang || undefined,
      has_editor: hasEditor,
      sort_order: lesson?.sort_order ?? 0,
      xp_reward: xpReward,
      is_published: isPublished,
    }
    try {
      if (isEdit) await updateLesson(lesson!.id, data)
      else await createLesson(moduleId, data)
      onSave()
    } catch (e: any) {
      setError(e.message)
    }
    setSaving(false)
  }

  const tabs = [
    { id: 'content', icon: FileText, label: 'Content' },
    { id: 'video', icon: Video, label: 'Video' },
    { id: 'resources', icon: Link2, label: 'Resources' },
    { id: 'editor', icon: Code2, label: 'Code Editor' },
  ] as const

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box lesson-modal" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="modal-header">
          <h2>{isEdit ? 'Edit Lesson' : 'New Lesson'}</h2>
          <button className="icon-btn" onClick={onClose}><X size={18} /></button>
        </div>

        {/* Meta row */}
        <div className="lesson-meta-row">
          <div className="form-group" style={{ flex: 3 }}>
            <label>Title</label>
            <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Lesson title…" />
          </div>
          <div className="form-group" style={{ flex: 1 }}>
            <label>Type</label>
            <select value={lessonType} onChange={e => setLessonType(e.target.value)}>
              <option value="theory">Theory</option>
              <option value="code">Code</option>
              <option value="quiz">Quiz</option>
            </select>
          </div>
          <div className="form-group" style={{ flex: 1 }}>
            <label>XP Reward</label>
            <input type="number" value={xpReward} onChange={e => setXpReward(Number(e.target.value))} min={0} />
          </div>
          <div className="form-group toggle-group">
            <label>Published</label>
            <button
              className={`toggle-btn ${isPublished ? 'on' : ''}`}
              onClick={() => setIsPublished(p => !p)}
            >
              {isPublished ? <Check size={14} /> : <X size={14} />}
            </button>
          </div>
        </div>

        {/* Tab navigation */}
        <div className="lesson-tabs">
          {tabs.map(t => (
            <button
              key={t.id}
              className={`lesson-tab ${tab === t.id ? 'active' : ''}`}
              onClick={() => setTab(t.id)}
            >
              <t.icon size={14} />
              {t.label}
            </button>
          ))}
        </div>

        {/* Tab content */}
        <div className="lesson-tab-body">

          {/* ── Content (Markdown) ─────── */}
          {tab === 'content' && (
            <div className="md-editor-wrap">
              <div className="md-toggle">
                <button className={mdTab === 'write' ? 'active' : ''} onClick={() => setMdTab('write')}>Write</button>
                <button className={mdTab === 'preview' ? 'active' : ''} onClick={() => setMdTab('preview')}>Preview</button>
              </div>
              {mdTab === 'write' ? (
                <textarea
                  className="md-textarea"
                  value={content}
                  onChange={e => setContent(e.target.value)}
                  placeholder={`# Lesson Title\n\nWrite your lesson content in **Markdown**.\n\n## Section 1\n\nYou can use:\n- \`inline code\`\n- **bold** and *italic*\n- Code blocks\n\n\`\`\`python\nprint("Hello, DevPulse!")\n\`\`\``}
                  spellCheck={false}
                />
              ) : (
                <div className="md-preview-wrap">
                  {content ? <MarkdownPreview content={content} /> : (
                    <p style={{ color: 'var(--text-muted)', fontStyle: 'italic' }}>
                      Nothing to preview yet. Switch to Write and add some Markdown.
                    </p>
                  )}
                </div>
              )}
              <div className="md-hint">
                Supports: <code># Headings</code> · <code>**bold**</code> · <code>*italic*</code> · <code>`code`</code> · <code>```blocks```</code> · <code>- lists</code> · <code>&gt; blockquotes</code>
              </div>
            </div>
          )}

          {/* ── Video ─────────────────── */}
          {tab === 'video' && (
            <VideoTab videoUrl={videoUrl} onUrlChange={setVideoUrl} />
          )}

          {/* ── Resources ─────────────── */}
          {tab === 'resources' && (
            <ResourcesTab resources={resources} onChange={setResources} />
          )}

          {/* ── Code Editor ───────────── */}
          {tab === 'editor' && (
            <div className="tab-section">
              <div className="editor-settings-row">
                <div className="form-group" style={{ flex: 1 }}>
                  <label>Language</label>
                  <select value={codeLang} onChange={e => setCodeLang(e.target.value)}>
                    {['python', 'javascript', 'typescript', 'dart', 'rust', 'go', 'java', 'cpp'].map(l => (
                      <option key={l} value={l}>{l}</option>
                    ))}
                  </select>
                </div>
                <div className="form-group toggle-group">
                  <label>Show editor to learner</label>
                  <button
                    className={`toggle-btn ${hasEditor ? 'on' : ''}`}
                    onClick={() => setHasEditor(h => !h)}
                  >
                    {hasEditor ? <Check size={14} /> : <X size={14} />}
                  </button>
                </div>
              </div>
              <div className="form-group">
                <label>Starter code template</label>
                <textarea
                  className="code-textarea"
                  value={codeTemplate}
                  onChange={e => setCodeTemplate(e.target.value)}
                  placeholder={`# Write the starter code the learner will see\ndef hello():\n    pass  # TODO: implement this`}
                  spellCheck={false}
                />
              </div>
              <p className="field-hint">
                The learner will see this code pre-filled in the interactive editor embedded in the lesson.
                Leave empty to show a blank editor.
              </p>
            </div>
          )}
        </div>

        {/* Footer */}
        {error && <div className="error-msg" style={{ marginTop: 8 }}>{error}</div>}
        <div className="modal-footer">
          <button className="btn-outline" onClick={onClose}>Cancel</button>
          <button className="btn" style={{ width: 'auto', padding: '10px 28px' }} onClick={handleSave} disabled={saving}>
            {saving ? 'Saving…' : isEdit ? 'Update Lesson' : 'Create Lesson'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Module Form Modal ─────────────────────────────────────────────
interface ModuleFormProps {
  courseId: number
  module?: ModuleOut | null
  onSave: () => void
  onClose: () => void
}

function ModuleFormModal({ courseId, module: mod, onSave, onClose }: ModuleFormProps) {
  const isEdit = !!mod
  const [title, setTitle] = useState(mod?.title ?? '')
  const [description, setDescription] = useState(mod?.description ?? '')
  const [totalXp, setTotalXp] = useState(mod?.total_xp ?? 0)
  const [isPublished, setIsPublished] = useState(mod?.is_published ?? false)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const handleSave = async () => {
    if (!title.trim()) { setError('Title is required'); return }
    setSaving(true)
    setError('')
    try {
      if (isEdit) await updateModule(mod!.id, { title, description, total_xp: totalXp, is_published: isPublished })
      else await createModule(courseId, { title, description, total_xp: totalXp, is_published: isPublished, sort_order: 0 })
      onSave()
    } catch (e: any) { setError(e.message) }
    setSaving(false)
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-box" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{isEdit ? 'Edit Module' : 'New Module'}</h2>
          <button className="icon-btn" onClick={onClose}><X size={18} /></button>
        </div>
        <div className="form-group">
          <label>Title</label>
          <input value={title} onChange={e => setTitle(e.target.value)} placeholder="Module title…" />
        </div>
        <div className="form-group">
          <label>Description</label>
          <textarea
            className="simple-textarea"
            value={description}
            onChange={e => setDescription(e.target.value)}
            placeholder="Short description of this module…"
            rows={3}
          />
        </div>
        <div style={{ display: 'flex', gap: 16 }}>
          <div className="form-group" style={{ flex: 1 }}>
            <label>Total XP</label>
            <input type="number" value={totalXp} onChange={e => setTotalXp(Number(e.target.value))} min={0} />
          </div>
          <div className="form-group toggle-group">
            <label>Published</label>
            <button className={`toggle-btn ${isPublished ? 'on' : ''}`} onClick={() => setIsPublished(p => !p)}>
              {isPublished ? <Check size={14} /> : <X size={14} />}
            </button>
          </div>
        </div>
        {error && <div className="error-msg">{error}</div>}
        <div className="modal-footer">
          <button className="btn-outline" onClick={onClose}>Cancel</button>
          <button className="btn" style={{ width: 'auto', padding: '10px 28px' }} onClick={handleSave} disabled={saving}>
            {saving ? 'Saving…' : isEdit ? 'Update' : 'Create'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ── Lesson Row ───────────────────────────────────────────────────
function LessonRow({ lesson, onEdit, onDelete }: {
  lesson: LessonOut
  onEdit: () => void
  onDelete: () => void
}) {
  const typeIcon = lesson.lesson_type === 'code' ? <Code2 size={13} /> :
    lesson.lesson_type === 'quiz' ? '❓' : <FileText size={13} />

  return (
    <tr>
      <td style={{ paddingLeft: 32, color: 'var(--text-muted)', fontSize: 12 }}>#{lesson.id}</td>
      <td style={{ color: 'var(--text-primary)' }}>
        <span style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: 'var(--accent)', opacity: 0.7 }}>{typeIcon}</span>
          {lesson.title}
        </span>
      </td>
      <td>
        <span className="feature-dots">
          {lesson.content && <span className="dot dot-blue" title="Has content">M</span>}
          {lesson.video_url && <span className="dot dot-coral" title="Has video">V</span>}
          {lesson.has_editor && <span className="dot dot-green" title="Has code editor">E</span>}
          {lesson.resources && lesson.resources !== '[]' && <span className="dot dot-gold" title="Has resources">R</span>}
        </span>
      </td>
      <td><span className="badge" style={{ color: 'var(--gold)' }}>{lesson.xp_reward} XP</span></td>
      <td>
        <span className={`badge ${lesson.is_published ? 'badge-published' : 'badge-draft'}`}>
          {lesson.is_published ? 'Published' : 'Draft'}
        </span>
      </td>
      <td>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="icon-btn" onClick={onEdit} title="Edit"><Pencil size={14} /></button>
          <button className="icon-btn danger" onClick={onDelete} title="Delete"><Trash2 size={14} /></button>
        </div>
      </td>
    </tr>
  )
}

// ── Module Row (with expandable lessons) ─────────────────────────
function ModuleRow({ mod, courseId, onModuleChange }: {
  mod: ModuleOut
  courseId: number
  onModuleChange: () => void
}) {
  const [expanded, setExpanded] = useState(false)
  const [lessons, setLessons] = useState<LessonOut[]>([])
  const [loadingLessons, setLoadingLessons] = useState(false)
  const [editModule, setEditModule] = useState(false)
  const [newLesson, setNewLesson] = useState(false)
  const [editLesson, setEditLesson] = useState<LessonOut | null>(null)

  const loadLessons = async () => {
    setLoadingLessons(true)
    try { setLessons(await getModuleLessons(mod.id)) }
    catch {}
    setLoadingLessons(false)
  }

  const toggleExpand = () => {
    if (!expanded) loadLessons()
    setExpanded(e => !e)
  }

  const handleDeleteModule = async () => {
    if (!confirm(`Delete module "${mod.title}" and all its lessons?`)) return
    try { await deleteModule(mod.id); onModuleChange() }
    catch (e: any) { alert(e.message) }
  }

  const handleDeleteLesson = async (id: number) => {
    if (!confirm('Delete this lesson?')) return
    try { await deleteLesson(id); loadLessons() }
    catch (e: any) { alert(e.message) }
  }

  return (
    <>
      <tr className="module-row">
        <td>
          <button className="expand-btn" onClick={toggleExpand}>
            {expanded ? <ChevronUp size={16} /> : <ChevronDown size={16} />}
          </button>
        </td>
        <td style={{ color: 'var(--text-primary)', fontWeight: 600 }}>{mod.title}</td>
        <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>{mod.description || '—'}</td>
        <td>{mod.total_lessons} lessons</td>
        <td><span style={{ color: 'var(--gold)', fontWeight: 700 }}>{mod.total_xp} XP</span></td>
        <td>
          <span className={`badge ${mod.is_published ? 'badge-published' : 'badge-draft'}`}>
            {mod.is_published ? 'Published' : 'Draft'}
          </span>
        </td>
        <td>
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="icon-btn" onClick={() => setEditModule(true)} title="Edit module"><Pencil size={14} /></button>
            <button className="icon-btn danger" onClick={handleDeleteModule} title="Delete module"><Trash2 size={14} /></button>
          </div>
        </td>
      </tr>

      {expanded && (
        <tr>
          <td colSpan={7} style={{ padding: 0, background: 'var(--bg-input)' }}>
            <div className="lessons-panel">
              <div className="lessons-panel-header">
                <span style={{ fontSize: 12, color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '1px' }}>
                  Lessons — {mod.title}
                </span>
                <button className="btn-small" onClick={() => setNewLesson(true)}>
                  <Plus size={14} /> Add Lesson
                </button>
              </div>
              {loadingLessons ? (
                <div style={{ padding: '16px 24px', color: 'var(--text-muted)' }}>Loading lessons…</div>
              ) : lessons.length === 0 ? (
                <div style={{ padding: '16px 24px', color: 'var(--text-muted)', fontStyle: 'italic' }}>
                  No lessons yet. Click "Add Lesson" to create the first one.
                </div>
              ) : (
                <table>
                  <thead>
                    <tr>
                      <th style={{ paddingLeft: 32 }}>ID</th>
                      <th>Title</th>
                      <th>Features</th>
                      <th>XP</th>
                      <th>Status</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {lessons.map(l => (
                      <LessonRow
                        key={l.id}
                        lesson={l}
                        onEdit={() => setEditLesson(l)}
                        onDelete={() => handleDeleteLesson(l.id)}
                      />
                    ))}
                  </tbody>
                </table>
              )}
            </div>
          </td>
        </tr>
      )}

      {editModule && (
        <ModuleFormModal
          courseId={courseId}
          module={mod}
          onSave={() => { setEditModule(false); onModuleChange() }}
          onClose={() => setEditModule(false)}
        />
      )}
      {newLesson && (
        <LessonFormModal
          moduleId={mod.id}
          onSave={() => { setNewLesson(false); loadLessons() }}
          onClose={() => setNewLesson(false)}
        />
      )}
      {editLesson && (
        <LessonFormModal
          moduleId={mod.id}
          lesson={editLesson}
          onSave={() => { setEditLesson(null); loadLessons() }}
          onClose={() => setEditLesson(null)}
        />
      )}
    </>
  )
}

// ── Media Upload Button ───────────────────────────────────────────
function UploadButton({
  accept,
  onUploaded,
  label,
}: {
  accept: string
  onUploaded: (item: MediaItem) => void
  label: string
}) {
  const ref = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState('')

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    setError('')
    try {
      const item = await uploadMedia(file)
      onUploaded(item)
    } catch (err: any) {
      setError(err.message)
    }
    setUploading(false)
    if (ref.current) ref.current.value = ''
  }

  return (
    <div>
      <input
        ref={ref}
        type="file"
        accept={accept}
        style={{ display: 'none' }}
        onChange={handleFile}
      />
      <button
        className="btn-small accent"
        onClick={() => ref.current?.click()}
        disabled={uploading}
      >
        <Upload size={14} />
        {uploading ? 'Uploading…' : label}
      </button>
      {error && <p className="field-hint" style={{ color: 'var(--coral)' }}>{error}</p>}
    </div>
  )
}

// ── Video Tab ─────────────────────────────────────────────────────
function VideoTab({
  videoUrl,
  onUrlChange,
}: {
  videoUrl: string
  onUrlChange: (url: string) => void
}) {
  const isYoutube = videoUrl.includes('youtube') || videoUrl.includes('youtu.be')
  const isLocal = videoUrl.startsWith('/api/media/')

  return (
    <div className="tab-section">
      <div style={{ display: 'flex', gap: 12, alignItems: 'flex-end', marginBottom: 12 }}>
        <div className="form-group" style={{ flex: 1, marginBottom: 0 }}>
          <label>Video URL</label>
          <input
            value={videoUrl}
            onChange={e => onUrlChange(e.target.value)}
            placeholder="https://youtube.com/embed/… or upload a file →"
          />
        </div>
        <UploadButton
          accept="video/mp4,video/webm,video/ogg"
          label="Upload Video"
          onUploaded={item => onUrlChange(item.url)}
        />
      </div>

      {videoUrl && (
        <div className="video-preview">
          {isYoutube ? (
            <iframe
              src={videoUrl.replace('watch?v=', 'embed/')}
              allowFullScreen
              style={{ width: '100%', height: 280, border: 'none', borderRadius: 8 }}
            />
          ) : (
            <video controls style={{ width: '100%', borderRadius: 8, maxHeight: 280 }}>
              <source src={videoUrl} />
              Your browser does not support the video tag.
            </video>
          )}
        </div>
      )}

      {isLocal && (
        <p className="field-hint" style={{ color: 'var(--green)' }}>
          ✓ Stored locally at <code>{videoUrl}</code>
        </p>
      )}
      <p className="field-hint">
        Upload an MP4/WebM (max 200 MB) or paste a YouTube embed URL.
        The Flutter app will display it as an embedded player.
      </p>
    </div>
  )
}

// ── Resources Tab ─────────────────────────────────────────────────
type Resource = { title: string; url: string; type: string }

function ResourcesTab({
  resources,
  onChange,
}: {
  resources: Resource[]
  onChange: (r: Resource[]) => void
}) {
  const add = () => onChange([...resources, { title: '', url: '', type: 'link' }])
  const update = (i: number, field: string, val: string) =>
    onChange(resources.map((r, idx) => idx === i ? { ...r, [field]: val } : r))
  const remove = (i: number) => onChange(resources.filter((_, idx) => idx !== i))

  return (
    <div className="tab-section">
      <div className="resources-header">
        <span>External resources for learners</span>
        <div style={{ display: 'flex', gap: 8 }}>
          <UploadButton
            accept=".pdf,.zip,.txt"
            label="Upload File"
            onUploaded={item =>
              onChange([
                ...resources,
                {
                  title: item.original_name ?? item.filename,
                  url: item.url,
                  type: item.mime === 'application/pdf' ? 'pdf' : 'link',
                },
              ])
            }
          />
          <button className="btn-small" onClick={add}>
            <Plus size={14} /> Add Link
          </button>
        </div>
      </div>

      {resources.length === 0 && (
        <p className="field-hint">
          No resources yet. Upload a PDF/ZIP or add an external link.
        </p>
      )}

      {resources.map((r, i) => (
        <div className="resource-row" key={i}>
          <select value={r.type} onChange={e => update(i, 'type', e.target.value)}>
            <option value="link">🔗 Link</option>
            <option value="pdf">📄 PDF</option>
            <option value="github">🐙 GitHub</option>
            <option value="video">🎬 Video</option>
          </select>
          <input
            placeholder="Title"
            value={r.title}
            onChange={e => update(i, 'title', e.target.value)}
          />
          <input
            placeholder="https://… or /api/media/…"
            value={r.url}
            onChange={e => update(i, 'url', e.target.value)}
            style={{ flex: 2 }}
          />
          <button className="icon-btn danger" onClick={() => remove(i)}>
            <Trash2 size={14} />
          </button>
        </div>
      ))}
    </div>
  )
}

// ── Media Library Page ────────────────────────────────────────────
function MediaLibraryPage() {
  const [items, setItems] = useState<MediaItem[]>([])
  const [filter, setFilter] = useState('all')
  const [loading, setLoading] = useState(true)
  const [uploading, setUploading] = useState(false)
  const fileRef = useRef<HTMLInputElement>(null)

  const load = async () => {
    setLoading(true)
    try { setItems(await listMedia(filter)) } catch {}
    setLoading(false)
  }

  useEffect(() => { load() }, [filter])

  const handleUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setUploading(true)
    try { await uploadMedia(file); await load() }
    catch (err: any) { alert(err.message) }
    setUploading(false)
    if (fileRef.current) fileRef.current.value = ''
  }

  const handleDelete = async (item: MediaItem) => {
    if (!confirm(`Delete "${item.filename}"?`)) return
    const parts = item.url.split('/')   // /api/media/videos/xxx.mp4
    const subfolder = parts[3]
    const filename = parts[4]
    try { await deleteMedia(subfolder, filename); await load() }
    catch (err: any) { alert(err.message) }
  }

  const formatSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
  }

  const typeIcon = (type: string) =>
    type === 'video' ? '🎬' : type === 'image' ? '🖼️' : '📄'

  const typeColor = (type: string) =>
    type === 'video' ? 'var(--coral)' : type === 'image' ? 'var(--accent)' : 'var(--gold)'

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <h1 className="page-title" style={{ marginBottom: 0 }}>Media Library</h1>
        <div style={{ display: 'flex', gap: 10 }}>
          {/* Filter tabs */}
          <div className="media-filter-tabs">
            {['all', 'video', 'image', 'resource'].map(t => (
              <button
                key={t}
                className={`media-filter-tab ${filter === t ? 'active' : ''}`}
                onClick={() => setFilter(t)}
              >
                {t === 'all' ? '⊞ All' : t === 'video' ? '🎬 Videos' : t === 'image' ? '🖼️ Images' : '📄 Files'}
              </button>
            ))}
          </div>
          {/* Upload */}
          <input
            ref={fileRef}
            type="file"
            accept="video/mp4,video/webm,image/*,.pdf,.zip,.txt"
            style={{ display: 'none' }}
            onChange={handleUpload}
          />
          <button
            className="btn-small accent"
            onClick={() => fileRef.current?.click()}
            disabled={uploading}
          >
            <Upload size={14} />
            {uploading ? 'Uploading…' : 'Upload File'}
          </button>
        </div>
      </div>

      {loading ? (
        <div className="loading">Loading media…</div>
      ) : items.length === 0 ? (
        <div className="empty-state">
          <FolderOpen size={40} style={{ opacity: 0.3, marginBottom: 12 }} />
          <p>No media files yet. Upload your first file.</p>
        </div>
      ) : (
        <div className="media-grid">
          {items.map(item => (
            <div className="media-card" key={item.url}>
              {/* Preview */}
              <div className="media-thumb">
                {item.type === 'image' ? (
                  <img src={item.url} alt={item.filename} />
                ) : item.type === 'video' ? (
                  <video src={item.url} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <div className="media-thumb-icon">
                    <span style={{ fontSize: 32 }}>{typeIcon(item.type)}</span>
                  </div>
                )}
              </div>
              {/* Info */}
              <div className="media-info">
                <div className="media-name" title={item.original_name ?? item.filename}>
                  {item.original_name ?? item.filename}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                  <span
                    className="badge"
                    style={{ color: typeColor(item.type), fontSize: 10 }}
                  >
                    {item.type}
                  </span>
                  <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
                    {formatSize(item.size_bytes)}
                  </span>
                </div>
              </div>
              {/* Actions */}
              <div className="media-actions">
                <button
                  className="icon-btn"
                  title="Copy URL"
                  onClick={() => {
                    navigator.clipboard.writeText(item.url)
                  }}
                >
                  <Link2 size={13} />
                </button>
                <a
                  href={item.url}
                  target="_blank"
                  rel="noreferrer"
                  className="icon-btn"
                  title="Open"
                  style={{ display: 'flex', alignItems: 'center' }}
                >
                  <Eye size={13} />
                </a>
                <button
                  className="icon-btn danger"
                  title="Delete"
                  onClick={() => handleDelete(item)}
                >
                  <Trash2 size={13} />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// ── Courses Page ─────────────────────────────────────────────────
function CoursesPage() {
  const [courses, setCourses] = useState<CourseOut[]>([])
  const [selectedCourse, setSelectedCourse] = useState<CourseOut | null>(null)
  const [modules, setModules] = useState<ModuleOut[]>([])
  const [loadingModules, setLoadingModules] = useState(false)
  const [showNewModule, setShowNewModule] = useState(false)

  const loadCourses = () => getCourses().then(setCourses).catch(() => {})

  const loadModules = async (course: CourseOut) => {
    setSelectedCourse(course)
    setLoadingModules(true)
    try { setModules(await getCourseModules(course.id)) }
    catch {}
    setLoadingModules(false)
  }

  useEffect(() => { loadCourses() }, [])

  const refreshModules = () => {
    if (selectedCourse) loadModules(selectedCourse)
  }

  return (
    <div>
      <div className="courses-layout">
        {/* Left: course list */}
        <div className="course-list-panel">
          <h1 className="page-title" style={{ marginBottom: 16 }}>Courses</h1>
          {courses.map(c => (
            <div
              key={c.id}
              className={`course-item ${selectedCourse?.id === c.id ? 'active' : ''}`}
              onClick={() => loadModules(c)}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <div style={{ fontWeight: 600, color: 'var(--text-primary)', marginBottom: 4 }}>{c.title}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                    {c.total_modules} modules · {c.total_xp} XP
                  </div>
                </div>
                <span className={`badge badge-${c.level}`}>{c.level}</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 8 }}>
                <span className={`badge ${c.is_published ? 'badge-published' : 'badge-draft'}`} style={{ fontSize: 10 }}>
                  {c.is_published ? 'Published' : 'Draft'}
                </span>
                <ChevronRight size={14} style={{ color: 'var(--text-muted)', marginLeft: 'auto' }} />
              </div>
            </div>
          ))}
        </div>

        {/* Right: modules panel */}
        <div className="modules-panel">
          {!selectedCourse ? (
            <div className="empty-state">
              <BookOpen size={40} style={{ opacity: 0.3, marginBottom: 12 }} />
              <p>Select a course to manage its modules and lessons</p>
            </div>
          ) : (
            <>
              <div className="modules-header">
                <div>
                  <h2 style={{ fontSize: 20, fontWeight: 700, color: 'var(--text-primary)' }}>
                    {selectedCourse.title}
                  </h2>
                  <p style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>
                    {selectedCourse.description || 'No description'}
                  </p>
                </div>
                <button className="btn-small accent" onClick={() => setShowNewModule(true)}>
                  <Plus size={14} /> New Module
                </button>
              </div>

              {loadingModules ? (
                <div className="loading">Loading modules…</div>
              ) : modules.length === 0 ? (
                <div className="empty-state">
                  <p>No modules yet. Create the first one.</p>
                </div>
              ) : (
                <div className="table-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th style={{ width: 40 }}></th>
                        <th>Title</th>
                        <th>Description</th>
                        <th>Lessons</th>
                        <th>XP</th>
                        <th>Status</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {modules.map(m => (
                        <ModuleRow
                          key={m.id}
                          mod={m}
                          courseId={selectedCourse.id}
                          onModuleChange={refreshModules}
                        />
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </>
          )}
        </div>
      </div>

      {showNewModule && selectedCourse && (
        <ModuleFormModal
          courseId={selectedCourse.id}
          onSave={() => { setShowNewModule(false); refreshModules() }}
          onClose={() => setShowNewModule(false)}
        />
      )}
    </div>
  )
}

// ── Users Page ───────────────────────────────────────────────────
function UsersPage() {
  const [users, setUsers] = useState<UserOut[]>([])

  useEffect(() => { getUsers().then(setUsers).catch(() => {}) }, [])

  return (
    <div>
      <h1 className="page-title">Users</h1>
      <div className="table-wrap">
        <table>
          <thead>
            <tr>
              <th>ID</th><th>Email</th><th>Display Name</th>
              <th>Role</th><th>Level</th><th>XP</th><th>Streak</th>
            </tr>
          </thead>
          <tbody>
            {users.map(u => (
              <tr key={u.id}>
                <td>{u.id}</td>
                <td style={{ color: 'var(--text-primary)' }}>{u.email}</td>
                <td>{u.display_name}</td>
                <td><span className={`badge badge-${u.role}`}>{u.role}</span></td>
                <td>{u.level}</td>
                <td style={{ color: 'var(--accent)' }}>{u.xp.toLocaleString()}</td>
                <td>{u.streak}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

// ── App ──────────────────────────────────────────────────────────
export default function App() {
  const auth = useAuth()
  const navigate = useNavigate()

  const handleLogin = async (email: string, password: string) => {
    await auth.signIn(email, password)
    navigate('/')
  }

  if (!auth.token) return <LoginPage onLogin={handleLogin} />

  return (
    <div className="app-layout">
      <Sidebar onLogout={() => { auth.signOut(); navigate('/') }} />
      <main className="main-content">
        <Routes>
          <Route path="/" element={<DashboardPage />} />
          <Route path="/courses" element={<CoursesPage />} />
          <Route path="/media" element={<MediaLibraryPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  )
}
