import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/navigation/utils.dart';
import '../../lib/core/utils/navigation/route_data.dart';

void main() {
  group('Navigation Utils Tests', () {
    group('matchRoute', () {
      test('should match exact routes', () {
        expect(matchRoute('/', Uri.parse('/')), isTrue);
        expect(matchRoute('/home', Uri.parse('/home')), isTrue);
        expect(matchRoute('/employees/123', Uri.parse('/employees/123')), isTrue);
      });

      test('should match routes with path parameters', () {
        expect(matchRoute('/employees/:id', Uri.parse('/employees/123')), isTrue);
        expect(matchRoute('/employees/:id', Uri.parse('/employees/abc')), isTrue);
        expect(matchRoute('/users/:userId/posts/:postId', Uri.parse('/users/123/posts/456')), isTrue);
      });

      test('should not match routes with different path lengths', () {
        expect(matchRoute('/employees/:id', Uri.parse('/employees/123/details')), isFalse);
        expect(matchRoute('/users/:userId', Uri.parse('/users')), isFalse);
      });

      test('should not match routes with different static segments', () {
        expect(matchRoute('/home', Uri.parse('/dashboard')), isFalse);
        expect(matchRoute('/employees/:id', Uri.parse('/users/123')), isFalse);
      });

      test('should handle empty segments correctly', () {
        expect(matchRoute('/test', Uri.parse('/test/')), isTrue);
        expect(matchRoute('/test', Uri.parse('//test')), isTrue);
      });
    });

    group('findMatchingRoutePattern', () {
      late List<RouteEntry> routes;

      setUp(() {
        routes = [
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
      });

      test('should find exact match for static routes', () {
        final pattern = findMatchingRoutePattern(Uri.parse('/home'), routes);
        expect(pattern, equals('/home'));
      });

      test('should find pattern match for parameterized routes', () {
        final pattern = findMatchingRoutePattern(Uri.parse('/employees/123'), routes);
        expect(pattern, equals('/employees/:id'));
      });

      test('should return 404 pattern for unsupported routes', () {
        final pattern = findMatchingRoutePattern(Uri.parse('/unsupported'), routes);
        expect(pattern, equals('/404'));
      });

      test('should handle complex routes correctly', () {
        final complexRoutes = [
          RouteEntry(
            path: '/users/:userId',
            builder: (key, routeData) => Container(),
          ),
          RouteEntry(
            path: '/users/:userId/posts/:postId',
            builder: (key, routeData) => Container(),
          ),
          RouteEntry(
            path: '/404',
            builder: (key, routeData) => Container(),
          ),
        ];

        final pattern1 = findMatchingRoutePattern(Uri.parse('/users/123'), complexRoutes);
        expect(pattern1, equals('/users/:userId'));

        final pattern2 = findMatchingRoutePattern(Uri.parse('/users/123/posts/456'), complexRoutes);
        expect(pattern2, equals('/users/:userId/posts/:postId'));

        final pattern3 = findMatchingRoutePattern(Uri.parse('/unknown'), complexRoutes);
        expect(pattern3, equals('/404'));
      });
    });

    group('getSegments', () {
      test('should split simple paths into segments', () {
        expect(getSegments('/home'), equals(['home']));
        expect(getSegments('/users/123'), equals(['users', '123']));
        expect(getSegments('/users/123/posts/456'), equals(['users', '123', 'posts', '456']));
      });

      test('should filter out empty segments', () {
        expect(getSegments('/'), equals([]));
        expect(getSegments('//'), equals([]));
        expect(getSegments('/users//123'), equals(['users', '123']));
        expect(getSegments('/users/123//posts'), equals(['users', '123', 'posts']));
        expect(getSegments('//users//123//posts//'), equals(['users', '123', 'posts']));
      });

      test('should handle leading and trailing slashes', () {
        expect(getSegments('/home'), equals(['home']));
        expect(getSegments('home/'), equals(['home']));
        expect(getSegments('/home/'), equals(['home']));
        expect(getSegments('home'), equals(['home']));
      });

      test('should handle empty path', () {
        expect(getSegments(''), equals([]));
        expect(getSegments('/'), equals([]));
        expect(getSegments('//'), equals([]));
      });

      test('should handle complex paths with special characters', () {
        expect(getSegments('/api/v1/users/123/profile'), equals(['api', 'v1', 'users', '123', 'profile']));
        expect(getSegments('/search?q=test&sort=name'), equals(['search?q=test&sort=name']));
      });
    });

    group('Edge Cases', () {
      test('should handle routes with query parameters', () {
        expect(matchRoute('/search', Uri.parse('/search?q=test&page=1')), isTrue);
        expect(matchRoute('/users/:id', Uri.parse('/users/123?tab=profile')), isTrue);
        
        final pattern = findMatchingRoutePattern(Uri.parse('/search?q=test'), [
          RouteEntry(path: '/search', builder: (key, routeData) => Container()),
          RouteEntry(path: '/404', builder: (key, routeData) => Container()),
        ]);
        expect(pattern, equals('/search'));
      });

      test('should handle routes with fragments', () {
        expect(matchRoute('/profile', Uri.parse('/profile#section')), isTrue);
        expect(matchRoute('/users/:id', Uri.parse('/users/123#details')), isTrue);
      });

      test('should handle Unicode characters in paths', () {
        expect(matchRoute('/пользователи', Uri.parse('/пользователи')), isTrue);
        expect(matchRoute('/пользователи/:id', Uri.parse('/пользователи/123')), isTrue);
        
        final segments = getSegments('/пользователи/123/профиль');
        expect(segments, equals(['пользователи', '123', 'профиль']));
      });

      test('should handle very long paths', () {
        final longPath = '/a' * 100; // Create a very long path
        final segments = getSegments(longPath);
        expect(segments.length, equals(1));
        expect(segments.first, equals('a' * 100));
      });

      test('should handle paths with encoded characters', () {
        final encodedPath = '/users/John%20Doe';
        expect(matchRoute('/users/:name', Uri.parse(encodedPath)), isTrue);
        
        final segments = getSegments(encodedPath);
        expect(segments, equals(['users', 'John%20Doe']));
      });
    });

    group('Performance Considerations', () {
      test('should handle large number of routes efficiently', () {
        // Create a large number of routes
        final largeRouteList = <RouteEntry>[];
        for (int i = 0; i < 1000; i++) {
          largeRouteList.add(RouteEntry(
            path: '/route$i',
            builder: (key, routeData) => Container(),
          ));
        }
        largeRouteList.add(RouteEntry(
          path: '/404',
          builder: (key, routeData) => Container(),
        ));

        final stopwatch = Stopwatch()..start();
        
        // Test finding a route at the end
        final pattern = findMatchingRoutePattern(Uri.parse('/route999'), largeRouteList);
        
        stopwatch.stop();
        
        expect(pattern, equals('/route999'));
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('should handle complex parameter matching efficiently', () {
        expect(matchRoute('/a/b/c', Uri.parse('/a/b/c')), isTrue);
        expect(matchRoute('/a/test/c', Uri.parse('/a/test/c')), isTrue);
        expect(matchRoute('/a/b/test', Uri.parse('/a/b/test')), isTrue);
        expect(matchRoute('/x/y/z', Uri.parse('/x/y/z')), isTrue);
        
        // Should not match incorrect parameter counts
        expect(matchRoute('/a/b', Uri.parse('/a/b')), isFalse);
        expect(matchRoute('/a/b/c/d', Uri.parse('/a/b/c/d')), isFalse);
      });
    });
  });
}