import 'package:flutter/material.dart';

class SafetyIndicator extends StatelessWidget {
  final double? safetyScore;
  final Map<String, dynamic>? safetyCheck;

  const SafetyIndicator({super.key, this.safetyScore, this.safetyCheck});

  @override
  Widget build(BuildContext context) {
    final bool isSafe = safetyCheck?['is_safe'] ?? true;
    final List warnings = safetyCheck?['warnings'] ?? [];

    return Card(
      color: _getBackgroundColor(isSafe, safetyScore),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIcon(isSafe, safetyScore),
                  size: 32,
                  color: _getIconColor(isSafe, safetyScore),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(isSafe, safetyScore),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getIconColor(isSafe, safetyScore),
                        ),
                      ),
                      if (safetyScore != null)
                        Text(
                          'Safety Score: ${safetyScore!.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Warnings for your health profile:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getWarningIcon(warning['type']),
                        size: 20,
                        color: _getWarningSeverityColor(warning['severity']),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              warning['ingredient'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (warning['condition'] != null)
                              Text('Condition: ${warning['condition']}'),
                            Text(
                              _getWarningTypeLabel(warning['type']),
                              style: TextStyle(
                                color: _getWarningSeverityColor(
                                  warning['severity'],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isSafe, double? score) {
    if (!isSafe) return Colors.red.shade50;
    if (score == null) return Colors.grey.shade100;
    if (score >= 75) return Colors.green.shade50;
    if (score >= 50) return Colors.orange.shade50;
    return Colors.red.shade50;
  }

  IconData _getIcon(bool isSafe, double? score) {
    if (!isSafe) return Icons.dangerous;
    if (score == null) return Icons.help;
    if (score >= 75) return Icons.check_circle;
    if (score >= 50) return Icons.warning;
    return Icons.cancel;
  }

  Color _getIconColor(bool isSafe, double? score) {
    if (!isSafe) return Colors.red;
    if (score == null) return Colors.grey;
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getTitle(bool isSafe, double? score) {
    if (!isSafe) return 'Not Safe for You';
    if (score == null) return 'Safety Unknown';
    if (score >= 75) return 'Safe';
    if (score >= 50) return 'Use with Caution';
    return 'Avoid';
  }

  IconData _getWarningIcon(String type) {
    switch (type) {
      case 'ALLERGY':
        return Icons.warning_amber;
      case 'AVOID':
        return Icons.block;
      case 'HEALTH_CONDITION':
        return Icons.local_hospital;
      default:
        return Icons.info;
    }
  }

  Color _getWarningSeverityColor(String severity) {
    switch (severity) {
      case 'HIGH':
      case 'AVOID':
        return Colors.red;
      case 'MEDIUM':
      case 'CAUTION':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getWarningTypeLabel(String type) {
    switch (type) {
      case 'ALLERGY':
        return 'Allergen Alert';
      case 'AVOID':
        return 'Ingredient to Avoid';
      case 'HEALTH_CONDITION':
        return 'Health Concern';
      default:
        return 'Warning';
    }
  }
}
