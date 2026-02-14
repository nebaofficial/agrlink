import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../widgets/product_card.dart';
import '../marketplace/product_detail_screen.dart';
import 'create_product_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _searchQuery = '';
  ProductStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.marketplaceTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: const Color(0xFF2D6A4F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              AppLocalizations.of(context)!.marketplaceSubtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchCrops,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      _showFilterBottomSheet();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: firestoreService.streamAvailableProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter products
                var products = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  products = products.where((product) {
                    return product.cropName.toLowerCase().contains(_searchQuery) ||
                        (product.location?.toLowerCase().contains(_searchQuery) ?? false);
                  }).toList();
                }

                if (_selectedStatus != null) {
                  products = products.where((product) {
                    return product.status == _selectedStatus;
                  }).toList();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${products.length} listings available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<UserModel?>(
        future: Provider.of<AuthService>(context, listen: false).getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.role == UserRole.FARMER) {
            return FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateProductScreen()),
                );
              },
              backgroundColor: const Color(0xFF2D6A4F),
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context)!.filterProducts,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(AppLocalizations.of(context)!.all),
                    selected: _selectedStatus == null,
                    onSelected: (_) {
                      setState(() => _selectedStatus = null);
                      Navigator.pop(context);
                    },
                  ),
                  ...ProductStatus.values.map((status) {
                    String statusLabel = '';
                    switch (status) {
                      case ProductStatus.AVAILABLE:
                        statusLabel = AppLocalizations.of(context)!.statusAvailable;
                        break;
                      case ProductStatus.RESERVED:
                        statusLabel = AppLocalizations.of(context)!.statusReserved;
                        break;
                      case ProductStatus.SOLD:
                        statusLabel = AppLocalizations.of(context)!.statusSold;
                        break;
                      case ProductStatus.UNAVAILABLE:
                        statusLabel = 'Unavailable'; // Add if needed
                        break;
                    }
                    return FilterChip(
                      label: Text(statusLabel),
                      selected: _selectedStatus == status,
                      onSelected: (_) {
                        setState(() => _selectedStatus = status);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
