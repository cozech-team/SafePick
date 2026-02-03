import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Use your production Render URL
  static const String baseUrl = 'https://safepick-1.onrender.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '819106507078-i1u1uq5lvv929tu29htm8ga4psd691lh.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 1. Kick off the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2. Obtain the auth headers from the user
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Send the access token to your Django backend
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/google/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': googleAuth.accessToken}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
