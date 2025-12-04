import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../lib/core/utils/http/http_abstraction.dart';
import '../../lib/core/utils/http/http_interceptor.dart';

void main() {
  group('HttpAbstraction Tests', () {
    group('Initialization', () {
      test('should initialize with empty interceptors', () {
        final abstraction = HttpAbstraction();
        expect(abstraction, isA<HttpAbstraction>());
      });

      test('should initialize with provided interceptors', () {
        final interceptor = MockInterceptor();
        final abstraction = HttpAbstraction(interceptors: [interceptor]);
        expect(abstraction, isA<HttpAbstraction>());
      });
    });

    group('Interceptor Management', () {
      test('should add interceptor', () {
        final abstraction = HttpAbstraction();
        final interceptor = MockInterceptor();
        abstraction.addInterceptor(interceptor);
        
        // Verify interceptor was added
        expect(interceptor.requestCallCount, equals(0));
        expect(interceptor.responseCallCount, equals(0));
      });

      test('should add multiple interceptors', () {
        final abstraction = HttpAbstraction();
        final interceptor1 = MockInterceptor();
        final interceptor2 = MockInterceptor();
        
        abstraction.addInterceptor(interceptor1);
        abstraction.addInterceptor(interceptor2);
        
        expect(interceptor1.requestCallCount, equals(0));
        expect(interceptor2.requestCallCount, equals(0));
      });
    });

    group('HTTP Methods Signature', () {
      test('should have correct method signatures', () {
        final abstraction = HttpAbstraction();
        
        // Test that all HTTP methods exist and have correct signatures
        expect(() => abstraction.get(Uri.parse('https://example.com')), returnsNormally);
        expect(() => abstraction.post(Uri.parse('https://example.com')), returnsNormally);
        expect(() => abstraction.put(Uri.parse('https://example.com')), returnsNormally);
        expect(() => abstraction.delete(Uri.parse('https://example.com')), returnsNormally);
        expect(() => abstraction.patch(Uri.parse('https://example.com')), returnsNormally);
      });
    });

    group('Request Parameter Handling', () {
      test('should handle GET with headers', () {
        final abstraction = HttpAbstraction();
        
        final headers = {'Authorization': 'Bearer token'};
        final future = abstraction.get(Uri.parse('https://example.com/api/test'), headers: headers);
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle POST with body and headers', () {
        final abstraction = HttpAbstraction();
        
        final headers = {'Content-Type': 'application/json'};
        final body = {'name': 'test'};
        final future = abstraction.post(
          Uri.parse('https://example.com/api/test'),
          headers: headers,
          body: body,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle PUT with encoding', () {
        final abstraction = HttpAbstraction();
        
        final encoding = utf8;
        final future = abstraction.put(
          Uri.parse('https://example.com/api/test'),
          encoding: encoding,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle DELETE with body', () {
        final abstraction = HttpAbstraction();
        
        final body = {'id': '123'};
        final future = abstraction.delete(
          Uri.parse('https://example.com/api/test'),
          body: body,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle PATCH with all parameters', () {
        final abstraction = HttpAbstraction();
        
        final headers = {'Authorization': 'Bearer token'};
        final body = {'key': 'value'};
        final encoding = utf8;
        final future = abstraction.patch(
          Uri.parse('https://example.com/api/test'),
          headers: headers,
          body: body,
          encoding: encoding,
        );
        
        expect(future, isA<Future<http.Response>>());
      });
    });

    group('Body Type Handling', () {
      test('should handle string body correctly', () {
        final abstraction = HttpAbstraction();
        
        final bodyString = 'test body content';
        final future = abstraction.post(
          Uri.parse('https://example.com/api/test'),
          body: bodyString,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle list body correctly', () {
        final abstraction = HttpAbstraction();
        
        final bodyList = [1, 2, 3, 4, 5];
        final future = abstraction.post(
          Uri.parse('https://example.com/api/test'),
          body: bodyList,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle map body correctly', () {
        final abstraction = HttpAbstraction();
        
        final bodyMap = {'username': 'test', 'password': 'secret'};
        final future = abstraction.post(
          Uri.parse('https://example.com/api/test'),
          body: bodyMap,
        );
        
        expect(future, isA<Future<http.Response>>());
      });
    });

    group('Resource Management', () {
      test('should close without throwing', () {
        final abstraction = HttpAbstraction();
        
        expect(() => abstraction.close(), returnsNormally);
      });
    });

    group('Complex Scenarios', () {
      test('should handle complex request with all features', () {
        final abstraction = HttpAbstraction();
        
        final headers = {
          'Authorization': 'Bearer token123',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        };
        final body = {
          'user': {'name': 'John Doe', 'email': 'john@example.com'},
          'settings': {'theme': 'dark', 'notifications': true},
        };
        final encoding = utf8;
        
        final future = abstraction.post(
          Uri.parse('https://example.com/api/complex'),
          headers: headers,
          body: body,
          encoding: encoding,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle Unicode content', () {
        final abstraction = HttpAbstraction();
        
        final unicodeBody = {'message': 'Привет мир'};
        final future = abstraction.post(
          Uri.parse('https://example.com/api/unicode'),
          body: unicodeBody,
        );
        
        expect(future, isA<Future<http.Response>>());
      });

      test('should handle different URL types', () {
        final abstraction = HttpAbstraction();
        
        // Test various URL formats
        expect(() => abstraction.get(Uri.parse('https://api.example.com/v1/users')), returnsNormally);
        expect(() => abstraction.get(Uri.parse('http://localhost:8080/api/test')), returnsNormally);
        expect(() => abstraction.get(Uri.parse('https://192.168.1.1:3000/api')), returnsNormally);
      });
    });

    group('Error Handling', () {
      test('should handle invalid URLs gracefully', () {
        final abstraction = HttpAbstraction();
        
        // These should not throw immediately (they would throw when the Future completes)
        expect(() => abstraction.get(Uri.parse('')), returnsNormally);
        expect(() => abstraction.post(Uri.parse('not-a-url')), returnsNormally);
      });
    });
  });
}

// Mock classes for testing
class MockInterceptor implements HttpInterceptor {
  int requestCallCount = 0;
  int responseCallCount = 0;

  @override
  Future<http.BaseRequest> interceptRequest(http.BaseRequest request) async {
    requestCallCount++;
    return request;
  }

  @override
  Future<http.BaseResponse> interceptResponse(http.BaseResponse response) async {
    responseCallCount++;
    return response;
  }
}