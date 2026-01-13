import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: product.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image_not_supported);
                          },
                        ),
                      )
                    : const Icon(Icons.shopping_bag),
              ),
              const SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (product.safetyScore != null) ...[
                          Icon(
                            _getSafetyIcon(product.safetyScore!),
                            size: 16,
                            color: _getSafetyColor(product.safetyScore!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.safetyScore!.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: _getSafetyColor(product.safetyScore!),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (product.verified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSafetyIcon(double score) {
    if (score >= 75) return Icons.check_circle;
    if (score >= 50) return Icons.warning;
    return Icons.cancel;
  }

  Color _getSafetyColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }
}
