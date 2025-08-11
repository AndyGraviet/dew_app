import 'dart:io';

/// Script to generate app_config.dart from environment variables for CI/CD
/// Usage: dart scripts/generate_app_config.dart
void main() {
  final supabaseUrl = Platform.environment['SUPABASE_URL'];
  final supabaseAnonKey = Platform.environment['SUPABASE_ANON_KEY'];
  final googleWebClientId = Platform.environment['GOOGLE_WEB_CLIENT_ID'];
  final googleIosClientId = Platform.environment['GOOGLE_IOS_CLIENT_ID'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    stderr.writeln('Error: SUPABASE_URL environment variable not set');
    exit(1);
  }

  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    stderr.writeln('Error: SUPABASE_ANON_KEY environment variable not set');
    exit(1);
  }

  if (googleWebClientId == null || googleWebClientId.isEmpty) {
    stderr.writeln('Error: GOOGLE_WEB_CLIENT_ID environment variable not set');
    exit(1);
  }

  if (googleIosClientId == null || googleIosClientId.isEmpty) {
    stderr.writeln('Error: GOOGLE_IOS_CLIENT_ID environment variable not set');
    exit(1);
  }

  // Generate app_config.dart content for CI/CD
  final content = '''
// Generated file for CI/CD builds
// DO NOT EDIT MANUALLY - This file is generated from environment variables

class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = '$supabaseUrl';
  static const String supabaseAnonKey = '$supabaseAnonKey';
  
  // Google Sign-In Configuration
  static const String googleWebClientId = '$googleWebClientId';
  static const String googleIosClientId = '$googleIosClientId';
  
  // CI/CD build - no environment variables needed
  static Future<void> initialize() async {
    // No-op for CI/CD builds
  }
  
  static String get environment => 'production';
  static bool get isProduction => true;
  static bool get isDevelopment => false;
}
''';

  // Write to lib/config/app_config.dart
  final file = File('lib/config/app_config.dart');
  file.writeAsStringSync(content);
  
  print('✅ Generated app_config.dart for CI/CD build');
}