/// Central API configuration. Call [ApiConfig.configure] once at startup.
class ApiConfig {
  static String _baseUrl = 'http://localhost:8040';
  static String _homeManagerUrl = 'http://localhost:8020';
  static String _vehicleManagerUrl = 'http://localhost:8030';

  static void configure({
    required String baseUrl,
    String homeManagerUrl = 'http://localhost:8020',
    String vehicleManagerUrl = 'http://localhost:8030',
  }) {
    _baseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    _homeManagerUrl = homeManagerUrl.endsWith('/')
        ? homeManagerUrl.substring(0, homeManagerUrl.length - 1)
        : homeManagerUrl;
    _vehicleManagerUrl = vehicleManagerUrl.endsWith('/')
        ? vehicleManagerUrl.substring(0, vehicleManagerUrl.length - 1)
        : vehicleManagerUrl;
  }

  static String get baseUrl => _baseUrl;
  static String get homeManagerUrl => _homeManagerUrl;
  static String get vehicleManagerUrl => _vehicleManagerUrl;

  static Uri uri(String path) => Uri.parse('$_baseUrl$path');
  static Uri homeManagerUri(String path) => Uri.parse('$_homeManagerUrl$path');
  static Uri vehicleManagerUri(String path) => Uri.parse('$_vehicleManagerUrl$path');
}
