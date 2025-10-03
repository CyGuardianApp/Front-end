import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/http_service.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Handle API exceptions and return user-friendly messages
  static String handleApiException(ApiException exception) {
    switch (exception.statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'Access denied. You don\'t have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'Conflict detected. The resource may already exist.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable. Please try again later.';
      case 503:
        return 'Service maintenance in progress. Please try again later.';
      default:
        return exception.message.isNotEmpty
            ? exception.message
            : 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle general exceptions and return user-friendly messages
  static String handleException(dynamic exception) {
    if (exception is ApiException) {
      return handleApiException(exception);
    }

    if (exception is FormatException) {
      return 'Invalid data format. Please try again.';
    }

    if (exception is TypeError) {
      return 'Data type error. Please refresh and try again.';
    }

    if (exception is StateError) {
      return 'Application state error. Please restart the app.';
    }

    if (exception is ArgumentError) {
      return 'Invalid input provided. Please check your data.';
    }

    if (exception is RangeError) {
      return 'Value out of range. Please check your input.';
    }

    if (exception is UnsupportedError) {
      return 'This operation is not supported.';
    }

    if (exception is UnimplementedError) {
      return 'This feature is not yet implemented.';
    }

    // Generic error message
    return 'An unexpected error occurred. Please try again.';
  }

  /// Log error for debugging
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('=== ERROR LOG ===');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
      print('=================');
    }
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: onPressed ??
                  () {
                    Navigator.of(context).pop();
                  },
              child: Text(buttonText ?? 'OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  /// Handle network errors specifically
  static String handleNetworkError(dynamic error) {
    if (error is ApiException) {
      return handleApiException(error);
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (errorString.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }

    if (errorString.contains('handshake')) {
      return 'Secure connection failed. Please try again.';
    }

    return 'Network error. Please check your connection and try again.';
  }

  /// Handle authentication errors
  static String handleAuthError(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 401:
          return 'Invalid credentials. Please check your email and password.';
        case 403:
          return 'Account access denied. Please contact support.';
        case 429:
          return 'Too many login attempts. Please wait before trying again.';
        default:
          return handleApiException(error);
      }
    }

    return 'Authentication failed. Please try again.';
  }

  /// Handle validation errors
  static String handleValidationError(dynamic error) {
    if (error is ApiException && error.statusCode == 422) {
      return 'Please check your input and try again.';
    }

    return 'Invalid input provided. Please check your data.';
  }

  /// Get error severity level
  static ErrorSeverity getErrorSeverity(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
        case 422:
          return ErrorSeverity.warning;
        case 401:
        case 403:
          return ErrorSeverity.error;
        case 500:
        case 502:
        case 503:
          return ErrorSeverity.critical;
        default:
          return ErrorSeverity.error;
      }
    }

    return ErrorSeverity.error;
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 500:
        case 502:
        case 503:
        case 429:
          return true;
        default:
          return false;
      }
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection');
  }

  /// Get retry delay based on error
  static Duration getRetryDelay(dynamic error, int attempt) {
    if (error is ApiException && error.statusCode == 429) {
      // Exponential backoff for rate limiting
      return Duration(seconds: (attempt * 2).clamp(1, 60));
    }

    // Standard exponential backoff
    return Duration(seconds: (attempt * attempt).clamp(1, 30));
  }
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Extension for error severity
extension ErrorSeverityExtension on ErrorSeverity {
  Color get color {
    switch (this) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return Colors.orange;
      case ErrorSeverity.error:
        return Colors.red;
      case ErrorSeverity.critical:
        return Colors.red.shade900;
    }
  }

  IconData get icon {
    switch (this) {
      case ErrorSeverity.info:
        return Icons.info;
      case ErrorSeverity.warning:
        return Icons.warning;
      case ErrorSeverity.error:
        return Icons.error;
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }
}
