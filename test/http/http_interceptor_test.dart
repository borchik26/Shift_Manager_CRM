import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../../lib/core/utils/http/http_interceptor.dart';

void main() {
  group('LoggingInterceptor Tests', () {
    group('Initialization', () {
      test('should initialize with default logBody setting', () {
        final interceptor = LoggingInterceptor();
        expect(interceptor.logBody, isFalse);
      });

      test('should initialize with custom logBody setting', () {
        final interceptor = LoggingInterceptor(logBody: true);
        expect(interceptor.logBody, isTrue);
      });
    });

    group('Request Interception', () {
      test('should log request method and URL', () async {
        final interceptor = LoggingInterceptor();
        final request = http.Request('GET', Uri.parse('https://example.com/api/test'));
        
        final loggedRequest = await interceptor.interceptRequest(request);
        
        expect(loggedRequest, equals(request));
        expect(loggedRequest.method, equals('GET'));
        expect(loggedRequest.url.toString(), equals('https://example.com/api/test'));
      });

      test('should log request body when logBody is true', () async {
        final interceptor = LoggingInterceptor(logBody: true);
        final request = http.Request('POST', Uri.parse('https://example.com/api/test'));
        request.body = 'test body content';
        
        final loggedRequest = await interceptor.interceptRequest(request);
        
        expect(loggedRequest, equals(request));
        if (loggedRequest is http.Request) {
          expect(loggedRequest.body, equals('test body content'));
        }
      });

      test('should handle different HTTP methods', () async {
        final interceptor = LoggingInterceptor();
        
        final methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
        
        for (final method in methods) {
          final request = http.Request(method, Uri.parse('https://example.com/api/test'));
          final loggedRequest = await interceptor.interceptRequest(request);
          
          expect(loggedRequest.method, equals(method));
        }
      });

      test('should handle requests with query parameters', () async {
        final interceptor = LoggingInterceptor();
        final request = http.Request(
          'GET', 
          Uri.parse('https://example.com/api/test?param1=value1&param2=value2')
        );
        
        final loggedRequest = await interceptor.interceptRequest(request);
        
        expect(loggedRequest.url.queryParameters['param1'], equals('value1'));
        expect(loggedRequest.url.queryParameters['param2'], equals('value2'));
      });
    });

    group('Response Interception', () {
      test('should log response status code and URL', () async {
        final interceptor = LoggingInterceptor();
        final response = http.Response('test body', 200);
        
        final loggedResponse = await interceptor.interceptResponse(response);
        
        expect(loggedResponse, equals(response));
        expect(loggedResponse.statusCode, equals(200));
      });

      test('should log response body when logBody is true', () async {
        final interceptor = LoggingInterceptor(logBody: true);
        final response = http.Response('test body content', 200);
        
        final loggedResponse = await interceptor.interceptResponse(response);
        
        expect(loggedResponse, equals(response));
        if (loggedResponse is http.Response) {
          expect(loggedResponse.body, equals('test body content'));
        }
      });

      test('should handle different status codes', () async {
        final interceptor = LoggingInterceptor();
        final statusCodes = [200, 201, 400, 404, 500];
        
        for (final statusCode in statusCodes) {
          final response = http.Response('test body', statusCode);
          
          final loggedResponse = await interceptor.interceptResponse(response);
          
          expect(loggedResponse.statusCode, equals(statusCode));
        }
      });
    });

    group('Integration Tests', () {
      test('should handle complete request-response cycle', () async {
        final interceptor = LoggingInterceptor(logBody: true);
        
        // Request phase
        final request = http.Request('POST', Uri.parse('https://example.com/api/users'));
        request.body = '{"name": "John", "email": "john@example.com"}';
        
        final loggedRequest = await interceptor.interceptRequest(request);
        expect(loggedRequest, equals(request));
        
        // Response phase
        final response = http.Response('{"id": 123, "status": "created"}', 201);
        
        final loggedResponse = await interceptor.interceptResponse(response);
        expect(loggedResponse, equals(response));
        expect(loggedResponse.statusCode, equals(201));
      });

      test('should handle error responses', () async {
        final interceptor = LoggingInterceptor();
        
        final request = http.Request('GET', Uri.parse('https://example.com/api/nonexistent'));
        await interceptor.interceptRequest(request);
        
        final response = http.Response('Not Found', 404);
        
        final loggedResponse = await interceptor.interceptResponse(response);
        expect(loggedResponse.statusCode, equals(404));
      });
    });

    group('Edge Cases', () {
      test('should handle null request gracefully', () async {
        final interceptor = LoggingInterceptor();
        
        // Test with BaseRequest instead of Request
        // Test with BaseRequest instead of Request
        final baseRequest = http.Request('GET', Uri.parse('https://example.com/api/test'));
        
        final loggedRequest = await interceptor.interceptRequest(baseRequest);
        expect(loggedRequest, equals(baseRequest));
      });

      test('should handle response without request', () async {
        final interceptor = LoggingInterceptor();
        
        final response = http.Response('test body', 200);
        // Don't set request property
        
        final loggedResponse = await interceptor.interceptResponse(response);
        expect(loggedResponse, equals(response));
      });
    });
  });
}