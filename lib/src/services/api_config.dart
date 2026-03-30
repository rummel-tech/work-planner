/// Central API configuration. Call [ApiConfig.configure] once at startup.
class ApiConfig {
  static String _baseUrl = 'http://localhost:8040';

  static void configure({required String baseUrl}) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  }

  static String get baseUrl => _baseUrl;

  static Uri uri(String path) => Uri.parse('$_baseUrl$path');
}
