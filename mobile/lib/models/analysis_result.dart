class AnalysisResult {
  final int totalIngredients;
  final String overallRating;
  final double overallScore;
  final List<IngredientDetail> goodIngredients;
  final List<IngredientDetail> badIngredients;
  final List<IngredientDetail> neutralIngredients;
  final String recommendation;
  final List<String> allergenWarnings;
  final List<String> healthConcerns;
  final bool fromCache;
  final double processingTime;

  AnalysisResult({
    required this.totalIngredients,
    required this.overallRating,
    required this.overallScore,
    required this.goodIngredients,
    required this.badIngredients,
    required this.neutralIngredients,
    required this.recommendation,
    required this.allergenWarnings,
    required this.healthConcerns,
    this.fromCache = false,
    this.processingTime = 0.0,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      totalIngredients: json['total_ingredients'] ?? 0,
      overallRating: json['overall_rating'] ?? 'UNKNOWN',
      overallScore: (json['overall_score'] ?? 0).toDouble(),
      goodIngredients: (json['good_ingredients'] as List<dynamic>?)
              ?.map((e) => IngredientDetail.fromJson(e))
              .toList() ??
          [],
      badIngredients: (json['bad_ingredients'] as List<dynamic>?)
              ?.map((e) => IngredientDetail.fromJson(e))
              .toList() ??
          [],
      neutralIngredients: (json['neutral_ingredients'] as List<dynamic>?)
              ?.map((e) => IngredientDetail.fromJson(e))
              .toList() ??
          [],
      recommendation: json['recommendation'] ?? '',
      allergenWarnings: List<String>.from(json['allergen_warnings'] ?? []),
      healthConcerns: List<String>.from(json['health_concerns'] ?? []),
      fromCache: json['from_cache'] ?? false,
      processingTime: (json['processing_time'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_ingredients': totalIngredients,
      'overall_rating': overallRating,
      'overall_score': overallScore,
      'good_ingredients': goodIngredients.map((e) => e.toJson()).toList(),
      'bad_ingredients': badIngredients.map((e) => e.toJson()).toList(),
      'neutral_ingredients': neutralIngredients.map((e) => e.toJson()).toList(),
      'recommendation': recommendation,
      'allergen_warnings': allergenWarnings,
      'health_concerns': healthConcerns,
      'from_cache': fromCache,
      'processing_time': processingTime,
    };
  }
}

class IngredientDetail {
  final String name;
  final String category;
  final String healthImpact;
  final String description;

  IngredientDetail({
    required this.name,
    required this.category,
    required this.healthImpact,
    required this.description,
  });

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    return IngredientDetail(
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      healthImpact: json['health_impact'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'health_impact': healthImpact,
      'description': description,
    };
  }
}
