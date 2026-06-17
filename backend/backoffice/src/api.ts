const API = '';

export async function apiFetch<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem('token');
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(opts.headers as Record<string, string> || {}),
  };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const res = await fetch(`${API}${path}`, { ...opts, headers });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || res.statusText);
  }
  return res.json();
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  user: UserOut;
}

export interface UserOut {
  id: number;
  email: string;
  display_name: string;
  role: string;
  level: number;
  xp: number;
  streak: number;
}

export interface CourseOut {
  id: number;
  title: string;
  description: string | null;
  icon: string | null;
  tag: string | null;
  level: string;
  language: string | null;
  total_modules: number;
  total_xp: number;
  sort_order: number;
  is_published: boolean;
  created_at: string;
}

export interface ModuleOut {
  id: number;
  course_id: number;
  title: string;
  description: string | null;
  sort_order: number;
  total_lessons: number;
  total_xp: number;
  is_published: boolean;
  created_at: string;
}

export interface LessonOut {
  id: number;
  module_id: number;
  title: string;
  lesson_type: string;
  content: string | null;
  video_url: string | null;
  resources: string | null;
  code_template: string | null;
  code_language: string | null;
  has_editor: boolean;
  sort_order: number;
  xp_reward: number;
  is_published: boolean;
  created_at: string;
}

export interface LessonCreate {
  title: string;
  lesson_type: string;
  content?: string;
  video_url?: string;
  resources?: string;
  code_template?: string;
  code_solution?: string;
  code_language?: string;
  has_editor: boolean;
  sort_order: number;
  xp_reward: number;
  is_published: boolean;
}

export interface BackofficeDashboard {
  total_users: number;
  total_courses: number;
  total_modules: number;
  total_quizzes: number;
  active_users_today: number;
  total_quiz_attempts: number;
}

// ── Auth ──────────────────────────────────────────────────────────
export const login = (email: string, password: string) =>
  apiFetch<TokenResponse>('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });

// ── Dashboard ─────────────────────────────────────────────────────
export const getDashboard = () =>
  apiFetch<BackofficeDashboard>('/api/progress/admin/dashboard');

// ── Courses ───────────────────────────────────────────────────────
export const getCourses = () =>
  apiFetch<CourseOut[]>('/api/courses/?published_only=false');

// ── Modules ───────────────────────────────────────────────────────
export const getCourseModules = (courseId: number) =>
  apiFetch<ModuleOut[]>(`/api/courses/${courseId}/modules`);

export const createModule = (courseId: number, data: Partial<ModuleOut>) =>
  apiFetch<ModuleOut>(`/api/modules/?course_id=${courseId}`, {
    method: 'POST',
    body: JSON.stringify(data),
  });

export const updateModule = (moduleId: number, data: Partial<ModuleOut>) =>
  apiFetch<ModuleOut>(`/api/modules/${moduleId}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });

export const deleteModule = (moduleId: number) =>
  apiFetch<{ ok: boolean }>(`/api/modules/${moduleId}`, { method: 'DELETE' });

// ── Lessons ───────────────────────────────────────────────────────
export const getModuleLessons = (moduleId: number) =>
  apiFetch<LessonOut[]>(`/api/modules/${moduleId}/lessons`);

export const createLesson = (moduleId: number, data: LessonCreate) =>
  apiFetch<LessonOut>(`/api/modules/${moduleId}/lessons`, {
    method: 'POST',
    body: JSON.stringify(data),
  });

export const updateLesson = (lessonId: number, data: Partial<LessonCreate>) =>
  apiFetch<LessonOut>(`/api/modules/lessons/${lessonId}`, {
    method: 'PATCH',
    body: JSON.stringify(data),
  });

export const deleteLesson = (lessonId: number) =>
  apiFetch<{ ok: boolean }>(`/api/modules/lessons/${lessonId}`, {
    method: 'DELETE',
  });

// ── Users ─────────────────────────────────────────────────────────
export const getUsers = () => apiFetch<UserOut[]>('/api/users/');

// ── Media ─────────────────────────────────────────────────────────
export interface MediaItem {
  url: string;
  filename: string;
  original_name?: string;
  type: 'video' | 'image' | 'resource';
  mime: string;
  size_bytes: number;
}

export const uploadMedia = async (file: File): Promise<MediaItem> => {
  const token = localStorage.getItem('token');
  const form = new FormData();
  form.append('file', file);
  const res = await fetch('/api/media/upload', {
    method: 'POST',
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: form,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || res.statusText);
  }
  return res.json();
};

export const listMedia = (type = 'all') =>
  apiFetch<MediaItem[]>(`/api/media/list?media_type=${type}`);

export const deleteMedia = (subfolder: string, filename: string) =>
  apiFetch<{ ok: boolean }>(`/api/media/${subfolder}/${filename}`, {
    method: 'DELETE',
  });
