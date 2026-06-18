import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Button } from 'primereact/button';
import { InputText } from 'primereact/inputtext';
import { InputNumber } from 'primereact/inputnumber';
import { InputTextarea } from 'primereact/inputtextarea';
import { Dialog } from 'primereact/dialog';
import { api } from '../api';
import type { Quiz, QuizQuestion } from '../types';

export default function QuizDetail() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [quiz, setQuiz] = useState<Quiz | null>(null);
  const [loading, setLoading] = useState(true);
  const [questionDialog, setQuestionDialog] = useState(false);
  const [editingQ, setEditingQ] = useState<QuizQuestion | null>(null);

  const emptyQ: QuizQuestion = { id: 0, question_text: '', code_snippet: null, option_a: '', option_b: '', option_c: '', option_d: '', correct_answer: 0, explanation: null, sort_order: 0 };
  const [qForm, setQForm] = useState<QuizQuestion>({ ...emptyQ });

  const load = async () => {
    if (!id) return;
    setLoading(true);
    try {
      const data = await api.getQuiz(parseInt(id));
      setQuiz(data);
    } finally { setLoading(false); }
  };
  useEffect(() => { load(); }, [id]);

  const openNewQ = () => { setQForm({ ...emptyQ }); setEditingQ(null); setQuestionDialog(true); };
  const openEditQ = (q: QuizQuestion) => { setQForm({ ...q }); setEditingQ(q); setQuestionDialog(true); };

  const saveQ = async () => {
    if (!quiz) return;
    try {
      // API doesn't have a single-question create, so we update the whole quiz
      const updatedQuestions = editingQ
        ? quiz.questions.map(q => q.id === editingQ.id ? qForm : q)
        : [...quiz.questions, { ...qForm, id: quiz.questions.length + 1 }];
      await api.updateQuiz(quiz.id, { questions: updatedQuestions });
      setQuestionDialog(false);
      load();
    } catch (e) { alert(e); }
  };

  const deleteQ = (questionId: number) => {
    if (!quiz) return;
    api.updateQuiz(quiz.id, { questions: quiz.questions.filter(q => q.id !== questionId) }).then(load);
  };

  if (loading) return <div className="page fade-in"><p>Loading...</p></div>;
  if (!quiz) return <div className="page fade-in"><p>Quiz not found</p></div>;

  return (
    <div className="page fade-in">
      <div className="page-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Button icon="pi pi-arrow-left" text rounded onClick={() => navigate('/quizzes')} />
          <div>
            <h1>{quiz.title}</h1>
            <p style={{ color: 'var(--text-dim)', fontSize: 13, marginTop: 4 }}>
              {quiz.questions.length} question{quiz.questions.length !== 1 ? 's' : ''} &middot; {quiz.time_limit_seconds}s time limit &middot; {quiz.xp_reward} XP
            </p>
          </div>
        </div>
        <Button label="Add Question" icon="pi pi-plus" onClick={openNewQ} />
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16, marginTop: 20 }}>
        {quiz.questions.map((q, i) => (
          <div key={q.id} style={{ background: 'var(--surface-card)', borderRadius: 10, padding: 20, border: '1px solid var(--surface-border)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
              <div>
                <span style={{ fontSize: 11, color: 'var(--text-dim)', fontWeight: 700, letterSpacing: 1 }}>Q{i + 1}</span>
                <p style={{ fontWeight: 500, marginTop: 4 }}>{q.question_text}</p>
              </div>
              <div style={{ display: 'flex', gap: 4 }}>
                <Button icon="pi pi-pencil" text rounded size="small" onClick={() => openEditQ(q)} />
                <Button icon="pi pi-trash" severity="danger" text rounded size="small" onClick={() => deleteQ(q.id)} />
              </div>
            </div>
            {q.code_snippet && <pre style={{ background: '#0D1117', padding: 12, borderRadius: 8, fontSize: 12, marginBottom: 12, overflow: 'auto' }}>{q.code_snippet}</pre>}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
              {[q.option_a, q.option_b, q.option_c, q.option_d].map((opt, oi) => (
                <div key={oi} style={{
                  padding: '10px 14px', borderRadius: 8, fontSize: 14,
                  border: `2px solid ${oi === q.correct_answer ? 'var(--green-500)' : 'var(--surface-border)'}`,
                  background: oi === q.correct_answer ? 'rgba(34,197,94,0.08)' : 'transparent',
                  color: oi === q.correct_answer ? 'var(--green-500)' : undefined
                }}>
                  <span style={{ fontWeight: 600 }}>${String.fromCharCode(65 + oi)}.</span> {opt}
                </div>
              ))}
            </div>
            {q.explanation && (
              <div style={{ marginTop: 12, padding: '10px 14px', background: 'rgba(124,92,252,0.06)', borderRadius: 8, border: '1px solid rgba(124,92,252,0.15)', fontSize: 13 }}>
                <strong>Explanation:</strong> {q.explanation}
              </div>
            )}
          </div>
        ))}
      </div>

      <Dialog header={editingQ ? 'Edit Question' : 'New Question'} visible={questionDialog} style={{ width: 600 }} onHide={() => setQuestionDialog(false)}
        footer={<div><Button label="Cancel" severity="secondary" text onClick={() => setQuestionDialog(false)} /><Button label="Save" onClick={saveQ} /></div>}>
        <div className="p-fluid" style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div>
            <label style={{ fontSize: 12, color: 'var(--text-dim)', display: 'block', marginBottom: 4 }}>QUESTION TEXT</label>
            <InputTextarea value={qForm.question_text} onChange={e => setQForm({ ...qForm, question_text: e.target.value })} rows={3} autoResize />
          </div>
          <div>
            <label style={{ fontSize: 12, color: 'var(--text-dim)', display: 'block', marginBottom: 4 }}>CODE SNIPPET (optional)</label>
            <InputTextarea value={qForm.code_snippet || ''} onChange={e => setQForm({ ...qForm, code_snippet: e.target.value })} rows={2} autoResize />
          </div>
          {['A', 'B', 'C', 'D'].map((letter, oi) => (
            <div key={letter}>
              <label style={{ fontSize: 12, color: 'var(--text-dim)', display: 'block', marginBottom: 4 }}>
                OPTION {letter} {oi === qForm.correct_answer ? <span style={{ color: 'var(--green-500)' }}>(correct)</span> : ''}
              </label>
              <div style={{ display: 'flex', gap: 8 }}>
                <InputText value={[qForm.option_a, qForm.option_b, qForm.option_c, qForm.option_d][oi]}
                  onChange={e => {
                    const upd = { ...qForm };
                    if (oi === 0) upd.option_a = e.target.value;
                    else if (oi === 1) upd.option_b = e.target.value;
                    else if (oi === 2) upd.option_c = e.target.value;
                    else upd.option_d = e.target.value;
                    setQForm(upd);
                  }} style={{ flex: 1 }} />
                <Button icon="pi pi-check" rounded text severity={oi === qForm.correct_answer ? 'success' : 'secondary'}
                  onClick={() => setQForm({ ...qForm, correct_answer: oi })} />
              </div>
            </div>
          ))}
          <div>
            <label style={{ fontSize: 12, color: 'var(--text-dim)', display: 'block', marginBottom: 4 }}>EXPLANATION</label>
            <InputTextarea value={qForm.explanation || ''} onChange={e => setQForm({ ...qForm, explanation: e.target.value })} rows={2} autoResize />
          </div>
        </div>
      </Dialog>
    </div>
  );
}
