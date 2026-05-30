class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.currency,
    required this.locale,
  });

  static const defaults = AppSettings(
    baseUrl: '',
    currency: 'RUB',
    locale: 'ru_RU',
  );

  final String baseUrl;
  final String currency;
  final String locale;

  AppSettings copyWith({
    String? baseUrl,
    String? currency,
    String? locale,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
    );
  }
}
