class BackendConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://armonia-backend-jo2y.onrender.com',
  );
}
