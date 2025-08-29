import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  // Use centralized API configuration
  static String get apiBaseUrl => ApiConfig.apiBaseUrl;

  Future<User> signIn(String email, String password) async {
    throw UnimplementedError();
  }

  Future<User> signUp(String email, String password, UserRole role) async {
    throw UnimplementedError();
  }

  Future<void> signOut() async {
    throw UnimplementedError();
  }
}
