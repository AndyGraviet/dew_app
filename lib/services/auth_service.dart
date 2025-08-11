import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.authTokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.authTokenKey);
  }

  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authTokenKey);
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  // Placeholder methods for future implementation
  Future<User?> login(String email, String password) async {
    // TODO: Implement actual login logic
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<User?> register(String name, String email, String password) async {
    // TODO: Implement actual registration logic
    await Future.delayed(const Duration(seconds: 1));
    return null;
  }

  Future<void> logout() async {
    await clearAuthToken();
  }
} 