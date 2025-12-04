import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_app/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:my_app/startup/startup_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Russian locale for date formatting
  await initializeDateFormatting('ru', null);

  configureUrlStrategy();

  runApp(const StartupView());
}
