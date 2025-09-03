import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  // Use centralized API configuration
  static String get apiBaseUrl => ApiConfig.apiBaseUrl;

  /// Sign in with email and password
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.login)),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Login failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService.signIn error: $e');
      }
      rethrow;
    }
  }

  /// Sign up a new user
  Future<Map<String, dynamic>> signUp(String email, String password, UserRole role, {
    String? name,
    String? departmentName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.users)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name ?? email.split('@')[0],
          'email': email,
          'password': password,
          'role': role.name,
          'department_id': email.split('@').last,
          'department_name': departmentName,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Registration failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService.signUp error: $e');
      }
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    // For now, this is handled client-side by clearing tokens
    // In a real implementation, you might want to call a logout endpoint
    if (kDebugMode) {
      print('User signed out');
    }
  }

  /// Get current user information
  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.me)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to get user info');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService.getCurrentUser error: $e');
      }
      rethrow;
    }
  }

  /// Change user password
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.changePassword)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthService.changePassword error: $e');
      }
      rethrow;
    }
  }

  /// Check if the service is healthy
  Future<bool> isHealthy() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.healthAuth)),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('AuthService health check failed: $e');
      }
      return false;
    }
  }
}
