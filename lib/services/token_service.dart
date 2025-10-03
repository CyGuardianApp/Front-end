import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_service.dart';

/// Service for managing authentication tokens and refresh logic
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userDataKey = 'user_data';

  /// Save tokens to local storage
  static Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);

      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }

      if (expiry != null) {
        await prefs.setString(_tokenExpiryKey, expiry.toIso8601String());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving tokens: $e');
      }
    }
  }

  /// Get access token from local storage
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting access token: $e');
      }
      return null;
    }
  }

  /// Get refresh token from local storage
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting refresh token: $e');
      }
      return null;
    }
  }

  /// Check if token is expired or will expire soon
  static Future<bool> isTokenExpired(
      {Duration buffer = const Duration(minutes: 5)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryString = prefs.getString(_tokenExpiryKey);

      if (expiryString == null) {
        return true; // No expiry info, assume expired
      }

      final expiry = DateTime.parse(expiryString);
      final now = DateTime.now();

      return now.isAfter(expiry.subtract(buffer));
    } catch (e) {
      if (kDebugMode) {
        print('Error checking token expiry: $e');
      }
      return true; // Assume expired on error
    }
  }

  /// Refresh access token using refresh token
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        // Don't print debug message - this is normal for OTP auth
        return null;
      }

      final response = await HttpService.post(
        '/auth/refresh',
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'] as int?;

        if (newAccessToken != null) {
          // Calculate expiry time
          DateTime? expiry;
          if (expiresIn != null) {
            expiry = DateTime.now().add(Duration(seconds: expiresIn));
          }

          // Save new tokens
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
            expiry: expiry,
          );

          if (kDebugMode) {
            print('Token refreshed successfully');
          }
          return newAccessToken;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error refreshing token: $e');
      }
    }
    return null;
  }

  /// Get valid access token (refresh if needed)
  static Future<String?> getValidAccessToken() async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        return null;
      }

      // Check if token is expired
      final isExpired = await isTokenExpired();
      if (!isExpired) {
        return accessToken;
      }

      // Try to refresh the token
      final newToken = await refreshAccessToken();
      return newToken;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting valid access token: $e');
      }
      return null;
    }
  }

  /// Clear all tokens from local storage
  static Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_tokenExpiryKey);
      await prefs.remove(_userDataKey);

      if (kDebugMode) {
        print('Tokens cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing tokens: $e');
      }
    }
  }

  /// Save user data to local storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(userData));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
    }
  }

  /// Get user data from local storage
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        return jsonDecode(userDataString) as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
    }
    return null;
  }

  /// Check if user is logged in (has valid token)
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getValidAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get token info for debugging
  static Future<Map<String, dynamic>> getTokenInfo() async {
    try {
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();
      final isExpired = await isTokenExpired();
      final userData = await getUserData();

      return {
        'hasAccessToken': accessToken != null,
        'hasRefreshToken': refreshToken != null,
        'isExpired': isExpired,
        'userData': userData,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
