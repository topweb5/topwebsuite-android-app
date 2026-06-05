class AppEnv {
  const AppEnv._();

  static const productionBaseUrl =
      'https://web-production-4266f.up.railway.app';
  static const localBaseUrl = 'http://127.0.0.1:8000';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  static Uri resolve(String path) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$apiBaseUrl$normalized');
  }
}
