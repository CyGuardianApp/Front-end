import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/responsive_container.dart';
import '../widgets/otp_input.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isOtpSent = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isRegistering = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  UserRole _selectedRole = UserRole.cyberSecurityHead; // Default role

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _confirmPasswordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Debug logging
      if (kDebugMode) {
        print('Sending OTP to: ${_emailController.text.toLowerCase()}');
      }

      final success = await authProvider.sendOTP(
          _emailController.text.toLowerCase()); // Make email case-insensitive

      // Debug logging
      if (kDebugMode) {
        print('OTP send result: $success');
        print('AuthProvider error: ${authProvider.errorMessage}');
      }

      if (success && mounted) {
        if (kDebugMode) {
          print('Setting _isOtpSent to true');
        }
        setState(() {
          _isOtpSent = true;
        });
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'OTP sent successfully! Please check your email.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else if (mounted) {
        // Show error message if OTP sending failed
        if (kDebugMode) {
          print('OTP send failed, showing error message');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ??
                        'Failed to send OTP. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Try to connect to the auth service to check if backend is available
      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/health/auth'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Show loading state
      setState(() {
        // Keep the current state
      });

      // Check network connectivity first
      final isNetworkAvailable = await _checkNetworkConnectivity();
      if (!isNetworkAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Backend services are not available. Please check if the backend is running.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _register(),
            ),
          ),
        );
        return;
      }

      // Try registration with retry mechanism
      bool success = false;
      int retryCount = 0;
      const maxRetries = 2;

      while (!success && retryCount <= maxRetries) {
        if (retryCount > 0) {
          // Show retry message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Retrying registration... ($retryCount/$maxRetries)'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          // Wait before retry
          await Future.delayed(const Duration(seconds: 1));
        }

        success = await authProvider.register(
          _emailController.text.toLowerCase(), // Make email case-insensitive
          _passwordController.text,
          _otpController.text,
          _selectedRole,
        );

        retryCount++;
      }

      if (success && mounted) {
        // After successful registration, log the user out and redirect to login
        authProvider.logout(); // Log the user out
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registration successful. Please log in with your credentials.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          _isRegistering = false;
          _isOtpSent = false;
        });
      } else if (mounted) {
        // Show error message if registration failed
        String errorMessage = authProvider.errorMessage ??
            'Registration failed. Please try again.';
        if (retryCount > 1) {
          errorMessage += ' (Tried $retryCount times)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(errorMessage),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _register(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // First verify OTP
      final otpValid = await authProvider.verifyOTP(
          _emailController.text, _otpController.text);
      if (!otpValid) {
        // Show OTP verification error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ??
                        'Invalid OTP. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      // Then login
      final success = await authProvider.login(
        _emailController.text.toLowerCase(), // Make email case-insensitive
        _passwordController.text,
      );

      if (success && mounted) {
        // Check if user needs to change password
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (mounted) {
        // Show login error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    authProvider.errorMessage ??
                        'Login failed. Please try again.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _toggleRegister() {
    setState(() {
      _isRegistering = !_isRegistering;
      _isOtpSent = false;
      _selectedRole = UserRole.cyberSecurityHead;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: ResponsiveContainer(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width < 400 ? 16.0 : 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    // Logo and branding
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.security,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CyGuardian',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enterprise-Grade Cyber Risk Assessment',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 48),
                    // Login/Register form
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width < 400
                                ? 20.0
                                : 32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _isRegistering
                                          ? Icons.person_add
                                          : Icons.login,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _isRegistering
                                        ? 'Create Account'
                                        : 'Welcome Back',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              // Email field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Work Email',
                                    hintText: 'Enter your company email',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.email,
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                  enabled: !authProvider.isLoading,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Password field
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.lock,
                                        color: Theme.of(context).primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[600],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    // Only apply complex password validation for registration
                                    if (_isRegistering && value.length < 8) {
                                      return 'Password must be at least 8 characters for registration';
                                    }
                                    // Optional: Add complex password validation for registration
                                    // if (_isRegistering &&
                                    //     !RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                                    //         .hasMatch(value)) {
                                    //   return 'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character';
                                    // }
                                    return null;
                                  },
                                  enabled: !authProvider.isLoading,
                                ),
                              ),
                              // Confirm Password field (only for registration)
                              if (_isRegistering) ...[
                                const SizedBox(height: 20),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      hintText: 'Confirm your password',
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          color: Theme.of(context).primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible =
                                                !_isConfirmPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    obscureText: !_isConfirmPasswordVisible,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your password';
                                      }
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                    enabled: !authProvider.isLoading,
                                  ),
                                ),

                                // Role selector (only for registration)
                                const SizedBox(height: 24),
                                Container(
                                  padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.width < 400
                                          ? 16.0
                                          : 20.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.withOpacity(0.1),
                                        Colors.blue.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.blue.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.blue.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.work,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Select your role in the organization:',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue[700],
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // CTO Radio button
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == UserRole.cto
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedRole == UserRole.cto
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            'Chief Technology Officer (CTO)',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  _selectedRole == UserRole.cto
                                                      ? Colors.blue[700]
                                                      : Colors.grey[800],
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Overall responsible for technology and security strategy',
                                            style: TextStyle(
                                              color:
                                                  _selectedRole == UserRole.cto
                                                      ? Colors.blue[600]
                                                      : Colors.grey[600],
                                            ),
                                          ),
                                          leading: Radio<UserRole>(
                                            value: UserRole.cto,
                                            groupValue: _selectedRole,
                                            activeColor: Colors.blue,
                                            onChanged: (UserRole? value) {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedRole = value;
                                                });
                                              }
                                            },
                                          ),
                                          dense: true,
                                        ),
                                      ),

                                      // Cybersecurity Head Radio button
                                      Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedRole ==
                                                  UserRole.cyberSecurityHead
                                              ? Colors.blue.withOpacity(0.1)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _selectedRole ==
                                                    UserRole.cyberSecurityHead
                                                ? Colors.blue.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            'Cybersecurity Head',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: _selectedRole ==
                                                      UserRole.cyberSecurityHead
                                                  ? Colors.blue[700]
                                                  : Colors.grey[800],
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Manages cybersecurity teams and risk assessments',
                                            style: TextStyle(
                                              color: _selectedRole ==
                                                      UserRole.cyberSecurityHead
                                                  ? Colors.blue[600]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          leading: Radio<UserRole>(
                                            value: UserRole.cyberSecurityHead,
                                            groupValue: _selectedRole,
                                            activeColor: Colors.blue,
                                            onChanged: (UserRole? value) {
                                              if (value != null) {
                                                setState(() {
                                                  _selectedRole = value;
                                                });
                                              }
                                            },
                                          ),
                                          dense: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Domain verification information
                                const SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(
                                      MediaQuery.of(context).size.width < 400
                                          ? 12.0
                                          : 16.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.info_outline,
                                              color: Colors.blue.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Organization Verification',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Users from the same organization must register with email addresses from the same domain.',
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Only CTO and Cybersecurity Head can register. Sub-Department Heads are created by the CISO/CS Head.',
                                        style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // OTP field (shown after sending OTP)
                              if (_isOtpSent) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.green.withOpacity(0.1),
                                        Colors.green.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.verified,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'One-Time Password (OTP)',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[700],
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      OtpInput(
                                        controller: _otpController,
                                        onComplete: (_) {
                                          if (_isRegistering) {
                                            _register();
                                          } else {
                                            _login();
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton.icon(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () async {
                                                await authProvider.sendOTP(
                                                    _emailController.text
                                                        .toLowerCase()); // Make email case-insensitive
                                              },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Resend OTP'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              // Error message
                              if (authProvider.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline,
                                          color: Colors.red[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style:
                                              TextStyle(color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                              // Login/Register button
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: authProvider.isLoading
                                      ? null
                                      : _isOtpSent
                                          ? (_isRegistering
                                              ? _register
                                              : _login)
                                          : _sendOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _isOtpSent
                                                  ? (_isRegistering
                                                      ? Icons.person_add
                                                      : Icons.login)
                                                  : Icons.send,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _isOtpSent
                                                  ? (_isRegistering
                                                      ? 'Create Account'
                                                      : 'Sign In')
                                                  : 'Send OTP',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Toggle between Login and Register
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isRegistering
                                          ? 'Already have an account?'
                                          : 'Don\'t have an account?',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: _toggleRegister,
                                      child: Text(
                                        _isRegistering ? 'Sign In' : 'Register',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Testing cardinalities
                              if (kDebugMode) ...[
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.developer_mode,
                                              color: Colors.orange[700]),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Testing Credentials:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'CTO: c@c.com / Cc12345@\nCS Head: ciso@c.com / Cc12345@\n(Email case doesn\'t matter)',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'OTP: 123456',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Note: Registration requires backend services to be running. If registration fails, check that the backend is running on ports 8001 and 8003.',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
