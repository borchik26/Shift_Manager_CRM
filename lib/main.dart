import 'package:flutter/material.dart';
import 'package:my_app/core/utils/navigation/url_strategy/url_strategy.dart';
import 'package:my_app/startup/startup_view.dart';
import 'package:syncfusion_flutter_core/core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register Syncfusion license (7-Day Trial License)
  SyncfusionLicense.registerLicense(
    'Ngo9BigBOggjHTQxAR8/V1JFaF1cXGFCf1FpQHxbf1x1ZFxMYF9bQXBPMyBoS35Rc0RiW3deeXRWQ2ZUWEV2VEFc'
  );
  
  configureUrlStrategy();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // In production, send to crash reporting service
  };

  runApp(const StartupView());
}
