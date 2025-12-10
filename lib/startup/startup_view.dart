import 'package:flutter/material.dart';
import 'package:my_app/core/ui/app_theme.dart';
import 'package:my_app/core/utils/internal_notification/internal_notification_listener.dart';
import 'package:my_app/core/utils/locator.dart';
import 'package:my_app/core/utils/navigation/best_router.dart';
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/startup/startup_view_model.dart';

class StartupView extends StatefulWidget {
  const StartupView({super.key});

  @override
  State<StartupView> createState() => _StartupViewState();
}

class _StartupViewState extends State<StartupView> {
  late final StartupViewModel _viewModel = StartupViewModel();
  BestRouterConfig? _routerConfig;

  @override
  void initState() {
    super.initState();
    _viewModel.appStateNotifier.addListener(_onStateChanged);
    _bootstrap();
  }

  void _onStateChanged() {
    final state = _viewModel.appStateNotifier.value;
    if (state is AppInitialized && _routerConfig == null) {
      setState(() {
        _routerConfig = BestRouterConfig(
          routerService: locator<RouterService>(),
        );
      });
    }
  }

  Future<void> _bootstrap() async {
    await _viewModel.initializeApp();
  }

  @override
  void dispose() {
    _viewModel.appStateNotifier.removeListener(_onStateChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppState>(
      valueListenable: _viewModel.appStateNotifier,
      builder: (context, state, _) {
        if (_routerConfig == null) {
          return MaterialApp(
            home: switch (state) {
              InitializingApp() => _SplashView(),
              AppInitializationError() => _StartupErrorView(
                  onRetry: () => _bootstrap(),
                ),
              _ => _SplashView(),
            },
            debugShowCheckedModeBanner: false,
          );
        }

        return MaterialApp.router(
          routerConfig: _routerConfig!,
          title: 'Shift Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildTheme(Brightness.light),
          darkTheme: AppTheme.buildTheme(Brightness.dark),
          builder: (context, child) {
            return switch (state) {
              InitializingApp() => _SplashView(),
              AppInitialized() => InternalNotificationListener(child: child!),
              AppInitializationError() => _StartupErrorView(
                  onRetry: () => _bootstrap(),
                ),
            };
          },
        );
      },
    );
  }
}

class _StartupErrorView extends StatelessWidget {
  const _StartupErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: context.theme.colorScheme.error,
                size: 48,
              ),
              SizedBox(height: context.spacing.md),
              Text(
                'Error',
                style: context.textStyles.xxl,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.sm),
              Text(
                'Failed to start the application',
                style: context.textStyles.standard,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.spacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
