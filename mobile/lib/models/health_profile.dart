class HealthProfile {
  final String id;
  final List<String> allergies;
  final List<String> dietaryRestrictions;
  final List<String> healthConditions;
  final List<String> avoidIngredients;
  final List<String> preferredCategories;
  final bool notificationEnabled;
  final bool scanReminder;

  HealthProfile({
    required this.id,
    this.allergies = const [],
    this.dietaryRestrictions = const [],
    this.healthConditions = const [],
    this.avoidIngredients = const [],
    this.preferredCategories = const [],
    this.notificationEnabled = true,
    this.scanReminder = true,
  });

  factory HealthProfile.fromJson(Map<String, dynamic> json) {
    return HealthProfile(
      id: json['id'].toString(),
      allergies: List<String>.from(json['allergies'] ?? []),
      dietaryRestrictions: List<String>.from(
        json['dietary_restrictions'] ?? [],
      ),
      healthConditions: List<String>.from(json['health_conditions'] ?? []),
      avoidIngredients: List<String>.from(json['avoid_ingredients'] ?? []),
      preferredCategories: List<String>.from(
        json['preferred_categories'] ?? [],
      ),
      notificationEnabled: json['notification_enabled'] ?? true,
      scanReminder: json['scan_reminder'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergies': allergies,
      'dietary_restrictions': dietaryRestrictions,
      'health_conditions': healthConditions,
      'avoid_ingredients': avoidIngredients,
      'preferred_categories': preferredCategories,
      'notification_enabled': notificationEnabled,
      'scan_reminder': scanReminder,
    };
  }

  HealthProfile copyWith({
    String? id,
    List<String>? allergies,
    List<String>? dietaryRestrictions,
    List<String>? healthConditions,
    List<String>? avoidIngredients,
    List<String>? preferredCategories,
    bool? notificationEnabled,
    bool? scanReminder,
  }) {
    return HealthProfile(
      id: id ?? this.id,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      healthConditions: healthConditions ?? this.healthConditions,
      avoidIngredients: avoidIngredients ?? this.avoidIngredients,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      scanReminder: scanReminder ?? this.scanReminder,
    );
  }
}
