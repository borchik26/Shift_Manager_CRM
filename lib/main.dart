import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/core/config/supabase_config.dart';
import 'package:my_app/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:my_app/startup/startup_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 APP STARTING...');

  try {
    // Load environment variables from .env file
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Environment variables loaded');

    // Initialize Supabase
    await _initializeSupabase();
    debugPrint('✅ Supabase initialized');

    // Initialize Russian locale for date formatting
    await initializeDateFormatting('ru', null);
    debugPrint('✅ Date formatting initialized');

    configureUrlStrategy();
    runApp(const StartupView());
  } catch (e, stack) {
    debugPrint('🛑 CRITICAL ERROR IN MAIN: $e\n$stack');
  }
}

/// Initialize Supabase client
/// For local development: Requires `supabase start` to be running
/// For production: Configure SupabaseConfig with your project credentials
Future<void> _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      debug: SupabaseConfig.useLocal, // Enable debug logs in local mode
    );

    debugPrint('✅ ${SupabaseConfig.statusMessage}');
  } catch (e) {
    debugPrint('❌ Supabase initialization failed: $e');
    // In development, we can continue with mock data
    // In production, you might want to show an error screen
  }
}
