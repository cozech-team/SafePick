import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import 'auth_service.dart';
import 'dart:convert';

class AnalysisService {
  final AuthService _authService;

  AnalysisService(this._authService);

  static String get baseUrl => AuthService.baseUrl;

  /// Analyze ingredients from an image
  Future<AnalysisResult> analyzeIngredients(String imagePath) async {
    try {
      if (!_authService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final token = await _authService.getIdToken();
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
