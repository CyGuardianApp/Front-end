import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/otp_service.dart';

enum UserRole { cto, cyberSecurityHead, subDepartmentHead }

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
  final AuthService _authService;
  final OTPService _otpService;
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;

  final List<Organization> _organizations = [];

  final List<User> _testUsers = [
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
  ];

  AuthProvider(this._authService, this._otpService) {
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
      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/login'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User(
          id: data['user_id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere((r) => r.name == data['role']),
          domain: data['department_id'],
          departmentName: data['department_name'],
        );
        _accessToken = data['access_token'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid email or password';
      }
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(
      String email, String password, String otp, UserRole role,
      {String? departmentName}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final otpValid = await verifyOTP(email, otp);
      if (!otpValid) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final domain = _extractDomain(email);
      final existingUser = _findUserByEmail(email);
      if (existingUser != null) {
        _errorMessage = 'A user with this email already exists';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      Organization? organization = findOrganizationByDomain(domain);

      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': email.split('@')[0],
          'email': email,
          'password': password,
          'role': role.name,
          'department_id': domain,
          'department_name': departmentName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _user = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere((r) => r.name == data['role']),
          domain: data['department_id'],
          departmentName: data['department_name'],
        );
        // Acquire access token so subsequent calls (like fetching sub-department heads) work
        final loggedIn = await login(email, password);
        if (!loggedIn) {
          _errorMessage = 'Registered but auto-login failed';
        }
      } else {
        _errorMessage = 'Registration failed';
      }

      if (organization == null) {
        organization = Organization(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          domain: domain,
          cto: role == UserRole.cto ? _user : null,
          cyberSecurityHead: role == UserRole.cyberSecurityHead ? _user : null,
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

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'An error occurred during registration. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOTP(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call the real backend OTP service
      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/otp/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'user_name': email.split('@')[0], // Extract name from email
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        _errorMessage =
            errorBody['detail'] ?? 'Failed to send OTP. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Failed to send OTP. Please check your internet connection.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Call the real backend OTP verification service
      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/otp/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        bool isValid = data['verified'] == true;

        if (!isValid) {
          _errorMessage = 'Invalid OTP. Please try again.';
        }

        _isLoading = false;
        notifyListeners();
        return isValid;
      } else {
        final errorBody = jsonDecode(response.body);
        _errorMessage =
            errorBody['detail'] ?? 'Failed to verify OTP. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage =
          'Failed to verify OTP. Please check your internet connection.';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _user = null;
    _isAuthenticated = false;
    _accessToken = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<List<User>> fetchSubDepartmentHeadsByDomain(String domain) async {
    try {
      if (_accessToken == null) {
        debugPrint('No access token available for fetching users');
        return [];
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final response = await http.get(
        Uri.parse(
            '${AuthService.apiBaseUrl}/users/?domain=$domain&role=subDepartmentHead'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        return data
            .map((userJson) => User(
                  id: userJson['id'],
                  name: userJson['name'],
                  email: userJson['email'],
                  role: UserRole.values
                      .firstWhere((r) => r.name == userJson['role']),
                  domain: userJson['department_id'],
                  departmentName: userJson['department_name'],
                ))
            .toList();
      } else {
        debugPrint(
            'Failed to fetch users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Failed to fetch users: $e');
    }
    return [];
  }

  Future<bool> createSubDepartmentHead(
      String name, String email, String password, String departmentName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_user?.role != UserRole.cyberSecurityHead) {
        _errorMessage =
            'Only Cybersecurity Heads can create Sub-Department Heads';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final domain = _extractDomain(email);
      if (domain != _user!.domain) {
        _errorMessage =
            'Email domain must match your organization domain ($domain)';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': 'subDepartmentHead',
          'department_id': domain,
          'department_name': departmentName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final newUser = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere((r) => r.name == data['role']),
          domain: data['department_id'],
          departmentName: data['department_name'],
        );

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

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Failed to create user';
        }
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
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
      if (_user?.role != UserRole.cyberSecurityHead) {
        _errorMessage =
            'Only Cybersecurity Heads can update Sub-Department Heads';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final updatePayload = <String, dynamic>{};
      if (name != null && name.isNotEmpty) updatePayload['name'] = name;
      if (email != null && email.isNotEmpty) {
        final domain = _extractDomain(email);
        if (domain != _user!.domain) {
          _errorMessage =
              'Email domain must match your organization domain ($domain)';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        updatePayload['email'] = email;
        updatePayload['department_id'] = domain;
      }
      if (password != null && password.isNotEmpty && password != 'unchanged') {
        if (password.length < 6) {
          _errorMessage = 'Password too short';
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

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final response = await http.patch(
        Uri.parse('${AuthService.apiBaseUrl}/users/$userId'),
        headers: headers,
        body: jsonEncode(updatePayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update local organization cache
        final domain = data['department_id'];
        final updatedUser = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere((r) => r.name == data['role']),
          domain: domain,
          departmentName: data['department_name'],
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

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to update user';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
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
      if (_user?.role != UserRole.cyberSecurityHead) {
        _errorMessage =
            'Only Cybersecurity Heads can delete Sub-Department Heads';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final response = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Remove from local organization list
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

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        if (errorData['detail'] != null) {
          _errorMessage = errorData['detail'];
        } else {
          _errorMessage = 'Failed to delete user';
        }
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
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
      if (_user == null) {
        _errorMessage = 'User not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (_accessToken == null) {
        _errorMessage = 'Authentication required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final payload = {
        'current_password': currentPassword,
        'new_password': newPassword,
      };

      final response = await http.post(
        Uri.parse('${AuthService.apiBaseUrl}/change-password'),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to change password';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
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

      if (_accessToken == null) {
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

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      };

      final response = await http.patch(
        Uri.parse('${AuthService.apiBaseUrl}/users/${_user!.id}'),
        headers: headers,
        body: jsonEncode(updatePayload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Update local user data
        _user = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
          role: UserRole.values.firstWhere((r) => r.name == data['role']),
          domain: data['department_id'],
          departmentName: data['department_name'],
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['detail'] ?? 'Failed to update profile';
      }
    } catch (e) {
      _errorMessage = 'An error occurred: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
