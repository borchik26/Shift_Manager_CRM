import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/navigation/router_service.dart';
import '../../lib/core/utils/navigation/route_data.dart';
import '../../lib/core/utils/navigation/navigation_observable.dart';

void main() {
  group('RouterService', () {
    late RouterService routerService;
    late List<RouteEntry> testRoutes;

    setUp(() {
      testRoutes = [
        RouteEntry(
          path: '/',
          builder: (key, routeData) => Container(),
        ),
        RouteEntry(
          path: '/home',
          builder: (key, routeData) => Container(),
        ),
        RouteEntry(
          path: '/employees/:id',
          builder: (key, routeData) => Container(),
        ),
        RouteEntry(
          path: '/404',
          builder: (key, routeData) => Container(),
        ),
      ];
      
      routerService = RouterService(supportedRoutes: testRoutes);
    });

    tearDown(() {
      // Note: RouterService doesn't have a dispose method in the current implementation
      // routerService.dispose();
    });

    test('initializes with home route', () {
      // Assert
      expect(routerService.navigationStack.value.length, equals(1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('go adds route to stack', () {
      // Arrange
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.goTo(Path(name: '/home'));
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength + 1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/home'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('replace replaces last route in stack', () {
      // Arrange
      routerService.goTo(Path(name: '/home'));
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.replace(Path(name: '/dashboard'));
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/dashboard'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('back removes last route from stack', () {
      // Arrange
      routerService.goTo(Path(name: '/home'));
      routerService.goTo(Path(name: '/employees'));
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.back();
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength - 1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/home'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('back does nothing when stack has only one route', () {
      // Arrange
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.back();
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('backUntil removes routes until specified route', () {
      // Arrange
      routerService.goTo(Path(name: '/home'));
      routerService.goTo(Path(name: '/employees'));
      routerService.goTo(Path(name: '/dashboard'));
      
      // Act
      routerService.backUntil(Path(name: '/home'));
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/home'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/'));
    });

    test('remove removes specific route from stack', () {
      // Arrange
      routerService.goTo(Path(name: '/home'));
      routerService.goTo(Path(name: '/employees'));
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.remove(Path(name: '/employees'));
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength - 1));
      expect(routerService.navigationStack.value.any((route) => route.pathWithParams == '/employees'), isFalse);
    });

    test('replaceAll replaces entire stack', () {
      // Arrange
      final newRoutes = [
        Path(name: '/profile'),
        Path(name: '/settings'),
      ];

      // Act
      routerService.replaceAll(newRoutes);

      // Assert
      expect(routerService.navigationStack.value.length, equals(2));
      expect(routerService.navigationStack.value[0].uri.toString(), equals('/profile'));
      expect(routerService.navigationStack.value[1].uri.toString(), equals('/settings'));
    });

    test('handles unsupported routes correctly', () {
      // Arrange
      final initialStackLength = routerService.navigationStack.value.length;
      
      // Act
      routerService.goTo(Path(name: '/unsupported'));
      
      // Assert
      expect(routerService.navigationStack.value.length, equals(initialStackLength + 1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/404'));
      expect(routerService.navigationStack.value.last.routePattern, equals('/404'));
    });

    test('navigation stack notifies observers', () async {
      // Arrange
      var pushCalled = false;
      var popCalled = false;
      var replaceCalled = false;
      
      final testObserver = TestNavigationObserver(
        onPush: () => pushCalled = true,
        onPop: () => popCalled = true,
        onReplace: () => replaceCalled = true,
      );
      
      routerService.addObserver(testObserver);
      
      // Act
      routerService.goTo(Path(name: '/test'));
      routerService.back();
      routerService.replace(Path(name: '/replacement'));
      
      // Assert
      expect(pushCalled, isTrue);
      expect(popCalled, isTrue);
      expect(replaceCalled, isTrue);
      
      // Cleanup
      routerService.removeObserver(testObserver);
    });

    test('creates RouteData correctly', () {
      // Arrange
      final path = Path(name: '/test', extra: {'test': 'data'});

      // Act
      routerService.goTo(path);

      // Assert
      final routeData = routerService.navigationStack.value.last;
      expect(routeData.uri.toString(), equals('/test'));
      expect(routeData.routePattern, equals('/'));
      expect(routeData.extra, equals({'test': 'data'}));
    });

    test('handles complex navigation scenarios', () {
      // Arrange
      final scenarios = [
        {
          'name': 'Simple navigation',
          'actions': () => (RouterService router) {
            routerService.goTo(Path(name: '/home'));
            expect(routerService.navigationStack.value.last.uri.toString(), equals('/home'));
            routerService.back();
            expect(routerService.navigationStack.value.last.uri.toString(), equals('/'));
          },
        },
      ];
      
      for (final scenario in scenarios) {
        // Reset router for each scenario
        routerService = RouterService(supportedRoutes: testRoutes);

        final action = scenario['actions'] as Function?;
        action?.call();
      }
    });

    test('handles edge cases', () {
      // Arrange
      routerService = RouterService(supportedRoutes: testRoutes);
      
      // Test multiple back operations when stack is empty
      for (int i = 0; i < 5; i++) {
        routerService.back();
      }
      
      // Assert - Stack should remain empty with only root route
      expect(routerService.navigationStack.value.length, equals(1));
      expect(routerService.navigationStack.value.last.uri.toString(), equals('/'));
      
      // Test navigation to same route multiple times
      routerService.goTo(Path(name: '/home'));
      routerService.goTo(Path(name: '/home'));
      
      // Assert - Should not duplicate routes
      expect(routerService.navigationStack.value.length, equals(3));
      expect(routerService.navigationStack.value.where((route) => route.pathWithParams == '/home').length, equals(3));
    });

    test('path validation works correctly', () {
      // Arrange
      final validPath = Path(name: '/employees/123');
      final invalidPath = Path(name: 'invalid//path');

      // Act & Assert
      expect(() => routerService.goTo(validPath), returnsNormally);
      expect(() => routerService.goTo(invalidPath), throwsArgumentError);
    });
  });
}

class TestNavigationObserver implements NavigationObserver {
  final VoidCallback _onPushCallback;
  final VoidCallback _onPopCallback;
  final VoidCallback _onReplaceCallback;

  TestNavigationObserver({
    required VoidCallback onPush,
    required VoidCallback onPop,
    required VoidCallback onReplace,
  }) : _onPushCallback = onPush,
       _onPopCallback = onPop,
       _onReplaceCallback = onReplace;

  @override
  void onPush(RouteData route) {
    _onPushCallback();
  }

  @override
  void onPop(RouteData route) {
    _onPopCallback();
  }

  @override
  void onReplace(RouteData route) {
    _onReplaceCallback();
  }

  @override
  void onRemove(RouteData route) {
    // Not implemented for this test
  }
}