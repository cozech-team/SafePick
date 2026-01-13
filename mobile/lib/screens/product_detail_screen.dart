import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../widgets/ingredient_list.dart';
import '../widgets/safety_indicator.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ApiService _apiService = ApiService();
  Product? _product;
  Map<String, dynamic>? _safetyCheck;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() => _isLoading = true);

    // Load product details
    final products = await _apiService.getProducts();
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => products.first,
    );

    // Check safety for user
    final safetyCheck = await _apiService.checkProductSafety(widget.productId);

    setState(() {
      _product = product;
      _safetyCheck = safetyCheck;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_product!.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_product!.imageUrl.isNotEmpty)
              Image.network(
                _product!.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            if (_product!.brand.isNotEmpty)
                              Text(
                                _product!.brand,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                          ],
                        ),
                      ),
                      if (_product!.verified)
                        const Chip(
                          label: Text('Verified'),
                          avatar: Icon(Icons.verified, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SafetyIndicator(
                    safetyScore: _product!.safetyScore,
                    safetyCheck: _safetyCheck,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ingredients',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  IngredientList(ingredients: _product!.ingredients),
                  const SizedBox(height: 24),
                  if (_product!.description.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_product!.description),
                    const SizedBox(height: 24),
                  ],
                  if (_product!.nutritionalInfo.isNotEmpty) ...[
                    Text(
                      'Nutritional Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: _product!.nutritionalInfo.entries
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(entry.value.toString()),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
