import 'package:flutter/material.dart';
import '../models/analysis_result.dart';

enum IngredientType { good, bad, neutral }

class IngredientCard extends StatelessWidget {
  final IngredientDetail ingredient;
  final IngredientType type;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final cardData = _getCardData(type);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(cardData.icon, color: cardData.color),
        title: Text(
          ingredient.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          ingredient.category,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.health_and_safety,
                        size: 16, color: cardData.color),
                    const SizedBox(width: 8),
                    Text(
                      'Health Impact: ${ingredient.healthImpact}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: cardData.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(ingredient.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _CardData _getCardData(IngredientType type) {
    switch (type) {
      case IngredientType.good:
        return _CardData(
          icon: Icons.check_circle,
          color: Colors.green,
        );
      case IngredientType.bad:
        return _CardData(
          icon: Icons.cancel,
          color: Colors.red,
        );
      case IngredientType.neutral:
        return _CardData(
          icon: Icons.remove_circle,
          color: Colors.grey,
        );
    }
  }
}

class _CardData {
  final IconData icon;
  final Color color;

  _CardData({required this.icon, required this.color});
}
