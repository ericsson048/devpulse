/// Central configuration for DevPulse.
///
/// Change [apiBaseUrl] to match your backend host when running on a real
/// device or emulator (replace localhost with your machine's LAN IP, e.g.
/// 'http://192.168.1.42:8000').
class AppConfig {
  AppConfig._();

  /// Base URL of the FastAPI backend, WITHOUT trailing slash.
  static const String apiBaseUrl = 'http://172.20.71.26:8000'; // Android emulator
  // static const String apiBaseUrl = 'http://localhost:8000'; // Web / iOS sim

  /// Resolve a media path returned by the backend (e.g. "/api/media/videos/abc.mp4")
  /// to a full URL.
  static String mediaUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path; // already absolute (YouTube, CDN, etc.)
    }
    // Local media served by FastAPI — prepend the base URL
    return '$apiBaseUrl$path';
  }
}
