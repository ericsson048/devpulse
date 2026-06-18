export type UserRole = 'user' | 'admin';
export type CourseLevel = 'beginner' | 'intermediate' | 'advanced';
export type LessonType = 'theory' | 'code' | 'quiz';

export interface User {
  id: number;
  email: string;
  display_name: string;
  avatar_url: string | null;
  role: UserRole;
  level: number;
  xp: number;
  streak: number;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export interface Course {
  id: number;
  title: string;
  description: string | null;
  icon: string | null;
  tag: string | null;
  level: CourseLevel;
  language: string | null;
  total_modules: number;
  total_xp: number;
  sort_order: number;
  is_published: boolean;
  created_at: string;
}

export interface CourseCreate {
  title: string;
  description?: string;
  icon?: string;
  tag?: string;
  level?: CourseLevel;
  language?: string;
  total_xp?: number;
  sort_order?: number;
  is_published?: boolean;
}

export interface Module {
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

export interface ModuleCreate {
  title: string;
  description?: string;
  sort_order?: number;
  total_xp?: number;
  is_published?: boolean;
}

export interface Lesson {
  id: number;
  module_id: number;
  title: string;
  lesson_type: LessonType;
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
  quiz_id: number | null;
}

export interface LessonCreate {
  title: string;
  lesson_type?: LessonType;
  content?: string;
  video_url?: string;
  resources?: string;
  code_template?: string;
  code_solution?: string;
  code_language?: string;
  has_editor?: boolean;
  sort_order?: number;
  xp_reward?: number;
  is_published?: boolean;
}

export interface QuizQuestion {
  id: number;
  question_text: string;
  code_snippet: string | null;
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_answer: number;
  explanation: string | null;
  sort_order: number;
}

export interface Quiz {
  id: number;
  module_id: number;
  title: string;
  time_limit_seconds: number;
  passing_score: number;
  xp_reward: number;
  is_published: boolean;
  questions: QuizQuestion[];
  created_at: string;
}

export interface BackofficeDashboard {
  total_users: number;
  total_courses: number;
  total_modules: number;
  total_quizzes: number;
  active_users_today: number;
  total_quiz_attempts: number;
}

export interface Achievement {
  id: number;
  title: string;
  description: string | null;
  icon: string | null;
  icon_bg: string | null;
  icon_color: string | null;
  xp_reward: number;
  condition_type: string | null;
  condition_value: number | null;
}

export interface MediaItem {
  id: number;
  filename: string;
  url: string;
  mime_type: string;
  file_size: number;
}
