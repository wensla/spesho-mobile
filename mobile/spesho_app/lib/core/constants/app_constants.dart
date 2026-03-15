class AppConstants {
  // Set at build time: flutter build apk --dart-define=API_BASE_URL=http://192.168.1.100:5000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  static const String roleManager = 'manager';
  static const String roleSalesperson = 'salesperson';

  static const List<String> grainProducts = ['Sembe', 'Dona', 'Mchele'];
}
