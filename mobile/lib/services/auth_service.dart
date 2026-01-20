import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;

class AuthService extends ChangeNotifier {
  static String get baseUrl {
    // Production backend on Render
    return 'https://safepick-1.onrender.com/api';

    // For local development, uncomment and use one of these:
    // if (kIsWeb) return 'http://localhost:8000/api';  // Web
    // return 'http://10.0.2.2:8000/api';  // Android Emulator
    // return 'http://192.168.1.4:8000/api';  // Physical Device
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '819106507078-i1u1uq5lvv929tu29htm8ga4psd691lh.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  app_user.User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _idToken;

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;

  AuthService() {
    init();
  }

  // Initialize and check if user is logged in
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('id_token');
    final userJson = prefs.getString('user');

    if (token != null && userJson != null) {
      _idToken = token;
      final userData = json.decode(userJson);
      _currentUser = app_user.User.fromJson(userData);
      _isAuthenticated = true;
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Get ID token for backend authentication
  Future<String?> getIdToken() async {
    return _idToken;
  }

  // Google Sign-In
  Future<bool> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return false;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Use Google ID token directly (no Firebase!)
      _idToken = googleAuth.idToken;

      if (_idToken == null) {
        print('Failed to get Google ID token');
        return false;
      }

      // Create user from Google account
      _currentUser = app_user.User(
        id: googleUser.id,
        username: googleUser.email.split('@')[0],
        email: googleUser.email,
        firstName: googleUser.displayName?.split(' ').first ?? '',
        lastName: (googleUser.displayName?.split(' ').length ?? 0) > 1
            ? googleUser.displayName!.split(' ').last
            : '',
      );

      _isAuthenticated = true;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id_token', _idToken!);
      await prefs.setString('user', json.encode(_currentUser!.toJson()));

      notifyListeners();

      // Sync with backend
      await _syncWithBackend();

      print('Google Sign-In successful: ${googleUser.email}');
      return true;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
    }
  }

  // Sync user with backend
  Future<void> _syncWithBackend() async {
    try {
      final token = await getIdToken();
      if (token == null) return;

      final response = await http.post(
        Uri.parse('$baseUrl/users/sync/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'uid': _currentUser?.id,
          'email': _currentUser?.email,
          'display_name':
              '${_currentUser?.firstName} ${_currentUser?.lastName}',
        }),
      );

      if (response.statusCode == 200) {
        print('User synced with backend');
      }
    } catch (e) {
      print('Error syncing with backend: $e');
    }
  }

  // Apple Sign-In
  Future<bool> signInWithApple() async {
    try {
      // Trigger Apple Sign-In flow
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Use Apple identity token directly
      _idToken = appleCredential.identityToken;

      if (_idToken == null) {
        print('Failed to get Apple ID token');
        return false;
      }

      // Create user from Apple credential
      final displayName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();

      _currentUser = app_user.User(
        id: appleCredential.userIdentifier ?? '',
        username: appleCredential.email?.split('@')[0] ?? 'user',
        email: appleCredential.email ?? '',
        firstName: appleCredential.givenName ?? '',
        lastName: appleCredential.familyName ?? '',
      );

      _isAuthenticated = true;

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('id_token', _idToken!);
      await prefs.setString('user', json.encode(_currentUser!.toJson()));

      notifyListeners();

      // Sync with backend
      await _syncWithBackend();

      print('Apple Sign-In successful: ${appleCredential.email}');
      return true;
    } catch (e) {
      print('Apple Sign-In error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();

      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id_token');
      await prefs.remove('user');

      _currentUser = null;
      _isAuthenticated = false;
      _idToken = null;
      notifyListeners();
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Refresh token (not needed without Firebase)
  Future<bool> refreshToken() async {
    // Google tokens are long-lived, no refresh needed
    return true;
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final token = await getIdToken();
      if (token == null) return false;

      // Call backend to delete account
      final response = await http.delete(
        Uri.parse('$baseUrl/users/delete/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }
}
