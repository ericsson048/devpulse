import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api';
import type { Course, Module, Lesson } from '../types';
import Table, { type ColumnDef } from '../components/ui/Table';
import Button from '../components/ui/Button';
import Badge from '../components/ui/Badge';
import ConfirmDialog, { confirmDialog } from '../components/ui/ConfirmDialog';
import { useToast } from '../components/Toast';
import { HelpCircle, Eye, EyeOff, Trash2, CheckCircle, XCircle } from 'lucide-react';

interface QuizInfo {
  lesson: Lesson;
  module: Module;
  course: Course;
}

export default function Quizzes() {
  const { toast } = useToast();
  const navigate = useNavigate();
  const [quizzes, setQuizzes] = useState<QuizInfo[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const courses = await api.getCourses(false);
      const all: QuizInfo[] = [];
      for (const course of courses) {
        const modules = await api.getCourseModules(course.id);
        for (const mod of modules) {
          const lessons = await api.getModuleLessons(mod.id);
          for (const lesson of lessons) {
            if (lesson.lesson_type === 'quiz') all.push({ lesson, module: mod, course });
          }
        }
      }
      setQuizzes(all);
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, []);

  const handleDelete = (lid: number) => {
    confirmDialog({ message: 'Delete this quiz lesson?', header: 'Confirm', accept: async () => { try { await api.deleteLesson(lid); load(); toast('Quiz deleted', 'success'); } catch (e) { toast((e as Error).message, 'error'); } } });
  };
  const togglePublish = async (l: Lesson) => { try { await api.updateLesson(l.id, { is_published: !l.is_published }); load(); toast(l.is_published ? 'Quiz unpublished' : 'Quiz published', 'success'); } catch (e) { toast((e as Error).message, 'error'); } };

  const columns: ColumnDef<QuizInfo>[] = [
    {
      header: 'Quiz', style: { minWidth: 200 },
      body: (row) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ width: 30, height: 30, borderRadius: 8, background: 'rgba(124,92,252,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <HelpCircle className="w-3.5 h-3.5" style={{ color: 'var(--accent)' }} />
          </div>
          <span style={{ fontWeight: 500 }}>{row.lesson.title}</span>
        </div>
      ),
    },
    { header: 'Course', body: (row) => row.course.title, sortable: true, sortField: 'course.title', style: { minWidth: 160 } },
    { header: 'Module', body: (row) => row.module.title, sortable: true, sortField: 'module.title', style: { minWidth: 160 } },
    { header: 'XP', field: 'lesson.xp_reward' as string, sortable: true, style: { width: 90 } },
    {
      header: 'Status', style: { width: 140 },
      body: (row) => (
        <Badge
          value={row.lesson.is_published ? 'Published' : 'Draft'}
          severity={row.lesson.is_published ? 'success' : 'secondary'}
          icon={row.lesson.is_published ? <CheckCircle className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
        />
      ),
    },
    {
      header: 'Actions', style: { width: 110 },
      body: (row) => (
        <div style={{ display: 'flex', gap: 4 }}>
          <button className="p-1.5 rounded-md text-gray-400 hover:text-white hover:bg-gray-700 transition-colors" onClick={() => row.lesson.quiz_id && navigate(`/quizzes/${row.lesson.quiz_id}`)} title="View">
            <Eye className="w-4 h-4" />
          </button>
          <button className="p-1.5 rounded-md text-gray-400 hover:text-green-400 hover:bg-gray-700 transition-colors" onClick={() => togglePublish(row.lesson)} title="Toggle publish">
            {row.lesson.is_published ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
          <button className="p-1.5 rounded-md text-gray-400 hover:text-red-400 hover:bg-gray-700 transition-colors" onClick={() => handleDelete(row.lesson.id)} title="Delete">
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
          <h1>Quizzes</h1>
          <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
            {quizzes.length} quiz{quizzes.length !== 1 ? 'zes' : ''} across all courses
          </p>
        </div>
      </div>

      <Table value={quizzes} columns={columns} loading={loading} striped paginator rows={20}
        emptyMessage="No quiz lessons found. Add quiz-type lessons to your modules."
        dataKey="lesson.id" />
    </div>
  );
}
