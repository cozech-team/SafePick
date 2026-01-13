class Ingredient {
  final String id;
  final String name;
  final List<String> alternativeNames;
  final String description;
  final String safetyRating; // SAFE, CAUTION, AVOID
  final List<String> healthConcerns;
  final String allergenInfo;

  Ingredient({
    required this.id,
    required this.name,
    this.alternativeNames = const [],
    this.description = '',
    required this.safetyRating,
    this.healthConcerns = const [],
    this.allergenInfo = '',
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      alternativeNames: List<String>.from(json['alternative_names'] ?? []),
      description: json['description'] ?? '',
      safetyRating: json['safety_rating'] ?? 'SAFE',
      healthConcerns: List<String>.from(json['health_concerns'] ?? []),
      allergenInfo: json['allergen_info'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alternative_names': alternativeNames,
      'description': description,
      'safety_rating': safetyRating,
      'health_concerns': healthConcerns,
      'allergen_info': allergenInfo,
    };
  }
}
