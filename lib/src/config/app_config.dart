class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://autotrader.az/api',
  );
  static const String recaptchaSiteKey = '';
}
