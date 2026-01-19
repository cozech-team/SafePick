import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
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

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '819106507078-i1u1uq5lvv929tu29htm8ga4psd691lh.apps.googleusercontent.com'
        : null,
    scopes: ['email', 'profile'],
  );

  app_user.User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  app_user.User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isInitialized => _isInitialized;
  firebase_auth.User? get firebaseUser => _firebaseAuth.currentUser;

  AuthService() {
    init();
  }

  // Initialize and check if user is logged in
  Future<void> init() async {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen((firebase_auth.User? user) {
      if (user != null) {
        _updateUserFromFirebase(user);
      } else {
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
      }
    });

    // Check if user is already signed in
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await _updateUserFromFirebase(user);
    }

    _isInitialized = true;
    notifyListeners();
  }

  // Update local user from Firebase user
  Future<void> _updateUserFromFirebase(firebase_auth.User firebaseUser) async {
    _currentUser = app_user.User(
      id: firebaseUser.uid,
      username: firebaseUser.displayName ??
          firebaseUser.email?.split('@')[0] ??
          'user',
      email: firebaseUser.email ?? '',
      firstName: firebaseUser.displayName?.split(' ').first ?? '',
      lastName: (firebaseUser.displayName?.split(' ').length ?? 0) > 1
          ? firebaseUser.displayName!.split(' ').last
          : '',
    );
    _isAuthenticated = true;
    notifyListeners();

    // Sync with backend (don't await to avoid blocking UI)
    _syncWithBackend();
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

  // Get Firebase ID token for backend authentication
  Future<String?> getIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
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

      // Create Firebase credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        print('Google Sign-In successful: ${userCredential.user?.email}');
        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign-In error: $e');
      return false;
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

      // Create Firebase credential
      final oAuthProvider = firebase_auth.OAuthProvider('apple.com');
      final credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Update display name if provided (Apple only provides this on first sign-in)
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }

      if (userCredential.user != null) {
        print('Apple Sign-In successful: ${userCredential.user?.email}');
        return true;
      }

      return false;
    } catch (e) {
      print('Apple Sign-In error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
      print('User logged out successfully');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Refresh token (Firebase handles this automatically)
  Future<bool> refreshToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force refresh
        return true;
      }
      return false;
    } catch (e) {
      print('Token refresh error: $e');
      return false;
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
        _currentUser = null;
        _isAuthenticated = false;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Delete account error: $e');
      return false;
    }
  }
}
