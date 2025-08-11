import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration class that loads values from environment variables
/// This prevents hardcoding sensitive information in the codebase
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Initialize environment variables
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
  }

  // Supabase Configuration
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in environment variables');
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in environment variables');
    }
    return key;
  }

  // Google Sign-In Configuration
  static String get googleWebClientId {
    final id = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (id == null || id.isEmpty) {
      throw Exception('GOOGLE_WEB_CLIENT_ID not found in environment variables');
    }
    return id;
  }

  static String get googleIosClientId {
    final id = dotenv.env['GOOGLE_IOS_CLIENT_ID'];
    if (id == null || id.isEmpty) {
      throw Exception('GOOGLE_IOS_CLIENT_ID not found in environment variables');
    }
    return id;
  }

  // Environment type
  static String get environment {
    return dotenv.env['ENVIRONMENT'] ?? 'development';
  }

  // Check if running in production
  static bool get isProduction {
    return environment == 'production';
  }

  // Check if running in development
  static bool get isDevelopment {
    return environment == 'development';
  }
}