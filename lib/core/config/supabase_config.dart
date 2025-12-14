import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase configuration constants
/// Credentials are loaded from .env file for security
///
/// Usage:
/// 1. Create .env file in project root with your Supabase credentials
/// 2. Make sure .env is added to .gitignore
/// 3. Set useLocal = true for local development or false for production
class SupabaseConfig {
  SupabaseConfig._();

  // === ACTIVE CONFIGURATION ===
  // Switch between local and production
  // true = use LOCAL_SUPABASE_* variables from .env
  // false = use PRODUCTION_SUPABASE_* variables from .env
  static const bool useLocal = false;

  // === LOAD FROM ENV ===
  static String get localUrl =>
      dotenv.get('LOCAL_SUPABASE_URL', fallback: 'http://127.0.0.1:54321');

  static String get localAnonKey =>
      dotenv.get('LOCAL_SUPABASE_ANON_KEY', fallback: '');

  static String get productionUrl =>
      dotenv.get('PRODUCTION_SUPABASE_URL', fallback: '');

  static String get productionAnonKey =>
      dotenv.get('PRODUCTION_SUPABASE_ANON_KEY', fallback: '');

  // === ACTIVE VALUES ===
  static String get url => useLocal ? localUrl : productionUrl;
  static String get anonKey => useLocal ? localAnonKey : productionAnonKey;

  // === VALIDATION ===
  static bool get isConfigured {
    if (useLocal) {
      return localUrl.isNotEmpty && localAnonKey.isNotEmpty;
    }
    return productionUrl.isNotEmpty && productionAnonKey.isNotEmpty;
  }

  static String get statusMessage {
    if (!isConfigured) {
      return 'Supabase не настроен. Проверьте .env файл и переменные окружения';
    }
    return useLocal
        ? 'Supabase: Локальная разработка ($localUrl)'
        : 'Supabase: Production ($productionUrl)';
  }
}
