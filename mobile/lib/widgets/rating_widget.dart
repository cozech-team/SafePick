import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final String rating;
  final bool compact;

  const RatingWidget({
    super.key,
    required this.rating,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratingData = _getRatingData(rating);

    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ratingData.icon, color: ratingData.color, size: 20),
          const SizedBox(width: 4),
          Text(
            ratingData.label,
            style: TextStyle(
              color: ratingData.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ratingData.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ratingData.color, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(ratingData.icon, color: ratingData.color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ratingData.label,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ratingData.color,
                ),
              ),
              Text(
                ratingData.description,
                style: TextStyle(
                  fontSize: 14,
                  color: ratingData.color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _RatingData _getRatingData(String rating) {
    switch (rating.toUpperCase()) {
      case 'BEST':
        return _RatingData(
          label: 'BEST',
          description: 'Excellent choice!',
          color: Colors.green.shade700,
          icon: Icons.star,
        );
      case 'GOOD':
        return _RatingData(
          label: 'GOOD',
          description: 'Good for you',
          color: Colors.green,
          icon: Icons.thumb_up,
        );
      case 'AVERAGE':
        return _RatingData(
          label: 'AVERAGE',
          description: 'Consume in moderation',
          color: Colors.orange,
          icon: Icons.info,
        );
      case 'BAD':
        return _RatingData(
          label: 'BAD',
          description: 'Not recommended',
          color: Colors.deepOrange,
          icon: Icons.warning,
        );
      case 'AVOID':
        return _RatingData(
          label: 'AVOID',
          description: 'Avoid this product',
          color: Colors.red,
          icon: Icons.dangerous,
        );
      default:
        return _RatingData(
          label: 'UNKNOWN',
          description: 'No rating available',
          color: Colors.grey,
          icon: Icons.help,
        );
    }
  }
}

class _RatingData {
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  _RatingData({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });
}
