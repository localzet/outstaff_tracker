class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.currency,
    required this.locale,
    required this.comfortableWeeklyCapacityHours,
    required this.assumePastPayoutsPaid,
  });

  static const defaults = AppSettings(
    baseUrl: '',
    currency: 'RUB',
    locale: 'ru_RU',
    comfortableWeeklyCapacityHours: 40,
    assumePastPayoutsPaid: true,
  );

  final String baseUrl;
  final String currency;
  final String locale;
  final double comfortableWeeklyCapacityHours;
  final bool assumePastPayoutsPaid;

  AppSettings copyWith({
    String? baseUrl,
    String? currency,
    String? locale,
    double? comfortableWeeklyCapacityHours,
    bool? assumePastPayoutsPaid,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      comfortableWeeklyCapacityHours:
          comfortableWeeklyCapacityHours ?? this.comfortableWeeklyCapacityHours,
      assumePastPayoutsPaid:
          assumePastPayoutsPaid ?? this.assumePastPayoutsPaid,
    );
  }
}
