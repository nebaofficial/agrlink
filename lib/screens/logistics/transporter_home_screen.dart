import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../widgets/app_branded_header.dart';
import '../profile/profile_screen.dart';

/// Full transporter experience with 5-tab bottom navigation.
class TransporterHomeScreen extends StatefulWidget {
  final UserModel? currentUser;
  const TransporterHomeScreen({super.key, this.currentUser});

  @override
  State<TransporterHomeScreen> createState() => _TransporterHomeScreenState();
}

class _TransporterHomeScreenState extends State<TransporterHomeScreen> {
  int _currentTab = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _DashboardTab(currentUser: widget.currentUser),
      _JobsTab(currentUser: widget.currentUser),
      _DeliveriesTab(currentUser: widget.currentUser),
      _EarningsTab(currentUser: widget.currentUser),
      ProfileScreen(currentUser: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D6A4F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), activeIcon: Icon(Icons.work), label: 'Jobs'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Deliveries'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final UserModel? currentUser;
  const _DashboardTab({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppBrandedHeader(
              greeting: 'Hello, ${currentUser?.fullName ?? 'Driver'}',
              subtitle: 'Manage your deliveries',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<DeliveryModel>>(
                stream: firestore.streamTransporterDeliveries(uid),
                builder: (context, snap) {
                  final deliveries = snap.data ?? [];
                  final active = deliveries.where((d) => d.status == DeliveryStatus.ASSIGNED || d.status == DeliveryStatus.PICKED_UP || d.status == DeliveryStatus.IN_TRANSIT).length;
                  final completed = deliveries.where((d) => d.status == DeliveryStatus.DELIVERED || d.status == DeliveryStatus.CONFIRMED).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatCard(icon: Icons.local_shipping, value: '$active', label: 'Active Jobs', color: const Color(0xFF3B82F6)),
                          const SizedBox(width: 12),
                          _StatCard(icon: Icons.check_circle, value: '$completed', label: 'Completed', color: const Color(0xFF10B981)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(icon: Icons.list_alt, value: '${deliveries.length}', label: 'Total Jobs', color: const Color(0xFF8B5CF6)),
                          const SizedBox(width: 12),
                          StreamBuilder<List<DeliveryModel>>(
                            stream: firestore.streamAvailableDeliveries(),
                            builder: (context, availSnap) {
                              final avail = availSnap.data?.length ?? 0;
                              return _StatCard(icon: Icons.work_outline, value: '$avail', label: 'Available', color: const Color(0xFFEC4899));
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Tips', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFE9F5FF), borderRadius: BorderRadius.circular(14)),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [Icon(Icons.lightbulb_outline, color: Color(0xFF2563EB), size: 18), SizedBox(width: 8), Text('How it works', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)))]),
                        SizedBox(height: 8),
                        Text('• Go to Jobs tab to see available deliveries', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
                        Text('• Accept a job to get assigned', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
                        Text('• Update your status as you pickup & deliver', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
                        Text('• View your earnings in the Earnings tab', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — AVAILABLE JOBS
// ═══════════════════════════════════════════════════════════════════════════════

class _JobsTab extends StatelessWidget {
  final UserModel? currentUser;
  const _JobsTab({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('Available Jobs'), backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white),
      body: StreamBuilder<List<DeliveryModel>>(
        stream: firestore.streamAvailableDeliveries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No available jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('New delivery jobs will appear here', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _JobCard(delivery: snapshot.data![index], currentUser: currentUser!, firestore: firestore);
            },
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final DeliveryModel delivery;
  final UserModel currentUser;
  final FirestoreService firestore;
  const _JobCard({required this.delivery, required this.currentUser, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: firestore.getOrder(delivery.orderId),
      builder: (context, orderSnap) {
        final order = orderSnap.data;
        return FutureBuilder<ProductModel?>(
          future: order != null ? firestore.getProduct(order.productId) : Future.value(null),
          builder: (context, prodSnap) {
            final product = prodSnap.data;
            final cropName = product?.cropName ?? 'Loading...';
            final qty = order?.quantityKg.toStringAsFixed(0) ?? '...';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD8F3DC), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.grass, color: Color(0xFF2D6A4F), size: 20)),
                        const SizedBox(width: 10),
                        Text(cropName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                        child: const Text('AVAILABLE', style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _infoLine(Icons.scale, 'Quantity: $qty kg'),
                  const SizedBox(height: 6),
                  _infoLine(Icons.location_on, 'Pickup: ${delivery.pickupLocation.isNotEmpty ? delivery.pickupLocation : "Farm"}'),
                  const SizedBox(height: 6),
                  _infoLine(Icons.pin_drop, 'Drop-off: ${delivery.dropoffLocation}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept Job'),
                      onPressed: () => _accept(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A4F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
      ],
    );
  }

  Future<void> _accept(BuildContext context) async {
    try {
      final latest = await firestore.getDeliveryByOrderId(delivery.orderId);
      if (latest != null && latest.transporterId != null && latest.transporterId!.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Already taken by another transporter'), backgroundColor: Colors.orange));
        }
        return;
      }
      final updated = delivery.copyWith(transporterId: currentUser.uid, status: DeliveryStatus.ASSIGNED);
      await firestore.updateDelivery(updated);

      // Also update order status to IN_TRANSIT
      final order = await firestore.getOrder(delivery.orderId);
      if (order != null && (order.status == OrderStatus.PAID || order.status == OrderStatus.ACCEPTED)) {
        final updatedOrder = order.copyWith(status: OrderStatus.IN_TRANSIT);
        await firestore.updateOrder(updatedOrder);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Delivery job accepted!'), backgroundColor: Color(0xFF2D6A4F)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — MY DELIVERIES
// ═══════════════════════════════════════════════════════════════════════════════

class _DeliveriesTab extends StatelessWidget {
  final UserModel? currentUser;
  const _DeliveriesTab({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: const Text('My Deliveries'), backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white),
      body: StreamBuilder<List<DeliveryModel>>(
        stream: firestore.streamTransporterDeliveries(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No deliveries yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Accept a job from "Jobs" tab to start', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _MyDeliveryCard(delivery: snapshot.data![index], firestore: firestore);
            },
          );
        },
      ),
    );
  }
}

class _MyDeliveryCard extends StatelessWidget {
  final DeliveryModel delivery;
  final FirestoreService firestore;
  const _MyDeliveryCard({required this.delivery, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: firestore.getOrder(delivery.orderId),
      builder: (context, orderSnap) {
        final order = orderSnap.data;
        return FutureBuilder<ProductModel?>(
          future: order != null ? firestore.getProduct(order.productId) : Future.value(null),
          builder: (context, prodSnap) {
            final cropName = prodSnap.data?.cropName ?? '...';
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cropName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      _statusTag(delivery.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF2D6A4F)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(delivery.pickupLocation, style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 14, color: Color(0xFF2D6A4F))),
                      Expanded(child: Text(delivery.dropoffLocation, style: TextStyle(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildActions(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusTag(DeliveryStatus status) {
    final (text, bg, fg) = switch (status) {
      DeliveryStatus.ASSIGNED  => ('ASSIGNED', const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      DeliveryStatus.PICKED_UP => ('PICKED UP', const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
      DeliveryStatus.IN_TRANSIT=> ('IN TRANSIT', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      DeliveryStatus.DELIVERED => ('DELIVERED', const Color(0xFFDCFCE7), const Color(0xFF059669)),
      DeliveryStatus.CONFIRMED => ('CONFIRMED', const Color(0xFFD8F3DC), const Color(0xFF2D6A4F)),
      _ => ('PENDING', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (delivery.status == DeliveryStatus.DELIVERED || delivery.status == DeliveryStatus.CONFIRMED) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.update, size: 18),
        label: const Text('Update Status'),
        onPressed: () => _showStatusDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    final nextStatuses = <(DeliveryStatus, String, IconData, Color)>[];

    if (delivery.status == DeliveryStatus.ASSIGNED) {
      nextStatuses.add((DeliveryStatus.PICKED_UP, 'Confirm Pickup', Icons.inventory_2, const Color(0xFF7C3AED)));
    }
    if (delivery.status == DeliveryStatus.PICKED_UP) {
      nextStatuses.add((DeliveryStatus.IN_TRANSIT, 'Mark In Transit', Icons.local_shipping, const Color(0xFFD97706)));
    }
    if (delivery.status == DeliveryStatus.PICKED_UP || delivery.status == DeliveryStatus.IN_TRANSIT) {
      nextStatuses.add((DeliveryStatus.DELIVERED, 'Confirm Delivery', Icons.check_circle, const Color(0xFF10B981)));
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...nextStatuses.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(item.$3),
                label: Text(item.$2),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final updated = delivery.copyWith(
                      status: item.$1,
                      deliveredAt: item.$1 == DeliveryStatus.DELIVERED ? DateTime.now() : null,
                    );
                    await firestore.updateDelivery(updated);

                    // If delivered, also update the order status
                    if (item.$1 == DeliveryStatus.DELIVERED) {
                      final order = await firestore.getOrder(delivery.orderId);
                      if (order != null) {
                        await firestore.updateOrder(order.copyWith(status: OrderStatus.DELIVERED));
                      }
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ Status updated to ${item.$1.value}'),
                        backgroundColor: const Color(0xFF2D6A4F),
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.$4,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — EARNINGS
// ═══════════════════════════════════════════════════════════════════════════════

class _EarningsTab extends StatelessWidget {
  final UserModel? currentUser;
  const _EarningsTab({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final uid = currentUser?.uid ?? '';
    final fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFmt = DateFormat('MMM dd');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppBrandedHeader(
              greeting: 'My Earnings',
              subtitle: 'Track your delivery income',
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<DeliveryModel>>(
              stream: firestore.streamTransporterDeliveries(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F))),
                  );
                }

                final deliveries = snap.data ?? [];
                final completedDeliveries = deliveries.where(
                  (d) => d.status == DeliveryStatus.DELIVERED || d.status == DeliveryStatus.CONFIRMED,
                ).toList();

                final totalFees = completedDeliveries.fold<double>(0, (sum, d) => sum + d.deliveryFee);
                final totalDeliveries = completedDeliveries.length;

                // This month
                final now = DateTime.now();
                final thisMonth = completedDeliveries.where(
                  (d) => d.createdAt.year == now.year && d.createdAt.month == now.month,
                );
                final thisMonthFees = thisMonth.fold<double>(0, (sum, d) => sum + d.deliveryFee);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Earnings summary card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance_wallet, color: Colors.white70, size: 20),
                                SizedBox(width: 8),
                                Text('Total Earned', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fmt.format(totalFees),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.local_shipping, size: 14, color: Color(0xFF6EE7B7)),
                                            SizedBox(width: 6),
                                            Text('Deliveries', style: TextStyle(fontSize: 11, color: Color(0xFF6EE7B7))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('$totalDeliveries', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Color(0xFFFCD34D)),
                                            SizedBox(width: 6),
                                            Text('This Month', style: TextStyle(fontSize: 11, color: Color(0xFFFCD34D))),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(fmt.format(thisMonthFees), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Delivery history
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD8F3DC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${completedDeliveries.length} trips',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (completedDeliveries.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text('No completed deliveries yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                                const SizedBox(height: 4),
                                Text('Completed delivery earnings will appear here', style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
                              ],
                            ),
                          ),
                        ),

                      ...completedDeliveries.map((d) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD8F3DC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d.pickupLocation} → ${d.dropoffLocation}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFmt.format(d.createdAt),
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              d.deliveryFee > 0 ? fmt.format(d.deliveryFee) : 'TBD',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: d.deliveryFee > 0 ? const Color(0xFF059669) : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
