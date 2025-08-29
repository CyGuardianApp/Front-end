import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';

class AuthorizedRoute extends StatelessWidget {
  final WidgetBuilder builder;
  final List<String> allowedRoles;

  const AuthorizedRoute({
    super.key,
    required this.builder,
    required this.allowedRoles,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // If 'all' is in allowedRoles, any authenticated user can access
        if (allowedRoles.contains('all')) {
          return builder(context);
        }

        final userRole = authProvider.user?.role.toString().split('.').last;
        if (userRole == null || !allowedRoles.contains(userRole)) {
          return const UnauthorizedScreen();
        }

        return builder(context);
      },
    );
  }
}

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unauthorized')),
      body: const Center(
        child: Text('You do not have permission to access this page.'),
      ),
    );
  }
}
