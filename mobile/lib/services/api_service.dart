import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/ingredient.dart';
import '../models/analysis_result.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000/api';
    return 'http://localhost:8000/api';
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

  // Analysis
  Future<AnalysisResult?> analyzeIngredients(String ingredientsText) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/analysis/analyze/'),
        headers: headers,
        body: json.encode({'ingredients_text': ingredientsText}),
      );

      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error analyzing ingredients: $e');
      return null;
    }
  }

  Future<List<AnalysisResult>> getAnalysisHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/analysis/history/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((e) => AnalysisResult.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching analysis history: $e');
      return [];
    }
  }

  // Products
  Future<Product?> getProductByBarcode(String barcode) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products/scan/$barcode'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  Future<List<Product>> getProducts({String? search}) async {
    try {
      final headers = await _getHeaders();
      // Changed from /products/ to /analysis/history/ to match backend
      var url = '$baseUrl/analysis/history/';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((p) => Product.fromJson(p)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Ingredients
  Future<List<Ingredient>> getIngredients({String? search}) async {
    try {
      final headers = await _getHeaders();
      var url = '$baseUrl/ingredients/';
      if (search != null && search.isNotEmpty) {
        url += '?search=$search';
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results.map((i) => Ingredient.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ingredients: $e');
      return [];
    }
  }

  Future<Ingredient?> getIngredient(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/ingredients/$id/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Ingredient.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching ingredient: $e');
      return null;
    }
  }

  // Health Profile
  Future<Map<String, dynamic>?> checkProductSafety(String productId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/health-profile/check_product/'),
        headers: headers,
        body: json.encode({'product_id': productId}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error checking product safety: $e');
      return null;
    }
  }
}
