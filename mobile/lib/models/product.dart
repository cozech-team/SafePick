import 'ingredient.dart';

class Product {
  final String id;
  final String barcode;
  final String name;
  final String brand;
  final String category;
  final String description;
  final String imageUrl;
  final String ingredientsText;
  final List<Ingredient> ingredients;
  final Map<String, dynamic> nutritionalInfo;
  final double? safetyScore;
  final double? averageRating;
  final bool verified;

  Product({
    required this.id,
    required this.barcode,
    required this.name,
    this.brand = '',
    this.category = '',
    this.description = '',
    this.imageUrl = '',
    this.ingredientsText = '',
    this.ingredients = const [],
    this.nutritionalInfo = const {},
    this.safetyScore,
    this.averageRating,
    this.verified = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      barcode: json['barcode'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      ingredientsText: json['ingredients_text'] ?? '',
      ingredients:
          (json['ingredients_detail'] as List<dynamic>?)
              ?.map((i) => Ingredient.fromJson(i))
              .toList() ??
          [],
      nutritionalInfo: json['nutritional_info'] ?? {},
      safetyScore: json['safety_score']?.toDouble(),
      averageRating: json['average_rating']?.toDouble(),
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barcode': barcode,
      'name': name,
      'brand': brand,
      'category': category,
      'description': description,
      'image_url': imageUrl,
      'ingredients_text': ingredientsText,
      'nutritional_info': nutritionalInfo,
      'verified': verified,
    };
  }
}
