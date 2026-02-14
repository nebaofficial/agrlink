import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../widgets/status_badge.dart';
import 'create_product_screen.dart';
import '../orders/create_order_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        final isOwner = currentUser?.uid == product.farmerId;
        final isAdmin = currentUser?.role == UserRole.ADMIN;
        final isBuyer = currentUser?.role == UserRole.BUYER;
        final isFarmer = currentUser?.role == UserRole.FARMER;

        // Can edit if they are the owner OR an admin
        final canEdit = (isOwner && isFarmer) || isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.productDetails),
            actions: canEdit
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateProductScreen(productToEdit: product),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(AppLocalizations.of(context)!.deleteProduct),
                            content: Text(AppLocalizations.of(context)!.deleteConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: Text(AppLocalizations.of(context)!.delete),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await firestoreService.deleteProduct(product.id);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context)!.productDeleted)),
                            );
                          }
                        }
                      },
                    ),
                  ]
                : null,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Container(
                  height: 250,
                  color: const Color(0xFFE5E7EB),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                        )
                      : Center(
                          child: Icon(
                            Icons.agriculture,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      StatusBadge(
                        status: product.status.value,
                        type: StatusType.product,
                      ),
                      const SizedBox(height: 16),

                      // Product Name
                      Text(
                        product.cropName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location
                      if (product.location != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Color(0xFF6B7280)),
                            const SizedBox(width: 4),
                            Text(
                              product.location!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Description
                      if (product.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Details Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildDetailRow('Quantity Available', '${product.quantityKg.toStringAsFixed(0)} kg'),
                              const Divider(height: 24),
                              _buildDetailRow('Min. Order', '${product.minOrderKg.toStringAsFixed(0)} kg'),
                              const Divider(height: 24),
                              if (product.harvestDate != null)
                                _buildDetailRow('Harvest Date', dateFormat.format(product.harvestDate!)),
                              if (product.harvestDate != null) const Divider(height: 24),
                              _buildDetailRow('Price per kg', currencyFormat.format(product.pricePerKg)),
                              const Divider(height: 24),
                              _buildDetailRow(
                                'Total Price',
                                currencyFormat.format(product.totalPrice),
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Farmer Info
                      FutureBuilder<UserModel?>(
                        future: firestoreService.getUser(product.farmerId),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final farmer = snapshot.data!;
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Farmer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: const Color(0xFF2D6A4F),
                                        child: Text(
                                          farmer.fullName[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              farmer.fullName,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (farmer.isVerified)
                                              const Row(
                                                children: [
                                                  Icon(
                                                    Icons.verified,
                                                    size: 16,
                                                    color: Color(0xFF2D6A4F),
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Verified Farmer',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF2D6A4F),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: (product.status == ProductStatus.AVAILABLE && isBuyer && !isOwner)
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateOrderScreen(product: product),
                          ),
                        );
                      },
                      child: const Text('Place Order'),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 20 : 16,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? const Color(0xFF2D6A4F) : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
