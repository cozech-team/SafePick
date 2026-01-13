import 'package:flutter/material.dart';
import '../models/ingredient.dart';

class IngredientList extends StatelessWidget {
  final List<Ingredient> ingredients;

  const IngredientList({super.key, required this.ingredients});

  @override
  Widget build(BuildContext context) {
    if (ingredients.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No ingredient information available'),
        ),
      );
    }

    return Column(
      children: ingredients.map((ingredient) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getSafetyColor(ingredient.safetyRating),
              child: Icon(
                _getSafetyIcon(ingredient.safetyRating),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(ingredient.name),
            subtitle: ingredient.description.isNotEmpty
                ? Text(
                    ingredient.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Chip(
              label: Text(
                ingredient.safetyRating,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _getSafetyColor(
                ingredient.safetyRating,
              ).withOpacity(0.2),
            ),
            onTap: () {
              _showIngredientDetails(context, ingredient);
            },
          ),
        );
      }).toList(),
    );
  }

  Color _getSafetyColor(String rating) {
    switch (rating) {
      case 'SAFE':
        return Colors.green;
      case 'CAUTION':
        return Colors.orange;
      case 'AVOID':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getSafetyIcon(String rating) {
    switch (rating) {
      case 'SAFE':
        return Icons.check_circle;
      case 'CAUTION':
        return Icons.warning;
      case 'AVOID':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showIngredientDetails(BuildContext context, Ingredient ingredient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  Chip(
                    label: Text(ingredient.safetyRating),
                    backgroundColor: _getSafetyColor(ingredient.safetyRating),
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (ingredient.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(ingredient.description),
                const SizedBox(height: 16),
              ],
              if (ingredient.healthConcerns.isNotEmpty) ...[
                Text(
                  'Health Concerns',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...ingredient.healthConcerns.map(
                  (concern) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(concern)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (ingredient.allergenInfo.isNotEmpty) ...[
                Text(
                  'Allergen Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(ingredient.allergenInfo),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
