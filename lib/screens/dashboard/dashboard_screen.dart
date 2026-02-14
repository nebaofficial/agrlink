import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../marketplace/create_product_screen.dart';
import '../orders/my_orders_screen.dart';
import '../../services/language_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardScreen extends StatelessWidget {
  final UserModel? currentUser;

  const DashboardScreen({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (currentUser?.role == UserRole.FARMER) {
      return _FarmerDashboard(currentUser: currentUser!);
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final isFarmer = currentUser?.role == UserRole.FARMER;
    final isBuyer = currentUser?.role == UserRole.BUYER;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: const Color(0xFF2D6A4F),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              isFarmer ? 'Your farming business overview' : 'Your marketplace activity',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Metrics Cards
            StreamBuilder<List<ProductModel>>(
              stream: isFarmer 
                ? firestoreService.streamFarmerProducts(currentUser!.uid)
                : firestoreService.streamAllProducts(),
              builder: (context, productSnapshot) {
                return StreamBuilder<List<OrderModel>>(
                  stream: isFarmer 
                    ? firestoreService.streamFarmerOrders(currentUser!.uid)
                    : isBuyer 
                      ? firestoreService.streamBuyerOrders(currentUser!.uid)
                      : const Stream.empty(),
                  builder: (context, orderSnapshot) {
                    final totalProducts = productSnapshot.data?.length ?? 0;
                    final totalOrders = orderSnapshot.data?.length ?? 0;
                    final completedOrders = orderSnapshot.data
                            ?.where((o) => o.status == OrderStatus.COMPLETED)
                            .length ??
                        0;
                    
                    final activeOrders = orderSnapshot.data
                            ?.where((o) => o.status != OrderStatus.COMPLETED && o.status != OrderStatus.CANCELLED)
                            .length ??
                         0;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: isFarmer ? 'My Active Listings' : 'Total Items',
                                value: isFarmer ? productSnapshot.data?.where((p) => p.status == ProductStatus.AVAILABLE).length.toString() ?? '0' : totalProducts.toString(),
                                change: '',
                                changeLabel: '',
                                icon: isFarmer ? Icons.grass : Icons.inventory_2,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Active Orders',
                                value: activeOrders.toString(),
                                change: '',
                                changeLabel: '',
                                icon: Icons.shopping_basket,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Revenue',
                                value: NumberFormat.compact().format(
                                  orderSnapshot.data?.fold<double>(0, (prev, o) => prev + o.totalAmount) ?? 0
                                ),
                                change: '',
                                changeLabel: '',
                                icon: Icons.attach_money,
                                color: const Color(0xFFEC4899),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Completed',
                                value: completedOrders.toString(),
                                change: '',
                                changeLabel: '',
                                icon: Icons.check_circle,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B4332),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _FarmerActionCard(
                icon: Icons.inventory_2_outlined,
                label: AppLocalizations.of(context)!.listNewCrop,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateProductScreen()),
                ),
                color: const Color(0xFF2D6A4F),
                textColor: Colors.white, // Added textColor for consistency
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FarmerActionCard(
                icon: Icons.gavel_outlined,
                label: AppLocalizations.of(context)!.viewOffers,
                onTap: () {},
                color: const Color(0xFF409167),
                textColor: Colors.white, // Added textColor for consistency
              ),
            ),
          ],
        ),
      ],
    ),  const SizedBox(height: 24),

            // Recent Transactions
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2D6A4F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<List<OrderModel>>(
              stream: currentUser?.role == UserRole.FARMER
                  ? firestoreService.streamFarmerOrders(currentUser!.uid)
                  : currentUser?.role == UserRole.BUYER
                      ? firestoreService.streamBuyerOrders(currentUser!.uid)
                      : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                   return Center(child: Text('Error loading transactions: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'No transactions yet',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data!.take(5).toList();

                return Column(
                  children: orders.map((order) {
                    return _TransactionCard(
                      order: order,
                      firestoreService: firestoreService,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerDashboard extends StatelessWidget {
  final UserModel currentUser;

  const _FarmerDashboard({required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final primaryColor = const Color(0xFF2D6A4F);
    final secondaryColor = const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: secondaryColor,
      body: CustomScrollView(
        slivers: [
          // Custom Farmer Header
          SliverToBoxAdapter(
            child: Container(
              color: primaryColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 30,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24), // Spacer for removed menu
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Text('AL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Text('AgriLink', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.language, color: Colors.white),
                            onPressed: () {
                              final langService = Provider.of<LanguageService>(context, listen: false);
                              langService.toggleLanguage();
                            },
                          ),
                          const SizedBox(width: 16),
                          const Badge(
                            label: Text('2'),
                            child: Icon(Icons.notifications_none, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.grass, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.myFarm,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.manageCropsSales,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Stats Grid
                  StreamBuilder<List<ProductModel>>(
                    stream: firestoreService.streamFarmerProducts(currentUser.uid),
                    builder: (context, productSnapshot) {
                      return StreamBuilder<List<OrderModel>>(
                        stream: firestoreService.streamFarmerOrders(currentUser.uid),
                        builder: (context, orderSnapshot) {
                          final products = productSnapshot.data ?? [];
                          final orders = orderSnapshot.data ?? [];

                          final activeListings = products.where((p) => p.status == ProductStatus.AVAILABLE).length;
                          final totalSoldKg = orders.fold<double>(0, (p, o) => p + o.quantityKg);
                          final totalEarnings = orders.fold<double>(0, (p, o) => p + o.totalAmount);
                          final activeBuyers = orders.map((o) => o.buyerId).toSet().length;

                          String volumeStr = totalSoldKg >= 1000 
                            ? '${(totalSoldKg / 1000).toStringAsFixed(1)} tons' 
                            : '${totalSoldKg.toInt()} kg';

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.4,
                            children: [
                              _FarmerStatCard(
                                icon: Icons.inventory_2_outlined,
                                value: activeListings.toString(),
                                label: AppLocalizations.of(context)!.activeListings,
                                subLabel: AppLocalizations.of(context)!.cropsListed,
                              ),
                              _FarmerStatCard(
                                icon: Icons.trending_up,
                                value: volumeStr,
                                label: AppLocalizations.of(context)!.totalSold,
                                subLabel: AppLocalizations.of(context)!.thisSeason,
                              ),
                              _FarmerStatCard(
                                icon: Icons.attach_money,
                                value: '${NumberFormat.compact().format(totalEarnings)} ETB',
                                label: AppLocalizations.of(context)!.earnings,
                                subLabel: AppLocalizations.of(context)!.thisMonth,
                              ),
                              _FarmerStatCard(
                                icon: Icons.people_outline,
                                value: activeBuyers.toString(),
                                label: AppLocalizations.of(context)!.activeBuyers,
                                subLabel: AppLocalizations.of(context)!.connected,
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Quick Actions
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quickActions,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _FarmerActionCard(
                          icon: Icons.inventory_2_outlined,
                          label: AppLocalizations.of(context)!.listNewCrop,
                          color: primaryColor,
                          textColor: Colors.white,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateProductScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FarmerActionCard(
                          icon: Icons.gavel_outlined,
                          label: AppLocalizations.of(context)!.viewOffers,
                          color: const Color(0xFFD8E2DC),
                          textColor: const Color(0xFF1B4332),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MyOrdersScreen(currentUser: currentUser)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // My Crops
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.myCrops,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          AppLocalizations.of(context)!.viewAll,
                          style: const TextStyle(color: Color(0xFF2D6A4F)),
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<List<ProductModel>>(
                    stream: firestoreService.streamFarmerProducts(currentUser.uid),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(child: Text(AppLocalizations.of(context)!.noCropsYet));
                      }
                      return Column(
                        children: snapshot.data!.map((product) => _FarmerCropCard(product: product)).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Recent Activity
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.recentActivity,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<OrderModel>>(
                    stream: firestoreService.streamFarmerOrders(currentUser.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final orders = snapshot.data ?? [];
                      if (orders.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            AppLocalizations.of(context)!.noRecentActivities,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      // Take top 3 most recent
                      final recentOrders = orders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                      final itemsToShow = recentOrders.take(3).toList();

                      return Column(
                        children: itemsToShow.map((order) {
                          final cropName = order.product?.cropName ?? 'Crop';
                          String title = AppLocalizations.of(context)!.orderReceivedFor(cropName);
                          if (order.status == OrderStatus.COMPLETED) {
                            title = AppLocalizations.of(context)!.saleCompleted(cropName);
                          } else if (order.status == OrderStatus.CANCELLED) {
                            title = AppLocalizations.of(context)!.orderCancelled(cropName);
                          }

                          return _ActivityItem(
                            icon: order.status == OrderStatus.COMPLETED ? Icons.trending_up : Icons.attach_money,
                            title: title,
                            subtitle: '${DateFormat('MMM dd').format(order.createdAt)} \u2022 ${NumberFormat.compact().format(order.totalAmount)} ETB',
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Help Banner
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F5FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Need Help?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Connect with field agents or access farming resources and market tips',
                      style: TextStyle(color: Color(0xFF1E40AF)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Get Support'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _FarmerStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String subLabel;

  const _FarmerStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            subLabel,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _FarmerActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _FarmerActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerCropCard extends StatelessWidget {
  final ProductModel product;

  const _FarmerCropCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD8E2DC).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                product.cropName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  product.status == ProductStatus.AVAILABLE ? 'Active' : 'Sold',
                  style: TextStyle(
                    color: product.status == ProductStatus.AVAILABLE ? Colors.green : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${product.quantityKg.toInt()} kg \u2022 ${product.pricePerKg.toInt()} ETB/kg',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.remove_red_eye, size: 14, color: Colors.brown),
              const SizedBox(width: 4),
              const Text('18 views', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.shopping_bag, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              const Text('2 offers', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD8E2DC).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}


class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final String changeLabel;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.change,
    required this.changeLabel,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$change $changeLabel',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: const Color(0xFF2D6A4F)),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final OrderModel order;
  final FirestoreService firestoreService;

  const _TransactionCard({
    required this.order,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return FutureBuilder<ProductModel?>(
      future: firestoreService.getProduct(order.productId),
      builder: (context, productSnapshot) {
        final productName = productSnapshot.data?.cropName ?? 'Loading...';

        return FutureBuilder<UserModel?>(
          future: firestoreService.getUser(order.farmerId),
          builder: (context, farmerSnapshot) {
            final farmerName = farmerSnapshot.data?.fullName ?? '';

            return FutureBuilder<UserModel?>(
              future: firestoreService.getUser(order.buyerId),
              builder: (context, buyerSnapshot) {
                final buyerName = buyerSnapshot.data?.fullName ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: order.status == OrderStatus.COMPLETED
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status == OrderStatus.COMPLETED
                                    ? 'Completed'
                                    : 'In Transit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: order.status == OrderStatus.COMPLETED
                                      ? const Color(0xFF166534)
                                      : const Color(0xFF1E40AF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (farmerName.isNotEmpty)
                          Text(
                            farmerName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Buyer',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                            Text(
                              'Amount',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              buyerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              currencyFormat.format(order.totalAmount),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D6A4F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
