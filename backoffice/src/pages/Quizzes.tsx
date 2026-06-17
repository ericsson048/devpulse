import { useEffect, useState } from 'react';
import { api } from '../api';
import type { Course, Module, Lesson } from '../types';
import { DataTable } from 'primereact/datatable';
import { Column } from 'primereact/column';
import { Button } from 'primereact/button';
import { Tag } from 'primereact/tag';
import { ConfirmDialog, confirmDialog } from 'primereact/confirmdialog';

interface QuizInfo {
  lesson: Lesson;
  module: Module;
  course: Course;
}

export default function Quizzes() {
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
    confirmDialog({ message: 'Delete this quiz lesson?', header: 'Confirm', icon: 'pi pi-exclamation-triangle', accept: async () => { await api.deleteLesson(lid); load(); } });
  };
  const togglePublish = async (l: Lesson) => { await api.updateLesson(l.id, { is_published: !l.is_published }); load(); };

  const quizBody = (row: QuizInfo) => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
      <div style={{ width: 30, height: 30, borderRadius: 8, background: 'rgba(124,92,252,0.12)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <i className="pi pi-question-circle" style={{ fontSize: 14, color: 'var(--accent)' }} />
      </div>
      <span style={{ fontWeight: 500 }}>{row.lesson.title}</span>
    </div>
  );

  const courseBody = (row: QuizInfo) => row.course.title;
  const moduleBody = (row: QuizInfo) => row.module.title;

  const statusBody = (row: QuizInfo) => (
    <Tag
      value={row.lesson.is_published ? 'Published' : 'Draft'}
      severity={row.lesson.is_published ? 'success' : 'secondary'}
      icon={row.lesson.is_published ? 'pi pi-check-circle' : 'pi pi-minus-circle'}
      rounded
    />
  );

  const actionsBody = (row: QuizInfo) => (
    <div style={{ display: 'flex', gap: 4 }}>
      <Button icon={row.lesson.is_published ? 'pi pi-eye' : 'pi pi-eye-slash'} severity={row.lesson.is_published ? 'success' : 'secondary'} text rounded size="small" onClick={() => togglePublish(row.lesson)} />
      <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => handleDelete(row.lesson.id)} />
    </div>
  );

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

      <DataTable value={quizzes} loading={loading} stripedRows paginator rows={20}
        emptyMessage="No quiz lessons found. Add quiz-type lessons to your modules."
        className="p-datatable-sm" dataKey="lesson.id">
        <Column header="Quiz" body={quizBody} style={{ minWidth: 200 }} />
        <Column header="Course" body={courseBody} sortable sortField="course.title" style={{ minWidth: 160 }} />
        <Column header="Module" body={moduleBody} sortable sortField="module.title" style={{ minWidth: 160 }} />
        <Column header="XP" field="lesson.xp_reward" sortable style={{ width: 90 }} />
        <Column header="Status" body={statusBody} style={{ width: 140 }} />
        <Column header="Actions" body={actionsBody} style={{ width: 110 }} />
      </DataTable>
    </div>
  );
}
