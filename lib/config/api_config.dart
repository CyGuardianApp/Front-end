import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API configuration for the CyGuardian application
///
/// This file contains all server URLs and can be easily updated
/// when moving between development and production environments.
class ApiConfig {
  // Environment configuration
  static const bool _isProduction =
      false; // Changed to false for local development

  // Development URLs (localhost)
  static const String _devWebUrl = 'http://127.0.0.1:8000';
  static const String _devAndroidUrl = 'http://10.0.2.2:8000';
  static const String _devLocalUrl = 'http://127.0.0.1:8000';

  // Production URLs (replace with your actual production domain)
  static const String _prodWebUrl =
      'https://api.cyguardian.org'; // API subdomain for backend
  static const String _prodAndroidUrl =
      'https://api.cyguardian.org'; // API subdomain for backend
  static const String _prodLocalUrl =
      'https://api.cyguardian.org'; // API subdomain for backend

  /// Get the base API URL based on platform and environment
  static String get apiBaseUrl {
    if (_isProduction) {
      return _getProductionUrl();
    } else {
      return _getDevelopmentUrl();
    }
  }

  /// Get development URL based on platform
  static String _getDevelopmentUrl() {
    if (kIsWeb) return _devWebUrl;
    if (Platform.isAndroid) return _devAndroidUrl;
    return _devLocalUrl;
  }

  /// Get production URL based on platform
  static String _getProductionUrl() {
    if (kIsWeb) return _prodWebUrl;
    if (Platform.isAndroid) return _prodAndroidUrl;
    return _prodLocalUrl;
  }

  /// Get the current environment name
  static String get environment => _isProduction ? 'production' : 'development';

  /// Check if running in production mode
  static bool get isProduction => _isProduction;

  /// Check if running in development mode
  static bool get isDevelopment => !_isProduction;

  /// API Endpoints (all relative to base URL)
  // Authentication
  static const String login = '/login';
  static const String me = '/me';
  static const String changePassword = '/change-password';

  // User Management
  static const String users = '/users/';
  static const String userById = '/users/{id}';

  // OTP Service
  static const String generateOtp = '/otp/generate-otp';
  static const String verifyOtp = '/otp/verify-otp';
  static const String clearOtp = '/otp/clear-otp/{email}';

  // Questionnaire Service
  static const String questionnaires = '/questionnaires/';
  static const String questionnaireById = '/questionnaires/{id}';
  static const String questionnaireResponses = '/questionnaire_responses/';

  // Company History Service
  static const String companyHistory = '/company-history/';
  static const String companyHistoryById = '/company-history/{id}';

  // Risk Assessment Service
  static const String riskAssessments = '/risk-assessments/';
  static const String riskAssessmentById = '/risk-assessments/{id}';

  // Health Checks
  static const String healthAuth = '/health/auth';
  static const String healthQuestionnaire = '/health/questionnaire';
  static const String healthUsers = '/health/users';
  static const String healthRisk = '/health/risk';
  static const String healthCompany = '/health/company';
  static const String healthEmail = '/health/email';
  static const String healthOtp = '/health/otp';

  /// Helper method to build full URLs
  static String buildUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  /// Helper method to build URLs with path parameters
  static String buildUrlWithParams(
      String endpoint, Map<String, String> params) {
    String url = endpoint;
    params.forEach((key, value) {
      url = url.replaceAll('{$key}', value);
    });
    return '$apiBaseUrl$url';
  }

  /// Print current configuration for debugging
  static void printConfig() {
    print('=== API Configuration ===');
    print('Environment: $environment');
    print('Base URL: $apiBaseUrl');
    print('Is Production: $isProduction');
    print('Is Development: $isDevelopment');
    print(
        'Platform: ${kIsWeb ? 'Web' : Platform.isAndroid ? 'Android' : 'Other'}');
    print('========================');
  }
}

/// Legacy compatibility - keeping the old AuthService.apiBaseUrl for backward compatibility
/// This can be removed once all code is updated to use ApiConfig
class AuthService {
  static String get apiBaseUrl => ApiConfig.apiBaseUrl;
}
