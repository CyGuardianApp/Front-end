import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errorCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// HTTP service with retry logic, timeouts, and comprehensive error handling
class HttpService {
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);
  static const Duration _retryDelay = Duration(seconds: 1);

  /// Make a GET request with retry logic
  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest(
      'GET',
      endpoint,
      headers: headers,
      accessToken: accessToken,
      queryParams: queryParams,
    );
  }

  /// Make a POST request with retry logic
  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      headers: headers,
      accessToken: accessToken,
      body: body,
      queryParams: queryParams,
    );
  }

  /// Make a PUT request with retry logic
  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      headers: headers,
      accessToken: accessToken,
      body: body,
      queryParams: queryParams,
    );
  }

  /// Make a PATCH request with retry logic
  static Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest(
      'PATCH',
      endpoint,
      headers: headers,
      accessToken: accessToken,
      body: body,
      queryParams: queryParams,
    );
  }

  /// Make a DELETE request with retry logic
  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    Map<String, String>? queryParams,
  }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      headers: headers,
      accessToken: accessToken,
      queryParams: queryParams,
    );
  }

  /// Core request method with retry logic
  static Future<http.Response> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    String? accessToken,
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    // Build URL
    String url = ApiConfig.buildUrl(endpoint);
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      url = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParams,
      }).toString();
    }

    // Prepare headers
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (accessToken != null && accessToken.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $accessToken';
    }

    // Prepare body
    String? requestBody;
    if (body != null) {
      if (body is Map<String, dynamic>) {
        requestBody = jsonEncode(body);
      } else if (body is String) {
        requestBody = body;
      } else {
        requestBody = body.toString();
      }
    }

    // Retry logic
    Exception? lastException;
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (kDebugMode) {
          print('HTTP $method $url (Attempt ${attempt + 1}/$_maxRetries)');
        }

        http.Response response;
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http
                .get(Uri.parse(url), headers: requestHeaders)
                .timeout(_timeout);
            break;
          case 'POST':
            response = await http
                .post(Uri.parse(url),
                    headers: requestHeaders, body: requestBody)
                .timeout(_timeout);
            break;
          case 'PUT':
            response = await http
                .put(Uri.parse(url), headers: requestHeaders, body: requestBody)
                .timeout(_timeout);
            break;
          case 'PATCH':
            response = await http
                .patch(Uri.parse(url),
                    headers: requestHeaders, body: requestBody)
                .timeout(_timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(Uri.parse(url), headers: requestHeaders)
                .timeout(_timeout);
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        // Log response in debug mode
        if (kDebugMode) {
          print(
              'Response: ${response.statusCode} - ${response.body.length} bytes');
        }

        // Check for client errors (4xx) - don't retry these
        if (response.statusCode >= 400 && response.statusCode < 500) {
          throw ApiException(
            _parseErrorMessage(response),
            statusCode: response.statusCode,
          );
        }

        // Check for server errors (5xx) - retry these
        if (response.statusCode >= 500) {
          throw ApiException(
            'Server error: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }

        return response;
      } on SocketException {
        lastException = ApiException('No internet connection');
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      } on HttpException catch (e) {
        lastException = ApiException('HTTP error: ${e.message}');
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      } on FormatException catch (e) {
        lastException = ApiException('Format error: ${e.message}');
        break; // Don't retry format errors
      } catch (e) {
        lastException = ApiException('Unexpected error: $e');
        if (attempt < _maxRetries - 1) {
          await Future.delayed(_retryDelay * (attempt + 1));
        }
      }
    }

    throw lastException ??
        ApiException('Request failed after $_maxRetries attempts');
  }

  /// Parse error message from response
  static String _parseErrorMessage(http.Response response) {
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        return errorData['detail'] ??
            errorData['message'] ??
            errorData['error'] ??
            'Request failed';
      }
    } catch (e) {
      // If JSON parsing fails, return the raw body or a generic message
    }
    return response.body.isNotEmpty ? response.body : 'Request failed';
  }

  /// Check if the API is reachable
  static Future<bool> isApiReachable() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.apiBaseUrl}/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get network status
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    try {
      final isReachable = await isApiReachable();
      return {
        'isReachable': isReachable,
        'baseUrl': ApiConfig.apiBaseUrl,
        'environment': ApiConfig.environment,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'isReachable': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
