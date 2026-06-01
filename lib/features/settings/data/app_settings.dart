class AppSettings {
  const AppSettings({
    required this.baseUrl,
    required this.currency,
    required this.locale,
    required this.comfortableWeeklyCapacityHours,
    required this.assumePastPayoutsPaid,
    required this.autoCheckUpdates,
    required this.includePrereleaseUpdates,
    required this.lastUpdateCheckAt,
    required this.allowInsecureKimaiHttp,
  });

  static const defaults = AppSettings(
    baseUrl: '',
    currency: 'RUB',
    locale: 'ru_RU',
    comfortableWeeklyCapacityHours: 40,
    assumePastPayoutsPaid: true,
    autoCheckUpdates: true,
    includePrereleaseUpdates: false,
    lastUpdateCheckAt: null,
    allowInsecureKimaiHttp: false,
  );

  final String baseUrl;
  final String currency;
  final String locale;
  final double comfortableWeeklyCapacityHours;
  final bool assumePastPayoutsPaid;
  final bool autoCheckUpdates;
  final bool includePrereleaseUpdates;
  final DateTime? lastUpdateCheckAt;
  final bool allowInsecureKimaiHttp;

  AppSettings copyWith({
    String? baseUrl,
    String? currency,
    String? locale,
    double? comfortableWeeklyCapacityHours,
    bool? assumePastPayoutsPaid,
    bool? autoCheckUpdates,
    bool? includePrereleaseUpdates,
    DateTime? lastUpdateCheckAt,
    bool? allowInsecureKimaiHttp,
  }) {
    return AppSettings(
      baseUrl: baseUrl ?? this.baseUrl,
      currency: currency ?? this.currency,
      locale: locale ?? this.locale,
      comfortableWeeklyCapacityHours:
          comfortableWeeklyCapacityHours ?? this.comfortableWeeklyCapacityHours,
      assumePastPayoutsPaid:
          assumePastPayoutsPaid ?? this.assumePastPayoutsPaid,
      autoCheckUpdates: autoCheckUpdates ?? this.autoCheckUpdates,
      includePrereleaseUpdates:
          includePrereleaseUpdates ?? this.includePrereleaseUpdates,
      lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
      allowInsecureKimaiHttp:
          allowInsecureKimaiHttp ?? this.allowInsecureKimaiHttp,
    );
  }
}
