import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    // For Web: use localhost
    if (kIsWeb) return 'http://localhost:8000/api';

    // For Android Emulator: use 10.0.2.2 (special alias for host machine)
    // For Physical Device: use your computer's local IP address
    // Make sure your phone and computer are on the same WiFi network

    // IP address from ipconfig: 192.168.1.4
    // To find your IP: Run 'ipconfig' in terminal and look for IPv4 Address
    return 'http://192.168.1.4:8000/api';
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
