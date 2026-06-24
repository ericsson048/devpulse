import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_config.dart';

/// Token store backed by SharedPreferences.
class _TokenStore {
  static String? _token;
  static const _key = 'auth_token';

  static String? get token => _token;
  static void setToken(String? t) {
    _token = t;
    _persist();
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_key);
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_key, _token!);
    } else {
      await prefs.remove(_key);
    }
  }
}

class ApiService {
  ApiService._();

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  static String? get token => _TokenStore.token;
  static void setToken(String? t) => _TokenStore.setToken(t);
  static Future<void> loadToken() => _TokenStore.loadToken();

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth && _TokenStore.token != null) {
      h['Authorization'] = 'Bearer ${_TokenStore.token}';
    }
    return h;
  }

  static Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    final headers = await _headers(auth: auth);
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final request = await _client.openUrl(method, url);
    headers.forEach((k, v) => request.headers.set(k, v));
    if (body != null) {
      request.write(jsonEncode(body));
    }
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      String detail;
      try { final json = jsonDecode(responseBody); detail = json['detail'] ?? responseBody; }
      catch (_) { detail = responseBody; }
      throw HttpException(detail);
    }
    if (responseBody.isEmpty) return null;
    return jsonDecode(responseBody);
  }

  static Future<dynamic> _get(String path, {bool auth = true}) =>
      _request('GET', path, auth: auth);
  static Future<dynamic> _post(String path, Map<String, dynamic> body, {bool auth = true}) =>
      _request('POST', path, body: body, auth: auth);
  static Future<dynamic> _patch(String path, Map<String, dynamic> body, {bool auth = true}) =>
      _request('PATCH', path, body: body, auth: auth);
  static Future<dynamic> _delete(String path, {bool auth = true}) =>
      _request('DELETE', path, auth: auth);

  // ── Auth ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await _post('/api/auth/login', {
      'email': email,
      'password': password,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    final data = await _post('/api/auth/register', {
      'email': email,
      'password': password,
      'display_name': displayName,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final data = await _get('/api/auth/me');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final data = await _post('/api/auth/forgot-password', {
      'email': email,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final data = await _post('/api/auth/reset-password', {
      'token': token,
      'new_password': newPassword,
    }, auth: false);
    return data as Map<String, dynamic>;
  }

  // ── Dashboard / Home ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getHomeDashboard() async {
    final data = await _get('/api/users/me/dashboard');
    return data as Map<String, dynamic>;
  }

  // ── Courses / Library ──────────────────────────────────────────
  static Future<List<dynamic>> getCourses({String? level, String? language, String? search}) async {
    final params = <String>[];
    if (level != null) params.add('level=$level');
    if (language != null) params.add('language=$language');
    if (search != null) params.add('search=$search');
    final qs = params.isEmpty ? '' : '?${params.join('&')}';
    final data = await _get('/api/courses/library$qs');
    if (data is Map && data.containsKey('items')) {
      return data['items'] as List<dynamic>;
    }
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getCoursesPaginated({
    String? level, String? language, String? search,
    int skip = 0, int limit = 20,
  }) async {
    final params = <String>['skip=$skip', 'limit=$limit'];
    if (level != null) params.add('level=$level');
    if (language != null) params.add('language=$language');
    if (search != null) params.add('search=$search');
    final qs = '?${params.join('&')}';
    final data = await _get('/api/courses/library$qs');
    return data as Map<String, dynamic>;
  }

  // ── Enrollment ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> enrollCourse(int courseId) async {
    final data = await _post('/api/courses/$courseId/enroll', {});
    return data as Map<String, dynamic>;
  }

  static Future<void> unenrollCourse(int courseId) async {
    await _post('/api/courses/$courseId/unenroll', {});
  }

  // ── Modules ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getCourse(int courseId) async {
    final data = await _get('/api/courses/$courseId');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getModules(int courseId) async {
    final data = await _get('/api/courses/$courseId/modules');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getModule(int moduleId) async {
    final data = await _get('/api/modules/$moduleId');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getModuleLessons(int moduleId) async {
    final data = await _get('/api/modules/$moduleId/lessons');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getLesson(int lessonId) async {
    final data = await _get('/api/modules/lessons/$lessonId');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> completeLesson(int lessonId) async {
    final data = await _post('/api/progress/lesson', {
      'lesson_id': lessonId,
      'status': 'completed',
    });
    return data as Map<String, dynamic>;
  }

  // ── Profile ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getUserProfile() async {
    final data = await _get('/api/users/me');
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getUserAchievements() async {
    final data = await _get('/api/users/me/achievements');
    return data as List<dynamic>;
  }

  static Future<List<dynamic>> getUserProgress() async {
    final data = await _get('/api/users/me/progress');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> updateProfile({String? displayName, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['display_name'] = displayName;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    final data = await _patch('/api/users/me', body);
    return data as Map<String, dynamic>;
  }

  // ── Quiz ──────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getQuiz(int quizId) async {
    final data = await _get('/api/quizzes/$quizId');
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> submitQuiz(int quizId, List<Map<String, dynamic>> answers) async {
    final data = await _post('/api/quizzes/$quizId/submit', {
      'answers': answers,
    });
    return data as Map<String, dynamic>;
  }

  // ── Code Execution ───────────────────────────────────────────
  static Future<Map<String, dynamic>> executeCode(String language, String code) async {
    final data = await _post('/api/code-exec/execute', {
      'language': language,
      'code': code,
    }, auth: true);
    return data as Map<String, dynamic>;
  }

  // ── Achievements ──────────────────────────────────────────────
  static Future<List<dynamic>> listAchievements() async {
    final data = await _get('/api/achievements/');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> createAchievement(Map<String, dynamic> body) async {
    final data = await _post('/api/achievements/', body);
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateAchievement(int id, Map<String, dynamic> body) async {
    final data = await _patch('/api/achievements/$id', body);
    return data as Map<String, dynamic>;
  }

  static Future<void> deleteAchievement(int id) async {
    await _delete('/api/achievements/$id');
  }

  // ── Media (placeholder) ────────────────────────────────────────
  static Future<List<dynamic>> listMedia() async {
    final data = await _get('/api/media/');
    return data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> uploadMedia(String filePath) async {
    // TODO: multipart upload
    throw UnimplementedError('Multipart upload not yet implemented');
  }

  static Future<void> deleteMedia(int id) async {
    await _delete('/api/media/$id');
  }
}
