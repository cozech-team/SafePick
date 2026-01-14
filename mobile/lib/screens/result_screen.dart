import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analysis_provider.dart';
import '../widgets/rating_widget.dart';
import '../widgets/ingredient_card.dart';
import '../widgets/score_gauge.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.green,
      ),
      body: Consumer<AnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final analysis = provider.currentAnalysis;
          if (analysis == null) {
            return const Center(child: Text('No analysis available'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score Gauge
                ScoreGauge(score: analysis.overallScore),
                const SizedBox(height: 24),

                // Rating
                RatingWidget(rating: analysis.overallRating),
                const SizedBox(height: 24),

                // Cache indicator
                if (analysis.fromCache)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Instant result from cache (${(analysis.processingTime * 1000).toStringAsFixed(0)}ms)',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Recommendation
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recommendation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(analysis.recommendation),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Allergen Warnings
                if (analysis.allergenWarnings.isNotEmpty) ...[
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Allergen Warnings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...analysis.allergenWarnings
                              .map((w) => Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('• $w'),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Good Ingredients
                if (analysis.goodIngredients.isNotEmpty) ...[
                  const Text(
                    'Good Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.goodIngredients
                      .map((ing) => IngredientCard(
                            ingredient: ing,
                            type: IngredientType.good,
                          ))
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Bad Ingredients
                if (analysis.badIngredients.isNotEmpty) ...[
                  const Text(
                    'Bad Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.badIngredients
                      .map((ing) => IngredientCard(
                            ingredient: ing,
                            type: IngredientType.bad,
                          ))
                      .toList(),
                  const SizedBox(height: 16),
                ],

                // Neutral Ingredients
                if (analysis.neutralIngredients.isNotEmpty) ...[
                  const Text(
                    'Neutral Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...analysis.neutralIngredients
                      .map((ing) => IngredientCard(
                            ingredient: ing,
                            type: IngredientType.neutral,
                          ))
                      .toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
