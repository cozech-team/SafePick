import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import '../services/api_service.dart';

class AnalysisProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  AnalysisResult? _currentAnalysis;
  bool _isLoading = false;
  String? _error;
  List<AnalysisResult> _history = [];

  AnalysisResult? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<AnalysisResult> get history => _history;

  /// Analyze ingredients text using backend API
  Future<void> analyzeIngredients(String ingredientsText) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.analyzeIngredients(ingredientsText);

      if (result != null) {
        _currentAnalysis = result;
        _error = null;

        // Add to history
        _history.insert(0, _currentAnalysis!);
        if (_history.length > 20) {
          _history = _history.sublist(0, 20);
        }
      } else {
        _error = 'Failed to analyze ingredients. Please check your connection.';
        _currentAnalysis = null;
      }
    } catch (e) {
      _error = 'Error: $e';
      _currentAnalysis = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch analysis history from backend
  Future<void> fetchHistory() async {
    try {
      final history = await _apiService.getAnalysisHistory();
      _history = history;
      notifyListeners();
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  /// Clear current analysis
  void clearAnalysis() {
    _currentAnalysis = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
