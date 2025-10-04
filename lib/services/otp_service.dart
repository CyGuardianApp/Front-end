import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'token_service.dart';

class OTPService {
  static String get baseUrl => ApiConfig.apiBaseUrl;

  /// Send OTP to the specified email
  Future<Map<String, dynamic>> sendOTP(String email, {String? userName}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.generateOtp)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'user_name': userName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending OTP: $e');
      }
      rethrow;
    }
  }

  /// Verify OTP for the specified email
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.verifyOtp)),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        // If OTP verification returns a token, save it
        if (result['access_token'] != null) {
          final expiryTime = DateTime.now().add(const Duration(hours: 24));
          await TokenService.saveTokens(
            accessToken: result['access_token'],
            refreshToken: result['refresh_token'],
            expiry: expiryTime,
          );
          
          if (kDebugMode) {
            print('JWT token saved after OTP verification');
          }
        }
        
        return result;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying OTP: $e');
      }
      rethrow;
    }
  }

  /// Clear OTP for the specified email (useful for testing)
  Future<Map<String, dynamic>> clearOTP(String email) async {
    try {
      final response = await http.delete(
        Uri.parse(
            ApiConfig.buildUrlWithParams(ApiConfig.clearOtp, {'email': email})),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to clear OTP');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing OTP: $e');
      }
      rethrow;
    }
  }

  /// Check if OTP service is healthy
  Future<bool> isHealthy() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.healthOtp)),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('OTP service health check failed: $e');
      }
      return false;
    }
  }

  /// Get OTP service status with detailed information
  Future<Map<String, dynamic>> getServiceStatus() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.healthOtp)),
      );

      if (response.statusCode == 200) {
        return {
          'status': 'healthy',
          'service': 'otp-service',
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'unhealthy',
          'error': 'HTTP ${response.statusCode}',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
