import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_app/core/utils/navigation/route_data.dart'
    show RouteData;
import 'package:my_app/core/utils/navigation/router_service.dart';
import 'package:my_app/core/utils/navigation/utils.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/utils/locator.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Custom page without transition animation
class NoTransitionPage<T> extends Page<T> {
  final Widget child;

  const NoTransitionPage({
    required this.child,
    required LocalKey key,
  }) : super(key: key);

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // No animation - just return the child directly
        return child;
      },
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

class AppRouterDelegate extends RouterDelegate<RouteData> {
  AppRouterDelegate({required RouterService routerService})
    : _routerService = routerService;

  final RouterService _routerService;

  List<Page<dynamic>> createPages() {
    List<Page<dynamic>> pages = [];
    final authService = locator<AuthService>();

    for (RouteData routeData in _routerService.navigationStack.value) {
      final matchedRoute = _routerService.supportedRoutes.firstWhere(
        (route) => matchRoute(route.path, routeData.uri),
      );

      // Check if route requires authentication
      if (matchedRoute.requiresAuth && !authService.isAuthenticated) {
        // Redirect to login if not authenticated
        // Store intended route for after login
        final loginRoute = _routerService.supportedRoutes.firstWhere(
          (route) => route.path == '/login',
        );
        Widget child = loginRoute.builder(
          ValueKey('/login'),
          RouteData(uri: Uri.parse('/login'), routePattern: '/login'),
        );
        pages.add(
          NoTransitionPage(
            key: const ValueKey('Page_login'),
            child: child,
          ),
        );
        break; // Stop processing further routes
      }

      Widget child = matchedRoute.builder(
        ValueKey(routeData.pathWithParams),
        routeData,
      );

      pages.add(
        NoTransitionPage(
          key: ValueKey('Page_${routeData.pathWithParams}'),
          child: child,
        ),
      );
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: createPages(),
      // ignore: deprecated_member_use
      onPopPage: (route, result) {
        if (route.didPop(result)) {
          _routerService.back();
          return true;
        }
        return false;
      },
    );
  }

  @override
  Future<bool> popRoute() async {
    if (_routerService.navigationStack.value.length > 1) {
      _routerService.back();
      return SynchronousFuture(true);
    }
    return SynchronousFuture(false);
  }

  @override
  RouteData? get currentConfiguration {
    if (_routerService.navigationStack.value.isEmpty) {
      return null;
    }
    return _routerService.navigationStack.value.last;
  }

  @override
  Future<void> setNewRoutePath(RouteData configuration) async {
    if (currentConfiguration == configuration) {
      return SynchronousFuture<void>(null);
    }
    SynchronousFuture(_routerService.replaceAllWithRoute(configuration));
  }

  @override
  void addListener(VoidCallback listener) {
    _routerService.navigationStack.addListener(listener);
    locator<AuthService>().currentUserNotifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _routerService.navigationStack.removeListener(listener);
    locator<AuthService>().currentUserNotifier.removeListener(listener);
  }
}
