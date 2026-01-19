class AnalysisResult {
  final int safetyScore;
  final List<String> goodIngredients;
  final List<String> badIngredients;
  final String explanation;

  AnalysisResult({
    required this.safetyScore,
    required this.goodIngredients,
    required this.badIngredients,
    required this.explanation,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      safetyScore: json['safety_score'] ?? 0,
      goodIngredients: List<String>.from(json['good_ingredients'] ?? []),
      badIngredients: List<String>.from(json['bad_ingredients'] ?? []),
      explanation: json['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'safety_score': safetyScore,
      'good_ingredients': goodIngredients,
      'bad_ingredients': badIngredients,
      'explanation': explanation,
    };
  }
}
