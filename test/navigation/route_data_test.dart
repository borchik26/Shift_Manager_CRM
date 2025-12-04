import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/utils/navigation/route_data.dart';

void main() {
  group('RouteData Tests', () {
    group('Path Parameters Extraction', () {
      test('should extract single path parameter', () {
        final routeData = RouteData(
          uri: Uri.parse('/employees/123'),
          routePattern: '/employees/:id',
        );

        final params = routeData.pathParameters;
        expect(params['id'], equals('123'));
        expect(params.length, equals(1));
      });

      test('should extract multiple path parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/users/123/posts/456'),
          routePattern: '/users/:userId/posts/:postId',
        );

        final params = routeData.pathParameters;
        expect(params['userId'], equals('123'));
        expect(params['postId'], equals('456'));
        expect(params.length, equals(2));
      });

      test('should handle empty path parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/users//posts'),
          routePattern: '/users/:userId/posts',
        );

        final params = routeData.pathParameters;
        expect(params.isEmpty, isTrue);
      });

      test('should handle routes with no parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/home'),
          routePattern: '/home',
        );

        final params = routeData.pathParameters;
        expect(params.isEmpty, isTrue);
      });

      test('should handle different segment counts', () {
        final routeData = RouteData(
          uri: Uri.parse('/users/123/posts'),
          routePattern: '/users/:userId/posts/:postId',
        );

        final params = routeData.pathParameters;
        expect(params.isEmpty, isTrue); // Different segment counts should return empty
      });

      test('should handle special characters in parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/search/John%20Doe'),
          routePattern: '/search/:query',
        );

        final params = routeData.pathParameters;
        expect(params['query'], equals('John%20Doe'));
      });
    });

    group('Query Parameters', () {
      test('should extract single query parameter', () {
        final routeData = RouteData(
          uri: Uri.parse('/search?q=test'),
          routePattern: '/search',
        );

        final params = routeData.queryParameters;
        expect(params['q'], equals('test'));
        expect(params.length, equals(1));
      });

      test('should extract multiple query parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/search?q=test&page=1&sort=name'),
          routePattern: '/search',
        );

        final params = routeData.queryParameters;
        expect(params['q'], equals('test'));
        expect(params['page'], equals('1'));
        expect(params['sort'], equals('name'));
        expect(params.length, equals(3));
      });

      test('should handle empty query parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/search'),
          routePattern: '/search',
        );

        final params = routeData.queryParameters;
        expect(params.isEmpty, isTrue);
      });

      test('should handle encoded query parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/search?q=Hello%20World'),
          routePattern: '/search',
        );

        final params = routeData.queryParameters;
        expect(params['q'], equals('Hello World'));
      });

      test('should handle duplicate query parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/search?q=first&q=second'),
          routePattern: '/search',
        );

        final params = routeData.queryParameters;
        expect(params['q'], equals('second')); // Last value wins
        expect(params.length, equals(1));
      });
    });

    group('Path with Params', () {
      test('should combine path and query parameters', () {
        final routeData = RouteData(
          uri: Uri.parse('/users/123?tab=profile&edit=true'),
          routePattern: '/users/:id',
        );

        expect(routeData.pathParameters['id'], equals('123'));
        expect(routeData.queryParameters['tab'], equals('profile'));
        expect(routeData.queryParameters['edit'], equals('true'));
      });

      test('should handle complex URLs', () {
        final routeData = RouteData(
          uri: Uri.parse('/api/v1/users/123/posts/456?include=comments&sort=desc#section1'),
          routePattern: '/api/v1/users/:userId/posts/:postId',
        );

        expect(routeData.pathParameters['userId'], equals('123'));
        expect(routeData.pathParameters['postId'], equals('456'));
        expect(routeData.queryParameters['include'], equals('comments'));
        expect(routeData.queryParameters['sort'], equals('desc'));
      });
    });

    group('Equality and HashCode', () {
      test('should consider routes equal with same properties', () {
        final route1 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: {'test': 'data'},
        );

        final route2 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: {'test': 'data'},
        );

        expect(route1, equals(route2));
        expect(route1.hashCode, equals(route2.hashCode));
      });

      test('should consider routes different with different URIs', () {
        final route1 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
        );

        final route2 = RouteData(
          uri: Uri.parse('/users/456'),
          routePattern: '/users/:id',
        );

        expect(route1, isNot(equals(route2)));
      });

      test('should consider routes different with different patterns', () {
        final route1 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
        );

        final route2 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/profile',
        );

        expect(route1, isNot(equals(route2)));
      });

      test('should consider routes different with different extra data', () {
        final route1 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: {'test': 'data1'},
        );

        final route2 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: {'test': 'data2'},
        );

        expect(route1, isNot(equals(route2)));
      });

      test('should handle null extra data correctly', () {
        final route1 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: null,
        );

        final route2 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: null,
        );

        final route3 = RouteData(
          uri: Uri.parse('/users/123'),
          routePattern: '/users/:id',
          extra: {'test': 'data'},
        );

        expect(route1, equals(route2));
        expect(route1, isNot(equals(route3)));
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final routeData = RouteData(
          uri: Uri.parse('/users/123?tab=profile'),
          routePattern: '/users/:id',
          extra: {'source': 'navigation'},
        );

        final stringRepresentation = routeData.toString();
        expect(stringRepresentation, contains('/users/123'));
        expect(stringRepresentation, contains('/users/:id'));
        expect(stringRepresentation, contains('tab=profile'));
        expect(stringRepresentation, contains('source: navigation'));
      });

      test('should handle empty parameters in string representation', () {
        final routeData = RouteData(
          uri: Uri.parse('/home'),
          routePattern: '/home',
        );

        final stringRepresentation = routeData.toString();
        expect(stringRepresentation, contains('/home'));
        expect(stringRepresentation, contains('queryParameters: {}'));
        expect(stringRepresentation, contains('pathParameters: {}'));
      });
    });

    group('Edge Cases', () {
      test('should handle Unicode characters', () {
        final routeData = RouteData(
          uri: Uri.parse('/пользователи/123?имя=Иван'),
          routePattern: '/пользователи/:id',
        );

        expect(routeData.pathParameters['id'], equals('123'));
        expect(routeData.queryParameters['имя'], equals('Иван'));
      });

      test('should handle empty URI', () {
        final routeData = RouteData(
          uri: Uri.parse(''),
          routePattern: '/',
        );

        expect(routeData.pathWithParams, equals(''));
        expect(routeData.pathParameters.isEmpty, isTrue);
        expect(routeData.queryParameters.isEmpty, isTrue);
      });

      test('should handle root path', () {
        final routeData = RouteData(
          uri: Uri.parse('/'),
          routePattern: '/',
        );

        expect(routeData.pathWithParams, equals('/'));
        expect(routeData.pathParameters.isEmpty, isTrue);
        expect(routeData.queryParameters.isEmpty, isTrue);
      });

      test('should handle complex extra data', () {
        final complexExtra = {
          'user': {'id': 123, 'name': 'John'},
          'settings': ['theme', 'notifications'],
          'timestamp': DateTime.now(),
        };

        final routeData = RouteData(
          uri: Uri.parse('/profile'),
          routePattern: '/profile',
          extra: complexExtra,
        );

        expect(routeData.extra, equals(complexExtra));
      });
    });

    group('Performance Considerations', () {
      test('should handle large parameter sets efficiently', () {
        // Create a route with many parameters
        final uriString = '/a/' + List.generate(100, (i) => 'value$i').join('/');
        final patternString = '/a/' + List.generate(100, (i) => ':param$i').join('/');

        final routeData = RouteData(
          uri: Uri.parse(uriString),
          routePattern: patternString,
        );

        final stopwatch = Stopwatch()..start();
        final params = routeData.pathParameters;
        stopwatch.stop();

        expect(params.length, equals(100));
        expect(params['param0'], equals('value0'));
        expect(params['param99'], equals('value99'));
        expect(stopwatch.elapsedMicroseconds, lessThan(10000)); // Should be very fast
      });

      test('should handle repeated access efficiently', () {
        final routeData = RouteData(
          uri: Uri.parse('/users/123/posts/456?tab=profile&sort=name'),
          routePattern: '/users/:userId/posts/:postId',
        );

        final stopwatch = Stopwatch()..start();
        
        // Access properties multiple times
        for (int i = 0; i < 1000; i++) {
          routeData.pathParameters;
          routeData.queryParameters;
          routeData.pathWithParams;
        }
        
        stopwatch.stop();

        expect(stopwatch.elapsedMicroseconds, lessThan(50000)); // Should be fast even with repeated access
      });
    });
  });
}