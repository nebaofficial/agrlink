import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../orders/order_detail_screen.dart';

class AgentTasksTab extends StatefulWidget {
  final UserModel? currentUser;
  const AgentTasksTab({super.key, this.currentUser});

  @override
  State<AgentTasksTab> createState() => _AgentTasksTabState();
}

class _AgentTasksTabState extends State<AgentTasksTab> with SingleTickerProviderStateMixin {
  late TabController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: const Text('Deliveries'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tc,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Active'), Tab(text: 'Done')],
        ),
      ),
      body: TabBarView(controller: _tc, children: [
        _List(filter: [DeliveryStatus.PENDING], user: widget.currentUser, empty: 'No pending deliveries'),
        _List(filter: [DeliveryStatus.ASSIGNED, DeliveryStatus.PICKED_UP, DeliveryStatus.IN_TRANSIT], user: widget.currentUser, empty: 'No active deliveries'),
        _List(filter: [DeliveryStatus.DELIVERED, DeliveryStatus.CONFIRMED], user: widget.currentUser, empty: 'No completed deliveries'),
      ]),
    );
  }
}

class _List extends StatelessWidget {
  final List<DeliveryStatus> filter;
  final UserModel? user;
  final String empty;
  const _List({required this.filter, this.user, required this.empty});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<List<DeliveryModel>>(
      stream: fs.streamAgentDeliveries(user?.uid ?? ''),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
        }
        final items = (snap.data ?? []).where((d) => filter.contains(d.status)).toList();
        if (items.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(empty, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (ctx, i) => _Card(delivery: items[i], fs: fs, user: user),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final DeliveryModel delivery;
  final FirestoreService fs;
  final UserModel? user;
  const _Card({required this.delivery, required this.fs, this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel?>(
      future: fs.getOrder(delivery.orderId),
      builder: (ctx, oSnap) {
        final order = oSnap.data;
        return FutureBuilder<ProductModel?>(
          future: order != null ? fs.getProduct(order.productId) : Future.value(null),
          builder: (ctx, pSnap) {
            final crop = pSnap.data?.cropName ?? '...';
            final qty = order?.quantityKg.toStringAsFixed(0) ?? '...';
            return InkWell(
              onTap: order != null ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: order),
                  ),
                );
              } : null,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(crop, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                    _tag(delivery.status),
                  ]),
                  const SizedBox(height: 10),
                  _info(Icons.scale, 'Quantity: $qty kg'),
                  const SizedBox(height: 6),
                  _info(Icons.location_on, 'From: ${delivery.pickupLocation}'),
                  const SizedBox(height: 6),
                  _info(Icons.pin_drop, 'To: ${delivery.dropoffLocation}'),
                  if (delivery.transporterId != null) ...[
                    const SizedBox(height: 6),
                    FutureBuilder<UserModel?>(
                      future: fs.getUser(delivery.transporterId!),
                      builder: (c, s) => _info(Icons.person, 'Transporter: ${s.data?.fullName ?? '...'}'),
                    ),
                  ],
                  if (delivery.status == DeliveryStatus.DELIVERED && !delivery.confirmedByAgent) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.verified),
                        label: const Text('Verify & Confirm'),
                        onPressed: () => _confirm(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                  if (delivery.confirmedByAgent)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(children: [
                        const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 16),
                        const SizedBox(width: 6),
                        Text('Verified by agent', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ]),
                    ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Widget _info(IconData ic, String t) => Row(children: [
    Icon(ic, size: 16, color: Colors.grey[500]),
    const SizedBox(width: 8),
    Expanded(child: Text(t, style: TextStyle(color: Colors.grey[700], fontSize: 13))),
  ]);

  Widget _tag(DeliveryStatus s) {
    final (t, bg, fg) = switch (s) {
      DeliveryStatus.PENDING    => ('PENDING',    const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      DeliveryStatus.ASSIGNED   => ('ASSIGNED',   const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      DeliveryStatus.PICKED_UP  => ('PICKED UP',  const Color(0xFFF3E5F5), const Color(0xFF6A1B9A)),
      DeliveryStatus.IN_TRANSIT => ('IN TRANSIT', const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      DeliveryStatus.DELIVERED  => ('DELIVERED',  const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      DeliveryStatus.CONFIRMED  => ('CONFIRMED',  const Color(0xFFC8E6C9), const Color(0xFF1B5E20)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    try {
      final updated = delivery.copyWith(
        status: DeliveryStatus.CONFIRMED,
        confirmedByAgent: true,
        agentId: user?.uid,
      );
      await fs.updateDelivery(updated);
      final order = await fs.getOrder(delivery.orderId);
      if (order != null) {
        await fs.updateOrder(order.copyWith(status: OrderStatus.COMPLETED));
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Delivery verified!'), backgroundColor: Color(0xFF2E7D32)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
