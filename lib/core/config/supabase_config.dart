/// Supabase configuration constants
/// For local development, these values come from `supabase start` output
/// For production, replace with your Supabase project credentials
class SupabaseConfig {
  SupabaseConfig._();

  // === LOCAL DEVELOPMENT ===
  // These are default values from `supabase start`
  // Run `supabase status` to see your local instance details
  static const String localUrl = 'http://127.0.0.1:54321';
  static const String localAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  // === PRODUCTION ===
  // Project: shift_manager (vzohmhsclrmhleyndtlz)
  // Region: West EU (Ireland)
  static const String productionUrl =
      'https://vzohmhsclrmhleyndtlz.supabase.co';
  static const String productionAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6b2htaHNjbHJtaGxleW5kdGx6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMDUzMjcsImV4cCI6MjA4MDc4MTMyN30.sLeu7_Gp6qutxtZxnoW1ZiUXFabQn6btz13Qf4gh0sM';

  // === ACTIVE CONFIGURATION ===
  // Switch between local and production
  // ✅ LOCAL DEVELOPMENT MODE ENABLED
  static const bool useLocal = false;

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
      return 'Supabase не настроен. Проверьте конфигурацию в supabase_config.dart';
    }
    return useLocal
        ? 'Supabase: Локальная разработка ($localUrl)'
        : 'Supabase: Production ($productionUrl)';
  }
}
