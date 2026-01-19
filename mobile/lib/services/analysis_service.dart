import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import 'auth_service.dart';
import 'dart:convert';

class AnalysisService {
  static String get baseUrl => AuthService.baseUrl;

  /// Analyze ingredients from an image
  Future<AnalysisResult> analyzeIngredients(String imagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final token = await user.getIdToken();
      if (token == null) {
        throw Exception('Failed to get authentication token');
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/analyze-ingredients/'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
        ),
      );

      // Send request
      debugPrint(
          'Sending analysis request to: $baseUrl/users/analyze-ingredients/');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Analysis response status: ${response.statusCode}');
      debugPrint('Analysis response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AnalysisResult.fromJson(jsonData);
      } else {
        throw Exception('Failed to analyze ingredients: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error analyzing ingredients: $e');
      rethrow;
    }
  }
}
