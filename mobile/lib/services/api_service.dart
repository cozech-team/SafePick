import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    // Production backend on Render
    return 'https://safepick-1.onrender.com/api';

    // For local development, uncomment and use one of these:
    // if (kIsWeb) return 'http://localhost:8000/api';  // Web
    // return 'http://10.0.2.2:8000/api';  // Android Emulator
    // return 'http://192.168.1.4:8000/api';  // Physical Device
  }

  // Get headers with authentication token
  Future<Map<String, String>> _getHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Add any future API methods here
}
