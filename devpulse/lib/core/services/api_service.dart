import 'dart:convert';
import 'dart:io';
import '../utils/app_config.dart';

class ApiService {
  ApiService._();

  static final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10);

  static Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  static Future<dynamic> _get(String path) async {
    final headers = await _headers();
    final url = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final request = await _client.getUrl(url);
    headers.forEach((k, v) => request.headers.set(k, v));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 400) {
      throw HttpException('GET $path -> ${response.statusCode}: $body');
    }
    return jsonDecode(body);
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
}
