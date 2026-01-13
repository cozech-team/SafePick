import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000/api';
  final StorageService _storage = StorageService();

  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  // Initialize and check if user is logged in
  Future<void> init() async {
    final token = await _storage.getAccessToken();
    if (token != null) {
      await loadUserProfile();
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.saveTokens(data['access'], data['refresh']);
        await loadUserProfile();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
          'first_name': firstName ?? '',
          'last_name': lastName ?? '',
        }),
      );

      if (response.statusCode == 201) {
        // Auto-login after registration
        return await login(username, password);
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(json.decode(response.body));
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearTokens();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Refresh token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/users/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _storage.saveAccessToken(data['access']);
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }
}
