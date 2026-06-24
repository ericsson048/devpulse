import { useEffect, useState, useRef, type FormEvent } from "react";
import { useParams, Link } from "react-router-dom";
import { api } from "../api";
import type {
  Course,
  Module,
  Lesson,
  ModuleCreate,
  LessonCreate,
} from "../types";
import Button from "../components/ui/Button";
import Dialog from "../components/ui/Dialog";
import { Input, Textarea } from "../components/ui/Input";
import InputNumber from "../components/ui/InputNumber";
import Select from "../components/ui/Select";
import Toggle from "../components/ui/Toggle";
import Badge from "../components/ui/Badge";
import ConfirmDialog, { confirmDialog } from "../components/ui/ConfirmDialog";
import { useToast } from "../components/Toast";
import LessonPreview from "../components/preview/LessonPreview";
import {
  Loader2,
  Plus,
  Pencil,
  Trash2,
  Eye,
  EyeOff,
  ChevronDown,
  ChevronRight,
  ArrowLeft,
  Code,
  HelpCircle,
  FileText,
  BookOpen,
  Monitor,
  Upload,
} from "lucide-react";

const LESSON_TYPES = [
  { label: "Theory", value: "theory" },
  { label: "Code", value: "code" },
  { label: "Quiz", value: "quiz" },
];

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: 12,
  fontWeight: 600,
  color: "var(--text-secondary)",
  marginBottom: 6,
  letterSpacing: "0.3px",
};

const lessonIcon = (t: string) =>
  t === "code" ? (
    <Code className="w-3.5 h-3.5" />
  ) : t === "quiz" ? (
    <HelpCircle className="w-3.5 h-3.5" />
  ) : (
    <FileText className="w-3.5 h-3.5" />
  );

export default function CourseDetail() {
  const { toast } = useToast();
  const { id } = useParams<{ id: string }>();
  const [course, setCourse] = useState<Course | null>(null);
  const [modules, setModules] = useState<Module[]>([]);
  const [lessons, setLessons] = useState<Record<number, Lesson[]>>({});
  const [expanded, setExpanded] = useState<Set<number>>(new Set());
  const [loading, setLoading] = useState(true);

  const [showModuleDialog, setShowModuleDialog] = useState(false);
  const [editingModule, setEditingModule] = useState<Module | null>(null);
  const [moduleForm, setModuleForm] = useState<ModuleCreate>({
    title: "",
    description: "",
    sort_order: 0,
    total_xp: 0,
    is_published: false,
  });
  const [savingModule, setSavingModule] = useState(false);

  const [showLessonDialog, setShowLessonDialog] = useState(false);
  const [editingLesson, setEditingLesson] = useState<Lesson | null>(null);
  const [lessonModuleId, setLessonModuleId] = useState(0);
  const [lessonForm, setLessonForm] = useState<LessonCreate>({
    title: "",
    lesson_type: "theory",
    content: "",
    resources: "",
    video_url: "",
    sort_order: 0,
    xp_reward: 25,
    is_published: false,
  });
  const [savingLesson, setSavingLesson] = useState(false);
  const [publishingModuleId, setPublishingModuleId] = useState<number | null>(
    null,
  );
  const [publishingLessonId, setPublishingLessonId] = useState<number | null>(
    null,
  );
  const [previewLesson, setPreviewLesson] = useState<Lesson | null>(null);
  const [uploadingResourceIndex, setUploadingResourceIndex] = useState<number | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [previewModule, setPreviewModule] = useState<Module | null>(null);
  const [previewCourse, setPreviewCourse] = useState(false);

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const [c, m] = await Promise.all([
        api.getCourse(+id),
        api.getCourseModules(+id),
      ]);
      setCourse(c);
      setModules(m);
      const lm: Record<number, Lesson[]> = {};
      await Promise.all(
        m.map(async (mod) => {
          lm[mod.id] = await api.getModuleLessons(mod.id);
        }),
      );
      setLessons(lm);
    } finally {
      setLoading(false);
    }
  };
  useEffect(() => {
    load();
  }, [id]);

  const toggleExpand = (modId: number) => {
    setExpanded((prev) => {
      const n = new Set(prev);
      n.has(modId) ? n.delete(modId) : n.add(modId);
      return n;
    });
  };

  const openCreateModule = () => {
    setEditingModule(null);
    setModuleForm({
      title: "",
      description: "",
      sort_order: modules.length,
      total_xp: 0,
      is_published: false,
    });
    setShowModuleDialog(true);
  };
  const openEditModule = (m: Module) => {
    setEditingModule(m);
    setModuleForm({
      title: m.title,
      description: m.description || "",
      sort_order: m.sort_order,
      total_xp: m.total_xp,
      is_published: m.is_published,
    });
    setShowModuleDialog(true);
  };
  const handleModuleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSavingModule(true);
    try {
      if (editingModule) {
        await api.updateModule(editingModule.id, moduleForm);
        toast("Module updated", "success");
      } else {
        await api.createModule(+id!, moduleForm);
        toast("Module created", "success");
      }
      setShowModuleDialog(false);
      load();
    } catch (e) {
      toast((e as Error).message, "error");
    } finally {
      setSavingModule(false);
    }
  };
  const handleDeleteModule = (modId: number) => {
    confirmDialog({
      message: "Delete this module and all its lessons?",
      header: "Confirm",
      accept: async () => {
        try {
          await api.deleteModule(modId);
          load();
          toast("Module deleted", "success");
        } catch (e) {
          toast((e as Error).message, "error");
        }
      },
    });
  };
  const toggleModulePublish = async (m: Module) => {
    setPublishingModuleId(m.id);
    try {
      await api.updateModule(m.id, { is_published: !m.is_published });
      load();
      toast(
        m.is_published ? "Module unpublished" : "Module published",
        "success",
      );
    } catch (e) {
      toast((e as Error).message, "error");
    } finally {
      setPublishingModuleId(null);
    }
  };

  const openCreateLesson = (modId: number) => {
    setEditingLesson(null);
    setLessonModuleId(modId);
    setLessonForm({
      title: "",
      lesson_type: "theory",
      content: "",
      resources: "",
      video_url: "",
      sort_order: (lessons[modId] || []).length,
      xp_reward: 25,
      is_published: false,
    });
    setShowLessonDialog(true);
  };
  const openEditLesson = (l: Lesson) => {
    setEditingLesson(l);
    setLessonModuleId(l.module_id);
    setLessonForm({
      title: l.title,
      lesson_type: l.lesson_type,
      content: l.content || "",
      resources: l.resources || "",
      video_url: l.video_url || "",
      code_template: l.code_template || "",
      code_language: l.code_language || "",
      has_editor: l.has_editor,
      sort_order: l.sort_order,
      xp_reward: l.xp_reward,
      is_published: l.is_published,
    });
    setShowLessonDialog(true);
  };
  const handleLessonSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSavingLesson(true);
    try {
      if (editingLesson) {
        await api.updateLesson(editingLesson.id, lessonForm);
        toast("Lesson updated", "success");
      } else {
        await api.createLesson(lessonModuleId, lessonForm);
        toast("Lesson created", "success");
      }
      setShowLessonDialog(false);
      load();
    } catch (e) {
      toast((e as Error).message, "error");
    } finally {
      setSavingLesson(false);
    }
  };
  const handleDeleteLesson = (lid: number) => {
    confirmDialog({
      message: "Delete this lesson?",
      header: "Confirm",
      accept: async () => {
        try {
          await api.deleteLesson(lid);
          load();
          toast("Lesson deleted", "success");
        } catch (e) {
          toast((e as Error).message, "error");
        }
      },
    });
  };
  const toggleLessonPublish = async (l: Lesson) => {
    setPublishingLessonId(l.id);
    try {
      await api.updateLesson(l.id, { is_published: !l.is_published });
      load();
      toast(
        l.is_published ? "Lesson unpublished" : "Lesson published",
        "success",
      );
    } catch (e) {
      toast((e as Error).message, "error");
    } finally {
      setPublishingLessonId(null);
    }
  };

  if (loading)
    return (
      <div className="page">
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            minHeight: 200,
          }}
        >
          <Loader2 className="w-8 h-8 text-[var(--accent)] animate-spin" />
        </div>
      </div>
    );
  if (!course) return <div className="page page-error">Course not found</div>;

  return (
    <div className="page fade-in">
      <ConfirmDialog />

      <Link
        to="/courses"
        className="inline-flex items-center gap-1.5 text-gray-500 text-xs no-underline mb-4 hover:text-gray-300 transition-colors"
      >
        <ArrowLeft className="w-3.5 h-3.5" /> Back to Courses
      </Link>

      <div className="page-header">
        <div>
          <h1>
            {course.icon && (
              <span style={{ marginRight: 8 }}>{course.icon}</span>
            )}
            {course.title}
          </h1>
          <p style={{ color: "var(--text-dim)", fontSize: 13, marginTop: 4 }}>
            {course.description || "No description"}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="ghost"
            icon={<Monitor className="w-4 h-4" />}
            onClick={() => setPreviewCourse(true)}
          >
            Preview
          </Button>
          <Button
            icon={<Plus className="w-4 h-4" />}
            onClick={openCreateModule}
          >
            Add Module
          </Button>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        {modules.map((mod) => (
          <div
            key={mod.id}
            style={{
              background: "var(--bg-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "var(--radius-lg)",
              overflow: "hidden",
            }}
          >
            <div
              onClick={() => toggleExpand(mod.id)}
              className="flex items-center gap-3.5 px-4 py-3.5 cursor-pointer transition-colors hover:bg-[var(--bg-card-hover)]"
            >
              {expanded.has(mod.id) ? (
                <ChevronDown className="w-3.5 h-3.5 text-gray-500" />
              ) : (
                <ChevronRight className="w-3.5 h-3.5 text-gray-500" />
              )}
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 14 }}>{mod.title}</div>
                <div className="flex items-center gap-2 text-xs text-gray-500 mt-0.5">
                  <span>
                    {mod.total_lessons} lesson
                    {mod.total_lessons !== 1 ? "s" : ""}
                  </span>
                  <span>·</span>
                  <span>{mod.total_xp} XP</span>
                  {!mod.is_published && (
                    <Badge
                      value="Draft"
                      severity="secondary"
                      className="text-[10px]"
                    />
                  )}
                </div>
              </div>
              <div
                style={{ display: "flex", gap: 4 }}
                onClick={(e) => e.stopPropagation()}
              >
                <button
                  className="p-1.5 rounded-md text-gray-400 hover:text-cyan-400 hover:bg-gray-700 transition-colors"
                  onClick={() => setPreviewModule(mod)}
                  title="Preview module"
                >
                  <Monitor className="w-4 h-4" />
                </button>
                <button
                  className="p-1.5 rounded-md text-gray-400 hover:text-green-400 hover:bg-gray-700 transition-colors disabled:opacity-40 disabled:pointer-events-none"
                  onClick={() => toggleModulePublish(mod)}
                  disabled={publishingModuleId === mod.id}
                  title="Toggle publish"
                >
                  {publishingModuleId === mod.id ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : mod.is_published ? (
                    <Eye className="w-4 h-4" />
                  ) : (
                    <EyeOff className="w-4 h-4" />
                  )}
                </button>
                <button
                  className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
                  onClick={() => openEditModule(mod)}
                  title="Edit"
                >
                  <Pencil className="w-4 h-4" />
                </button>
                <button
                  className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors"
                  onClick={() => handleDeleteModule(mod.id)}
                  title="Delete"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>

            {expanded.has(mod.id) && (
              <div className="px-4 pb-3.5" style={{ paddingLeft: 52 }}>
                {(lessons[mod.id] || []).map((l) => (
                  <div
                    key={l.id}
                    className="flex items-center justify-between px-3.5 py-2 rounded-lg transition-colors hover:bg-[var(--bg-card-hover)]"
                  >
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 10,
                        flex: 1,
                      }}
                    >
                      <span className="text-gray-500">
                        {lessonIcon(l.lesson_type)}
                      </span>
                      <span style={{ fontSize: 13 }}>{l.title}</span>
                      <Badge
                        value={l.lesson_type}
                        severity="info"
                        className="text-[10px] px-1.5 py-0.5"
                      />
                      <span style={{ fontSize: 11, color: "var(--text-dim)" }}>
                        +{l.xp_reward} XP
                      </span>
                    </div>
                    <div style={{ display: "flex", gap: 2 }}>
                      <button
                        className="p-1.5 rounded-md text-gray-400 hover:text-cyan-400 hover:bg-gray-700 transition-colors"
                        onClick={() => setPreviewLesson(l)}
                        title="Preview lesson"
                      >
                        <Eye className="w-4 h-4" />
                      </button>
                      {l.lesson_type === "quiz" && (l as any).quiz_id && (
                        <Link to={`/quizzes/${(l as any).quiz_id}`}>
                          <button
                            className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
                            title="View Quiz"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                        </Link>
                      )}
                      <button
                        className="p-1.5 rounded-md text-gray-400 hover:text-green-400 hover:bg-gray-700 transition-colors disabled:opacity-40 disabled:pointer-events-none"
                        onClick={() => toggleLessonPublish(l)}
                        disabled={publishingLessonId === l.id}
                        title="Toggle publish"
                      >
                        {publishingLessonId === l.id ? (
                          <Loader2 className="w-4 h-4 animate-spin" />
                        ) : l.is_published ? (
                          <Eye className="w-4 h-4" />
                        ) : (
                          <EyeOff className="w-4 h-4" />
                        )}
                      </button>
                      <button
                        className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors"
                        onClick={() => openEditLesson(l)}
                        title="Edit"
                      >
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button
                        className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors"
                        onClick={() => handleDeleteLesson(l.id)}
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                ))}
                <Button
                  variant="ghost"
                  icon={<Plus className="w-3.5 h-3.5" />}
                  className="mt-2"
                  size="sm"
                  onClick={() => openCreateLesson(mod.id)}
                >
                  Add Lesson
                </Button>
              </div>
            )}
          </div>
        ))}
        {modules.length === 0 && (
          <div
            style={{
              background: "var(--bg-card)",
              border: "1px solid var(--border-subtle)",
              borderRadius: "var(--radius-lg)",
              padding: "40px",
              textAlign: "center",
              color: "var(--text-dim)",
            }}
          >
            No modules yet. Add your first module!
          </div>
        )}
      </div>

      {/* Module Dialog */}
      <Dialog
        header={editingModule ? "Edit Module" : "New Module"}
        visible={showModuleDialog}
        onHide={() => setShowModuleDialog(false)}
        width="480px"
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => setShowModuleDialog(false)}
              disabled={savingModule}
            >
              Cancel
            </Button>
            <Button onClick={handleModuleSubmit} loading={savingModule}>
              {editingModule ? "Update" : "Create"}
            </Button>
          </>
        }
      >
        <form
          onSubmit={handleModuleSubmit}
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 14,
            paddingTop: 12,
          }}
        >
          <div>
            <label style={labelStyle}>Title *</label>
            <Input
              value={moduleForm.title}
              onChange={(e) =>
                setModuleForm({ ...moduleForm, title: e.target.value })
              }
              required
            />
          </div>
          <div>
            <label style={labelStyle}>Description</label>
            <Textarea
              value={moduleForm.description || ""}
              onChange={(e) =>
                setModuleForm({ ...moduleForm, description: e.target.value })
              }
              rows={2}
            />
          </div>
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <div>
              <label style={labelStyle}>Total XP</label>
              <InputNumber
                value={moduleForm.total_xp || 0}
                onValueChange={(e) =>
                  setModuleForm({ ...moduleForm, total_xp: e.value || 0 })
                }
              />
            </div>
            <div>
              <label style={labelStyle}>Sort Order</label>
              <InputNumber
                value={moduleForm.sort_order || 0}
                onValueChange={(e) =>
                  setModuleForm({ ...moduleForm, sort_order: e.value || 0 })
                }
              />
            </div>
          </div>
          <div>
            <Toggle
              checked={moduleForm.is_published || false}
              onChange={(e) =>
                setModuleForm({ ...moduleForm, is_published: e.value })
              }
              onLabel="Published"
              offLabel="Draft"
            />
          </div>
        </form>
      </Dialog>

      {/* Lesson Dialog */}
      <Dialog
        header={editingLesson ? "Edit Lesson" : "New Lesson"}
        visible={showLessonDialog}
        onHide={() => setShowLessonDialog(false)}
        width="620px"
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => setShowLessonDialog(false)}
              disabled={savingLesson}
            >
              Cancel
            </Button>
            <Button onClick={handleLessonSubmit} loading={savingLesson}>
              {editingLesson ? "Update" : "Create"}
            </Button>
          </>
        }
      >
        <form
          onSubmit={handleLessonSubmit}
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 14,
            paddingTop: 12,
          }}
        >
          <div>
            <label style={labelStyle}>Title *</label>
            <Input
              value={lessonForm.title}
              onChange={(e) =>
                setLessonForm({ ...lessonForm, title: e.target.value })
              }
              required
            />
          </div>
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <div>
              <label style={labelStyle}>Type</label>
              <Select
                value={lessonForm.lesson_type}
                options={LESSON_TYPES}
                onChange={(e) =>
                  setLessonForm({ ...lessonForm, lesson_type: e.value })
                }
              />
            </div>
            <div>
              <label style={labelStyle}>XP Reward</label>
              <InputNumber
                value={lessonForm.xp_reward || 25}
                onValueChange={(e) =>
                  setLessonForm({ ...lessonForm, xp_reward: e.value || 25 })
                }
              />
            </div>
          </div>
          <div>
            <label style={labelStyle}>Content (Markdown)</label>
            <Textarea
              value={lessonForm.content || ""}
              onChange={(e) =>
                setLessonForm({ ...lessonForm, content: e.target.value })
              }
              rows={5}
            />
          </div>
          <div>
            <label style={labelStyle}>Video URL (optional)</label>
            <Input
              value={lessonForm.video_url || ""}
              onChange={(e) =>
                setLessonForm({ ...lessonForm, video_url: e.target.value })
              }
              placeholder="https://youtube.com/embed/..."
            />
          </div>
          <div>
            <label style={labelStyle}>
              Resources (JSON)
              <span style={{ fontWeight: 400, color: "var(--text-dim)" }}>
                {" "}
                — [{'{"title": "...", "url": "...", "type": "link|pdf|github"}'}
                ]
              </span>
              <button
                type="button"
                className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors float-right"
                onClick={() => {
                  const current = (() => {
                    try {
                      return JSON.parse(lessonForm.resources || "[]");
                    } catch {
                      return [];
                    }
                  })();
                  current.push({ title: "", url: "", type: "link" });
                  setLessonForm({
                    ...lessonForm,
                    resources: JSON.stringify(current),
                  });
                }}
              >
                <Plus className="w-4 h-4" />
              </button>
            </label>
            <input
              type="file"
              ref={fileInputRef}
              hidden
              accept=".pdf,application/pdf"
              onChange={async (e) => {
                const file = e.target.files?.[0];
                if (!file || uploadingResourceIndex === null) return;
                try {
                  const media = await api.uploadMedia(file);
                  const items = JSON.parse(lessonForm.resources || "[]");
                  if (Array.isArray(items) && items[uploadingResourceIndex]) {
                    items[uploadingResourceIndex].url = media.url;
                    setLessonForm({
                      ...lessonForm,
                      resources: JSON.stringify(items),
                    });
                  }
                } catch (err) {
                  toast((err as Error).message, "error");
                } finally {
                  setUploadingResourceIndex(null);
                  e.target.value = "";
                }
              }}
            />
            <div
              style={{
                display: "flex",
                flexDirection: "column",
                gap: 6,
                marginBottom: 8,
              }}
            >
              {(() => {
                  try {
                    const items = JSON.parse(lessonForm.resources || "[]");
                    if (!Array.isArray(items) || items.length === 0) return null;
                    return items.map((r: any, i: number) => (
                      <div
                        key={i}
                        style={{ display: "flex", gap: 6, alignItems: "center" }}
                      >
                        <Input
                          value={r.title || ""}
                          onChange={(e) => {
                            const copy = [...items];
                            copy[i] = { ...copy[i], title: e.target.value };
                            setLessonForm({
                              ...lessonForm,
                              resources: JSON.stringify(copy),
                            });
                          }}
                          placeholder="Title"
                          style={{ flex: 2 }}
                        />
                        <Input
                          value={r.url || ""}
                          onChange={(e) => {
                            const copy = [...items];
                            copy[i] = { ...copy[i], url: e.target.value };
                            setLessonForm({
                              ...lessonForm,
                              resources: JSON.stringify(copy),
                            });
                          }}
                          placeholder="URL"
                          style={{ flex: 3 }}
                        />
                        {(r.type === "pdf") && (
                          <button
                            type="button"
                            className="p-1.5 rounded-md text-gray-400 hover:text-cyan-400 hover:bg-gray-700 transition-colors disabled:opacity-40"
                            onClick={() => {
                              setUploadingResourceIndex(i);
                              fileInputRef.current?.click();
                            }}
                            disabled={uploadingResourceIndex === i}
                            title="Upload file"
                          >
                            {uploadingResourceIndex === i ? (
                              <Loader2 className="w-4 h-4 animate-spin" />
                            ) : (
                              <Upload className="w-4 h-4" />
                            )}
                          </button>
                        )}
                        <select
                          value={r.type || "link"}
                          onChange={(e) => {
                            const copy = [...items];
                            copy[i] = { ...copy[i], type: e.target.value };
                            setLessonForm({
                              ...lessonForm,
                              resources: JSON.stringify(copy),
                            });
                          }}
                          className="bg-gray-800 border border-gray-700 rounded-md px-2 py-1.5 text-sm text-gray-200"
                          style={{ width: 100 }}
                        >
                          <option value="link">Link</option>
                          <option value="pdf">PDF</option>
                          <option value="github">GitHub</option>
                        </select>
                        <button
                          type="button"
                          className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors"
                          onClick={() => {
                            const copy = items.filter(
                              (_: any, j: number) => j !== i,
                            );
                            setLessonForm({
                              ...lessonForm,
                              resources: JSON.stringify(copy),
                            });
                          }}
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    ));
                  } catch {
                    return null;
                  }
                })()
              }
            </div>
            <Textarea
              value={lessonForm.resources || ""}
              onChange={(e) =>
                setLessonForm({ ...lessonForm, resources: e.target.value })
              }
              rows={2}
              placeholder='[{"title": "Express Docs", "url": "https://expressjs.com", "type": "link"}]'
              className="text-[11px] font-mono"
            />
          </div>
          {lessonForm.lesson_type === "code" && (
            <>
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "1fr 1fr",
                  gap: 12,
                }}
              >
                <div>
                  <label style={labelStyle}>Code Language</label>
                  <Input
                    value={lessonForm.code_language || ""}
                    onChange={(e) =>
                      setLessonForm({
                        ...lessonForm,
                        code_language: e.target.value,
                      })
                    }
                    placeholder="python, javascript..."
                  />
                </div>
                <div style={{ display: "flex", alignItems: "flex-end" }}>
                  <Toggle
                    checked={lessonForm.has_editor || false}
                    onChange={(e) =>
                      setLessonForm({ ...lessonForm, has_editor: e.value })
                    }
                    onLabel="Editor ON"
                    offLabel="Editor OFF"
                  />
                </div>
              </div>
              <div>
                <label style={labelStyle}>Code Template</label>
                <Textarea
                  value={lessonForm.code_template || ""}
                  onChange={(e) =>
                    setLessonForm({
                      ...lessonForm,
                      code_template: e.target.value,
                    })
                  }
                  rows={4}
                  className="font-mono text-xs"
                />
              </div>
            </>
          )}
          <div
            style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
          >
            <div>
              <label style={labelStyle}>Sort Order</label>
              <InputNumber
                value={lessonForm.sort_order || 0}
                onValueChange={(e) =>
                  setLessonForm({ ...lessonForm, sort_order: e.value || 0 })
                }
              />
            </div>
            <div style={{ display: "flex", alignItems: "flex-end" }}>
              <Toggle
                checked={lessonForm.is_published || false}
                onChange={(e) =>
                  setLessonForm({ ...lessonForm, is_published: e.value })
                }
                onLabel="Published"
                offLabel="Draft"
              />
            </div>
          </div>
        </form>
      </Dialog>

      {/* Lesson Preview */}
      {previewLesson && (
        <LessonPreview
          lesson={previewLesson}
          onHide={() => setPreviewLesson(null)}
        />
      )}

      {/* Module Preview */}
      <Dialog
        header={
          <div className="flex items-center gap-3">
            <BookOpen className="w-4 h-4 text-cyan-400" />
            <span>{previewModule?.title}</span>
            {previewModule && !previewModule.is_published && (
              <Badge
                value="Draft"
                severity="secondary"
                className="text-[10px]"
              />
            )}
          </div>
        }
        visible={!!previewModule}
        onHide={() => setPreviewModule(null)}
        width="620px"
      >
        {previewModule && (
          <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-1">
            {previewModule.description && (
              <p className="text-sm text-gray-400">
                {previewModule.description}
              </p>
            )}
            <div className="flex items-center gap-3 text-xs text-gray-500">
              <span>
                {(lessons[previewModule.id] || []).length} lesson
                {(lessons[previewModule.id] || []).length !== 1 ? "s" : ""}
              </span>
              <span>·</span>
              <span>{previewModule.total_xp} XP</span>
            </div>

            <div className="space-y-1.5">
              {(lessons[previewModule.id] || []).map((l) => (
                <div
                  key={l.id}
                  className="flex items-center gap-3 px-3.5 py-2.5 rounded-lg bg-gray-800/40 border border-gray-700/40 hover:bg-gray-700/40 hover:border-gray-600 cursor-pointer transition-colors"
                  onClick={() => setPreviewLesson(l)}
                >
                  <span className="text-gray-500">
                    {lessonIcon(l.lesson_type)}
                  </span>
                  <span className="flex-1 text-sm text-gray-200">
                    {l.title}
                  </span>
                  <Badge
                    value={l.lesson_type}
                    severity="info"
                    className="text-[10px]"
                  />
                  <span className="text-xs text-gray-500">
                    +{l.xp_reward} XP
                  </span>
                  <Eye className="w-3.5 h-3.5 text-gray-500" />
                </div>
              ))}
              {(lessons[previewModule.id] || []).length === 0 && (
                <p className="text-sm text-gray-500 text-center py-8">
                  No lessons in this module
                </p>
              )}
            </div>
          </div>
        )}
      </Dialog>

      {/* Course Preview */}
      <Dialog
        header={
          <div className="flex items-center gap-3">
            <Monitor className="w-4 h-4 text-cyan-400" />
            <span>{course.title}</span>
          </div>
        }
        visible={previewCourse}
        onHide={() => setPreviewCourse(false)}
        width="680px"
      >
        <div className="space-y-5 max-h-[65vh] overflow-y-auto pr-1">
          <div>
            <p className="text-sm text-gray-400 mb-3">
              {course.description || "No description"}
            </p>
            <div className="flex flex-wrap gap-3 text-xs text-gray-500">
              <Badge
                value={course.level}
                severity="info"
                className="text-[10px]"
              />
              {course.language && (
                <Badge
                  value={course.language}
                  severity="secondary"
                  className="text-[10px]"
                />
              )}
              <span>
                {modules.length} module{modules.length !== 1 ? "s" : ""}
              </span>
              <span>·</span>
              <span>{course.total_xp} XP</span>
              {!course.is_published && (
                <Badge
                  value="Draft"
                  severity="secondary"
                  className="text-[10px]"
                />
              )}
            </div>
          </div>

          <div className="space-y-2">
            {modules.map((mod) => (
              <div
                key={mod.id}
                className="bg-gray-800/30 border border-gray-700/40 rounded-xl overflow-hidden"
              >
                <div className="flex items-center gap-3 px-4 py-3">
                  <BookOpen className="w-4 h-4 text-gray-500" />
                  <div className="flex-1">
                    <div className="text-sm font-medium text-gray-200">
                      {mod.title}
                    </div>
                    <div className="text-xs text-gray-500">
                      {(lessons[mod.id] || []).length} lesson
                      {(lessons[mod.id] || []).length !== 1 ? "s" : ""} ·{" "}
                      {mod.total_xp} XP
                    </div>
                  </div>
                  <button
                    className="p-1.5 rounded-md text-gray-500 hover:text-cyan-400 hover:bg-gray-700 transition-colors"
                    onClick={() => setPreviewModule(mod)}
                    title="View module"
                  >
                    <Eye className="w-3.5 h-3.5" />
                  </button>
                </div>
                <div
                  className="px-4 pb-3 space-y-1"
                  style={{ paddingLeft: 52 }}
                >
                  {(lessons[mod.id] || []).map((l) => (
                    <div
                      key={l.id}
                      className="flex items-center gap-2.5 px-3 py-1.5 rounded-lg hover:bg-gray-700/40 cursor-pointer transition-colors"
                      onClick={() => setPreviewLesson(l)}
                    >
                      <span className="text-gray-500">
                        {lessonIcon(l.lesson_type)}
                      </span>
                      <span className="flex-1 text-xs text-gray-300">
                        {l.title}
                      </span>
                      <Badge
                        value={l.lesson_type}
                        severity="info"
                        className="text-[9px] px-1 py-0.5"
                      />
                      <span className="text-[10px] text-gray-500">
                        +{l.xp_reward} XP
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
          {modules.length === 0 && (
            <p className="text-sm text-gray-500 text-center py-8">
              No modules in this course
            </p>
          )}
        </div>
      </Dialog>
    </div>
  );
}
