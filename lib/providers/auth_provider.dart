import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../services/auth_service.dart' as auth_service;
import '../services/otp_service.dart';
import '../services/http_service.dart';
import '../services/token_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class Organization {
  final String id;
  final String domain;
  final User? cto;
  final User? cyberSecurityHead;
  final List<User> subDepartmentHeads;

  Organization({
    required this.id,
    required this.domain,
    this.cto,
    this.cyberSecurityHead,
    this.subDepartmentHeads = const [],
  });
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String domain;
  final String? departmentName;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.domain,
    this.departmentName,
  });
}

class AuthProvider extends ChangeNotifier {
  final auth_service.AuthService _authService;
  final OTPService _otpService;
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;

  final List<Organization> _organizations = [];

  // Test data only available in debug mode
  final List<User> _testUsers = kDebugMode
      ? [
          User(
            id: '1',
            name: 'CTO User',
            email: 'cto@example.com',
            role: UserRole.cto,
            domain: 'example.com',
          ),
          User(
            id: '2',
            name: 'Cybersecurity Head',
            email: 'cs@example.com',
            role: UserRole.cyberSecurityHead,
            domain: 'example.com',
          ),
          User(
            id: '3',
            name: 'Sub-Department Head',
            email: 'sub@example.com',
            role: UserRole.subDepartmentHead,
            domain: 'example.com',
          ),
        ]
      : [];

  AuthProvider(this._authService, this._otpService) {
    // Only add test organization in debug mode
    if (kDebugMode && _testUsers.isNotEmpty) {
      _organizations.add(
        Organization(
          id: '1',
          domain: 'example.com',
          cto: _testUsers[0],
          cyberSecurityHead: _testUsers[1],
          subDepartmentHeads: [_testUsers[2]],
        ),
      );
    }
  }

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get accessToken => _accessToken;
  List<Organization> get organizations => _organizations;

  String _extractDomain(String email) {
    return email.split('@').last.toLowerCase();
  }

  Organization? findOrganizationByDomain(String domain) {
    try {
      return _organizations.firstWhere((org) => org.domain == domain);
    } catch (e) {
      return null;
    }
  }

  Future<Organization?> findOrganizationByDomainWithFetch(String domain) async {
    try {
      final users = await fetchSubDepartmentHeadsByDomain(domain);
      if (users.isEmpty) return null;

      return Organization(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        domain: domain,
        cto: null,
        cyberSecurityHead: null,
        subDepartmentHeads: users,
      );
    } catch (e) {
      debugPrint('Failed to fetch organization: $e');
      return null;
    }
  }

  User? _findUserByEmail(String email) {
    for (var org in _organizations) {
      if (org.cto?.email == email) return org.cto;
      if (org.cyberSecurityHead?.email == email) return org.cyberSecurityHead;
      for (var user in org.subDepartmentHeads) {
        if (user.email == email) return user;
      }
    }
    try {
      return _testUsers.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate input
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Please enter both email and password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_isValidEmail(email)) {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Call the auth service
      final data = await _authService.signIn(email, password);

      // Parse user data
      print('DEBUG: Login response data: $data');
      print('DEBUG: Role from server: ${data['role']}');
      print(
          'DEBUG: Available roles: ${UserRole.values.map((r) => r.name).toList()}');

      _user = User(
        id: data['user_id'] ?? data['id'] ?? '',
        name: data['name'] ?? email.split('@')[0],
        email: data['email'] ?? email,
        role: UserRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => UserRole.subDepartmentHead,
        ),
        domain: data['department_id'] ?? _extractDomain(email),
        departmentName: data['department_name'],
      );

      _accessToken = data['access_token'];

      // Save tokens and user data
      if (_accessToken != null) {
        await TokenService.saveTokens(
          accessToken: _accessToken!,
          refreshToken: data['refresh_token'],
          expiry: data['expires_in'] != null
              ? DateTime.now().add(Duration(seconds: data['expires_in']))
              : null,
        );

        await TokenService.saveUserData({
          'id': _user!.id,
          'name': _user!.name,
          'email': _user!.email,
          'role': _user!.role.name,
          'domain': _user!.domain,
          'departmentName': _user!.departmentName,
        });
      }

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Login API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage =
          'Login failed. Please check your internet connection and try again.';
      if (kDebugMode) {
        print('Login error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<bool> register(
      String email, String password, String otp, UserRole role,
      {String? departmentName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate input
      if (email.isEmpty || password.isEmpty || otp.isEmpty) {
        _errorMessage = 'Please fill in all required fields';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_isValidEmail(email)) {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters long';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verify OTP first
      final otpValid = await verifyOTP(email, otp);
      if (!otpValid) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if user already exists (only in debug mode with test data)
      if (kDebugMode) {
        final existingUser = _findUserByEmail(email);
        if (existingUser != null) {
          _errorMessage = 'A user with this email already exists';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Call the auth service to register
      final data = await _authService.signUp(
        email,
        password,
        role,
        name: email.split('@')[0],
        departmentName: departmentName,
      );

      // Parse user data
      _user = User(
        id: data['id'] ?? '',
        name: data['name'] ?? email.split('@')[0],
        email: data['email'] ?? email,
        role: UserRole.values.firstWhere(
          (r) => r.name == data['role'],
          orElse: () => role,
        ),
        domain: data['department_id'] ?? _extractDomain(email),
        departmentName: data['department_name'] ?? departmentName,
      );

      // Try to auto-login after registration
      final loggedIn = await login(email, password);
      if (!loggedIn) {
        _errorMessage =
            'Registration successful, but auto-login failed. Please log in manually.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update organization data (only in debug mode)
      if (kDebugMode) {
        final domain = _extractDomain(email);
        Organization? organization = findOrganizationByDomain(domain);

        if (organization == null) {
          organization = Organization(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            domain: domain,
            cto: role == UserRole.cto ? _user : null,
            cyberSecurityHead:
                role == UserRole.cyberSecurityHead ? _user : null,
          );
          _organizations.add(organization);
        } else {
          final index = _organizations.indexOf(organization);
          if (role == UserRole.cto) {
            _organizations[index] = Organization(
              id: organization.id,
              domain: organization.domain,
              cto: _user,
              cyberSecurityHead: organization.cyberSecurityHead,
              subDepartmentHeads: organization.subDepartmentHeads,
            );
          } else if (role == UserRole.cyberSecurityHead) {
            _organizations[index] = Organization(
              id: organization.id,
              domain: organization.domain,
              cto: organization.cto,
              cyberSecurityHead: _user,
              subDepartmentHeads: organization.subDepartmentHeads,
            );
          }
        }
      }

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Registration API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage =
          'An error occurred during registration. Please try again.';
      if (kDebugMode) {
        print('Registration error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> sendOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate email
      if (email.isEmpty || !_isValidEmail(email)) {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        if (kDebugMode) {
          print('Email validation failed: $email');
        }
        return false;
      }

      if (kDebugMode) {
        print('Calling OTP service for email: $email');
      }

      // Call the OTP service
      await _otpService.sendOTP(email, userName: email.split('@')[0]);

      if (kDebugMode) {
        print('OTP service call successful');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Send OTP API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage =
          'Failed to send OTP. Please check your internet connection.';
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate input
      if (email.isEmpty || otp.isEmpty) {
        _errorMessage = 'Please enter both email and OTP';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_isValidEmail(email)) {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Call the OTP service
      final response = await _otpService.verifyOTP(email, otp);
      bool isValid = response['verified'] == true;

      if (isValid) {
        // Update user information if provided in response
        if (response['name'] != null) {
          _user = User(
            id: response['id'] ?? 'unknown',
            name: response['name'],
            email: email,
            role: UserRole.values.firstWhere(
              (role) => role.name.toLowerCase() == (response['role']?.toLowerCase() ?? 'user'),
              orElse: () => UserRole.subDepartmentHead,
            ),
            domain: _extractDomain(email),
            departmentName: response['department_name'],
          );
          
          // Set authentication state
          _isAuthenticated = true;
        }
        
        if (kDebugMode) {
          print('OTP verified successfully');
        }
      } else {
        _errorMessage = 'Invalid OTP. Please try again.';
      }

      _isLoading = false;
      notifyListeners();
      return isValid;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Verify OTP API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage =
          'Failed to verify OTP. Please check your internet connection.';
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    try {
      // Clear tokens from storage
      await TokenService.clearTokens();

      // Clear local state
      _user = null;
      _isAuthenticated = false;
      _accessToken = null;

      // Call auth service logout if needed
      await _authService.signOut();

      if (kDebugMode) {
        print('User logged out successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Logout error: $e');
      }
      // Even if logout fails, clear local state
      _user = null;
      _isAuthenticated = false;
      _accessToken = null;
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<User>> fetchSubDepartmentHeadsByDomain(String domain) async {
    try {
      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        if (kDebugMode) {
          print('No valid access token available for fetching users');
        }
        return [];
      }

      final response = await HttpService.get(
        ApiConfig.users,
        accessToken: accessToken,
        queryParams: {
          'domain': domain,
          'role': 'subDepartmentHead',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .map((userJson) => User(
                  id: userJson['id'] ?? '',
                  name: userJson['name'] ?? '',
                  email: userJson['email'] ?? '',
                  role: UserRole.values.firstWhere(
                    (r) => r.name == userJson['role'],
                    orElse: () => UserRole.subDepartmentHead,
                  ),
                  domain: userJson['department_id'] ?? domain,
                  departmentName: userJson['department_name'],
                ))
            .toList();
      } else {
        if (kDebugMode) {
          print(
              'Failed to fetch users: ${response.statusCode} - ${response.body}');
        }
      }
    } on ApiException catch (e) {
      if (kDebugMode) {
        print('Failed to fetch users: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch users: $e');
      }
    }
    return [];
  }

  Future<bool> createSubDepartmentHead(
      String name, String email, String password, String departmentName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate permissions - allow any authenticated user for now
      // TODO: Update this based on your actual role names
      if (_user == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate input
      if (name.isEmpty ||
          email.isEmpty ||
          password.isEmpty ||
          departmentName.isEmpty) {
        _errorMessage = 'Please fill in all required fields';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (!_isValidEmail(email)) {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'Password must be at least 6 characters long';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final domain = _extractDomain(email);
      if (domain != _user!.domain) {
        _errorMessage = 'Email domain must match your organization domain';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await HttpService.post(
        ApiConfig.users,
        accessToken: accessToken,
        body: {
          'name': name,
          'email': email,
          'password': password,
          'role': 'subDepartmentHead',
          'department_id': domain,
          'department_name': departmentName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final newUser = User(
          id: data['id'] ?? '',
          name: data['name'] ?? name,
          email: data['email'] ?? email,
          role: UserRole.values.firstWhere(
            (r) => r.name == data['role'],
            orElse: () => UserRole.subDepartmentHead,
          ),
          domain: data['department_id'] ?? domain,
          departmentName: data['department_name'] ?? departmentName,
        );

        // Update organization data (only in debug mode)
        if (kDebugMode) {
          final organization = findOrganizationByDomain(domain);
          if (organization != null) {
            final index = _organizations.indexOf(organization);
            _organizations[index] = Organization(
              id: organization.id,
              domain: organization.domain,
              cto: organization.cto,
              cyberSecurityHead: organization.cyberSecurityHead,
              subDepartmentHeads: [...organization.subDepartmentHeads, newUser],
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Create user API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage = 'An error occurred while creating the user';
      if (kDebugMode) {
        print('Create user error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateSubDepartmentHead(
      {required String userId,
      String? name,
      String? email,
      String? password,
      String? departmentName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate permissions
      if (_user?.role != UserRole.cyberSecurityHead) {
        _errorMessage =
            'Only Cybersecurity Heads can update Sub-Department Heads';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Build update payload
      final updatePayload = <String, dynamic>{};
      if (name != null && name.isNotEmpty) updatePayload['name'] = name;
      if (email != null && email.isNotEmpty) {
        if (!_isValidEmail(email)) {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final domain = _extractDomain(email);
        if (domain != _user!.domain) {
          _errorMessage = 'Email domain must match your organization domain';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        updatePayload['email'] = email;
        updatePayload['department_id'] = domain;
      }
      if (password != null && password.isNotEmpty && password != 'unchanged') {
        if (password.length < 6) {
          _errorMessage = 'Password must be at least 6 characters long';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        updatePayload['password'] = password;
      }
      if (departmentName != null && departmentName.isNotEmpty) {
        updatePayload['department_name'] = departmentName;
      }

      if (updatePayload.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return true; // nothing to update
      }

      final response = await HttpService.patch(
        ApiConfig.buildUrlWithParams(ApiConfig.userById, {'id': userId}),
        accessToken: accessToken,
        body: updatePayload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update local organization cache (only in debug mode)
        if (kDebugMode) {
          final domain = data['department_id'] ?? _user!.domain;
          final updatedUser = User(
            id: data['id'] ?? userId,
            name: data['name'] ?? name ?? '',
            email: data['email'] ?? email ?? '',
            role: UserRole.values.firstWhere(
              (r) => r.name == data['role'],
              orElse: () => UserRole.subDepartmentHead,
            ),
            domain: domain,
            departmentName: data['department_name'] ?? departmentName,
          );

          final organization = findOrganizationByDomain(domain);
          if (organization != null) {
            final index = _organizations.indexOf(organization);
            final updatedList = organization.subDepartmentHeads
                .map((u) => u.id == userId ? updatedUser : u)
                .toList();
            _organizations[index] = Organization(
              id: organization.id,
              domain: organization.domain,
              cto: organization.cto,
              cyberSecurityHead: organization.cyberSecurityHead,
              subDepartmentHeads: updatedList,
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Update user API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage = 'An error occurred while updating the user';
      if (kDebugMode) {
        print('Update user error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteSubDepartmentHead(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate permissions
      if (_user?.role != UserRole.cyberSecurityHead) {
        _errorMessage =
            'Only Cybersecurity Heads can delete Sub-Department Heads';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await HttpService.delete(
        ApiConfig.buildUrlWithParams(ApiConfig.userById, {'id': userId}),
        accessToken: accessToken,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local organization list (only in debug mode)
        if (kDebugMode) {
          final domain = _user!.domain;
          final organization = findOrganizationByDomain(domain);
          if (organization != null) {
            final index = _organizations.indexOf(organization);
            _organizations[index] = Organization(
              id: organization.id,
              domain: organization.domain,
              cto: organization.cto,
              cyberSecurityHead: organization.cyberSecurityHead,
              subDepartmentHeads: organization.subDepartmentHeads
                  .where((user) => user.id != userId)
                  .toList(),
            );
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Delete user API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage = 'An error occurred while deleting the user';
      if (kDebugMode) {
        print('Delete user error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Validate input
      if (currentPassword.isEmpty || newPassword.isEmpty) {
        _errorMessage = 'Please enter both current and new passwords';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (newPassword.length < 6) {
        _errorMessage = 'New password must be at least 6 characters long';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (currentPassword == newPassword) {
        _errorMessage = 'New password must be different from current password';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_user == null) {
        _errorMessage = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use the auth service method
      await _authService.changePassword(
        accessToken: accessToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Change password API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage = 'An error occurred while changing password';
      if (kDebugMode) {
        print('Change password error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_user == null) {
        _errorMessage = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final accessToken = await TokenService.getValidAccessToken();
      if (accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Handle password change separately using the dedicated endpoint
      if (currentPassword != null &&
          currentPassword.isNotEmpty &&
          newPassword != null &&
          newPassword.isNotEmpty) {
        final passwordSuccess = await changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        if (!passwordSuccess) {
          return false; // Password change failed, don't continue with profile update
        }
      }

      final updatePayload = <String, dynamic>{};

      if (name != null && name.isNotEmpty && name != _user!.name) {
        updatePayload['name'] = name;
      }

      if (email != null && email.isNotEmpty && email != _user!.email) {
        if (!_isValidEmail(email)) {
          _errorMessage = 'Please enter a valid email address';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        final domain = _extractDomain(email);
        if (domain != _user!.domain) {
          _errorMessage = 'Email domain must match your organization domain';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        updatePayload['email'] = email;
      }

      if (updatePayload.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return true; // Nothing to update
      }

      final response = await HttpService.patch(
        ApiConfig.buildUrlWithParams(ApiConfig.userById, {'id': _user!.id}),
        accessToken: accessToken,
        body: updatePayload,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update local user data
        _user = User(
          id: data['id'] ?? _user!.id,
          name: data['name'] ?? name ?? _user!.name,
          email: data['email'] ?? email ?? _user!.email,
          role: UserRole.values.firstWhere(
            (r) => r.name == data['role'],
            orElse: () => _user!.role,
          ),
          domain: data['department_id'] ?? _user!.domain,
          departmentName: data['department_name'] ?? _user!.departmentName,
        );

        // Update stored user data
        await TokenService.saveUserData({
          'id': _user!.id,
          'name': _user!.name,
          'email': _user!.email,
          'role': _user!.role.name,
          'domain': _user!.domain,
          'departmentName': _user!.departmentName,
        });

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
      if (kDebugMode) {
        print('Update profile API error: ${e.message} (${e.statusCode})');
      }
    } catch (e) {
      _errorMessage = 'An error occurred while updating profile';
      if (kDebugMode) {
        print('Update profile error: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
