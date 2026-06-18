import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/course/course_detail_screen.dart';
import '../../features/module/module_screen.dart';
import '../../features/lesson/lesson_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/quiz/quiz_result_screen.dart';
import '../../features/editor/editor_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';

/// Named route paths — single source of truth for the whole app.
class AppRoutes {
  AppRoutes._();

  // ── Pre-auth ──────────────────────────────────────────────────
  static const splash          = '/';
  static const onboarding      = '/onboarding';
  static const auth            = '/auth';
  static const forgotPassword  = '/forgot-password';

  // ── Shell (bottom nav) ────────────────────────────────────────
  static const home            = '/app/home';
  static const library         = '/app/library';
  static const course          = '/app/course/:courseId';
  static const module          = '/app/module/:moduleId';
  static const lesson          = '/app/lesson/:lessonId';
  static const quiz            = '/app/quiz';
  static const quizResult      = '/app/quiz-result';
  static const editor          = '/app/editor';
  static const profile         = '/app/profile';
  static const settings        = '/app/settings';

  /// Helper to build module route path
  static String coursePath(int courseId) => '/app/course/$courseId';
  static String modulePath(int moduleId) => '/app/module/$moduleId';
  /// Helper to build lesson route path
  static String lessonPath(int lessonId) => '/app/lesson/$lessonId';
  /// Helper to build quiz route path
  static String quizPath(int lessonId) => '/app/quiz/$lessonId';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Pre-auth screens ─────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (_, __) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, __) => const ForgotPasswordScreen(),
    ),

    // ── Authenticated shell ──────────────────────────────────────
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.library,
          builder: (_, __) => const LibraryScreen(),
        ),
        GoRoute(
          path: '/app/course/:courseId',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['courseId']!);
            return CourseDetailScreen(courseId: id);
          },
        ),
        GoRoute(
          path: '/app/module/:moduleId',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['moduleId']!);
            return ModuleScreen(moduleId: id);
          },
        ),
        GoRoute(
          path: '/app/module',
          redirect: (_, __) => '/app/module/1',
        ),
        GoRoute(
          path: '/app/lesson/:lessonId',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['lessonId']!);
            return LessonScreen(lessonId: id);
          },
        ),
        GoRoute(
          path: '/app/quiz/:lessonId',
          builder: (_, state) {
            final id = int.parse(state.pathParameters['lessonId']!);
            return QuizScreen(lessonId: id);
          },
        ),
        GoRoute(
          path: AppRoutes.quizResult,
          builder: (_, state) {
            final score = int.tryParse(
                    state.uri.queryParameters['score'] ?? '7') ?? 7;
            final total = int.tryParse(
                    state.uri.queryParameters['total'] ?? '10') ?? 10;
            return QuizResultScreen(score: score, total: total);
          },
        ),
        GoRoute(
          path: AppRoutes.editor,
          builder: (_, __) => const EditorScreen(),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, __) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
