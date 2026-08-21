/// Batalat — App Constants
class AppConstants {
  AppConstants._();

  // API
  // Android emulator: use 10.0.2.2 — physical device / host: use LAN IP
  static const String baseUrl = 'https://app.alrgabe.com.ly/api/v1';

  /// Origin without `/api/v1` — used for absolute media URLs.
  static String get apiOrigin {
    final uri = Uri.parse(baseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage Keys
  static const String accessTokenKey  = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey     = 'user_data';
  static const String fcmTokenKey     = 'fcm_token';
  static const String onboardingKey   = 'onboarding_done';

  // Pagination
  static const int pageSize = 20;

  // Currency
  static const String currency = 'د.ل';

  // App Info
  static const String appName = 'Batalat';
  static const String appNameAr = 'باتلات';
  static const String supportPhone = '+218910000000';
  static const String supportEmail = 'support@batalat.ly';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Border Radius
  static const double radiusSmall  = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge  = 16.0;
  static const double radiusXLarge = 24.0;
  static const double radiusRound  = 50.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS  = 8.0;
  static const double spacingM  = 16.0;
  static const double spacingL  = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL= 48.0;

  // Padding
  static const double screenPadding = 20.0;
  static const double cardPadding   = 16.0;

  // Occasion Icons
  static const Map<String, String> occasionIcons = {
    'wedding':     '💍',
    'birthday':    '🎂',
    'anniversary': '❤️',
    'condolences': '🕊️',
    'graduation':  '🎓',
    'love':        '🌹',
    'corporate':   '🏢',
    'other':       '🌸',
  };
}
