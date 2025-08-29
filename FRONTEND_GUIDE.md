# CyGuardian Frontend Guide

## Overview

This is the **complete guide** for the CyGuardian Flutter frontend application. It covers everything you need to know about development, configuration, deployment, and troubleshooting.

## Quick Start

### Development Setup
1. **No changes needed** - app is configured for development by default
2. **Run the app**: `flutter run`
3. **All API calls** go to `http://127.0.0.1:8000` (localhost)

### Production Deployment
1. **Open**: `lib/config/api_config.dart`
2. **Change**: `_isProduction = true`
3. **Update**: Replace `cyguardian.com` with your actual domain
4. **Build**: `flutter build apk --release`

## API Configuration System

### Centralized Configuration
All server URLs are managed in one file: `lib/config/api_config.dart`

```dart
// Environment toggle
static const bool _isProduction = false; // Change to true for production

// Development URLs
static const String _devWebUrl = 'http://127.0.0.1:8000';
static const String _devAndroidUrl = 'http://10.0.2.2:8000';
static const String _devLocalUrl = 'http://127.0.0.1:8000';

// Production URLs
static const String _prodWebUrl = 'https://cyguardian.com';
static const String _prodAndroidUrl = 'https://cyguardian.com';
static const String _prodLocalUrl = 'https://cyguardian.com';
```

### How to Use
```dart
import '../config/api_config.dart';

// Get base URL
String baseUrl = ApiConfig.apiBaseUrl;

// Build URLs
String loginUrl = ApiConfig.buildUrl(ApiConfig.login);
String userUrl = ApiConfig.buildUrlWithParams(ApiConfig.userById, {'id': 'user123'});

// Environment checks
if (ApiConfig.isProduction) {
  // Production code
}
```

## Available Endpoints

### Authentication
- `ApiConfig.login` - `/login`
- `ApiConfig.me` - `/me`
- `ApiConfig.changePassword` - `/change-password`

### User Management
- `ApiConfig.users` - `/users/`
- `ApiConfig.userById` - `/users/{id}`

### OTP Service
- `ApiConfig.generateOtp` - `/otp/generate-otp`
- `ApiConfig.verifyOtp` - `/otp/verify-otp`
- `ApiConfig.clearOtp` - `/otp/clear-otp/{email}`

### Questionnaire Service
- `ApiConfig.questionnaires` - `/questionnaires/`
- `ApiConfig.questionnaireById` - `/questionnaires/{id}`

### Company History Service
- `ApiConfig.companyHistory` - `/company-history/`

### Risk Assessment Service
- `ApiConfig.riskAssessments` - `/risk-assessments/`

## Architecture

### API Gateway Pattern
All requests go through the API gateway (port 8000) which routes to microservices:

```
Frontend → API Gateway (8000) → Microservices (8001-8007)
```

### Microservices
- **Auth Service** (8001) - Authentication
- **Users Service** (8003) - User management
- **Questionnaire Service** (8002) - Security questionnaires
- **Risk Service** (8004) - Risk assessments
- **Company History Service** (8005) - Company history
- **Email Service** (8006) - Email notifications
- **OTP Service** (8007) - One-time passwords

## Code Migration Examples

### Before (Old Way)
```dart
final response = await http.post(
  Uri.parse('${AuthService.apiBaseUrl}/login'),
  // ...
);
```

### After (New Way)
```dart
final response = await http.post(
  Uri.parse(ApiConfig.buildUrl(ApiConfig.login)),
  // ...
);
```

## Production Deployment Steps

### 1. Update Configuration
```dart
// In lib/config/api_config.dart
static const bool _isProduction = true;
static const String _prodWebUrl = 'https://your-domain.com';
static const String _prodAndroidUrl = 'https://your-domain.com';
static const String _prodLocalUrl = 'https://your-domain.com';
```

### 2. Build for Production
```bash
# Android
flutter build apk --release

# Web
flutter build web --release

# iOS
flutter build ios --release
```

### 3. Test Configuration
```dart
ApiConfig.printConfig();
// Should show: Environment: production, Base URL: https://your-domain.com
```

## Troubleshooting

### Common Issues

1. **Wrong URL in production**
   - Check `_isProduction` is set to `true`
   - Verify production URLs are correct
   - Use `ApiConfig.printConfig()` to debug

2. **Android emulator can't connect**
   - Development uses `10.0.2.2` for Android emulator
   - Production uses the same domain for all platforms

3. **CORS issues**
   - Ensure your production server allows requests from your domain
   - Check that the API gateway is properly configured

### Debug Commands
```dart
// Print current configuration
ApiConfig.printConfig();

// Check environment
print('Is Production: ${ApiConfig.isProduction}');
print('Base URL: ${ApiConfig.apiBaseUrl}');
```

## Best Practices

1. **Always use endpoint constants** instead of hardcoding URLs
2. **Use `buildUrl()` for simple endpoints**
3. **Use `buildUrlWithParams()` for endpoints with parameters**
4. **Test both environments** before deploying
5. **Use `ApiConfig.printConfig()` for debugging**

## Benefits

1. **Single Source of Truth**: All URLs in one place
2. **Easy Environment Switching**: One boolean to change
3. **Type Safety**: Compile-time checking of endpoints
4. **Maintainability**: Easy to update URLs
5. **Consistency**: All services use the same configuration
6. **Debugging**: Built-in configuration printing

---

**This guide replaces all other frontend .md files and contains everything you need to know about the CyGuardian frontend.**
