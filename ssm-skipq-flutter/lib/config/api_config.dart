/// API configuration.
///
/// Override at build/run time:
/// flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ssmskipq-1-s1dg.onrender.com/api',
  );

  static String get socketUrl {
    var url = baseUrl;
    if (url.endsWith('/api')) {
      url = url.substring(0, url.length - 4);
    }
    return url;
  }

  static const String tokenKey = 'ssm_skipq_token';
}
