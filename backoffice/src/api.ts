import type {
  TokenResponse, User, Course, CourseCreate, Module, ModuleCreate,
  Lesson, LessonCreate, Quiz, BackofficeDashboard
} from './types';

const API_BASE = 'http://localhost:8000/api';

function getToken(): string | null {
  return localStorage.getItem('token');
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, { ...options, headers });
  if (res.status === 401) {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/login';
    throw new Error('Unauthorized');
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail || 'Request failed');
  }
  return res.json();
}

// Auth
export const api = {
  login: (email: string, password: string) =>
    request<TokenResponse>('/auth/backoffice-login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    }),

  // Dashboard
  getDashboard: () => request<BackofficeDashboard>('/progress/admin/dashboard'),

  // Users
  getUsers: (skip = 0, limit = 50) =>
    request<User[]>(`/users/?skip=${skip}&limit=${limit}`),
  getUser: (id: number) => request<User>(`/users/${id}`),

  // Courses
  getCourses: (publishedOnly = false) =>
    request<Course[]>(`/courses/?published_only=${publishedOnly}`),
  getCourse: (id: number) => request<Course>(`/courses/${id}`),
  createCourse: (data: CourseCreate) =>
    request<Course>('/courses/', { method: 'POST', body: JSON.stringify(data) }),
  updateCourse: (id: number, data: Partial<CourseCreate>) =>
    request<Course>(`/courses/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  deleteCourse: (id: number) =>
    request<{ ok: boolean }>(`/courses/${id}`, { method: 'DELETE' }),

  // Modules
  getCourseModules: (courseId: number) =>
    request<Module[]>(`/courses/${courseId}/modules`),
  getModule: (id: number) => request<Module>(`/modules/${id}`),
  createModule: (courseId: number, data: ModuleCreate) =>
    request<Module>(`/modules/?course_id=${courseId}`, { method: 'POST', body: JSON.stringify(data) }),
  updateModule: (id: number, data: Partial<ModuleCreate>) =>
    request<Module>(`/modules/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  deleteModule: (id: number) =>
    request<{ ok: boolean }>(`/modules/${id}`, { method: 'DELETE' }),

  // Lessons
  getModuleLessons: (moduleId: number) =>
    request<Lesson[]>(`/modules/${moduleId}/lessons`),
  createLesson: (moduleId: number, data: LessonCreate) =>
    request<Lesson>(`/modules/${moduleId}/lessons`, { method: 'POST', body: JSON.stringify(data) }),
  updateLesson: (id: number, data: Partial<LessonCreate>) =>
    request<Lesson>(`/modules/lessons/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),
  deleteLesson: (id: number) =>
    request<{ ok: boolean }>(`/modules/lessons/${id}`, { method: 'DELETE' }),

  // Quizzes
  getQuiz: (id: number) => request<Quiz>(`/quizzes/admin/${id}`),
  deleteQuiz: (id: number) =>
    request<{ ok: boolean }>(`/quizzes/${id}`, { method: 'DELETE' }),
};
