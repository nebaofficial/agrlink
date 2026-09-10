import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../orders/order_detail_screen.dart';

class AgentReportsTab extends StatelessWidget {
  final UserModel? currentUser;
  const AgentReportsTab({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7F0),
      appBar: AppBar(
        title: const Text('Orders & Reports'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: fs.streamAgentOrders(currentUser?.uid ?? ''),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)));
          }
          final orders = snap.data ?? [];

          if (orders.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('No orders yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              ],
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              return FutureBuilder<ProductModel?>(
                future: fs.getProduct(order.productId),
                builder: (ctx, pSnap) {
                  final crop = pSnap.data?.cropName ?? '...';
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(crop, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                          _orderTag(order.status),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Icon(Icons.tag, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text('ID: ${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const Spacer(),
                          Text(fmt.format(order.totalAmount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.scale, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text('${order.quantityKg.toStringAsFixed(0)} kg', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(width: 16),
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 6),
                          Text(DateFormat('MMM dd, yyyy').format(order.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ]),
                      ]),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _orderTag(OrderStatus s) {
    final (t, bg, fg) = switch (s) {
      OrderStatus.PENDING   => ('PENDING',    const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      OrderStatus.ACCEPTED  => ('ACCEPTED',   const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
      OrderStatus.PAID      => ('PAID',       const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      OrderStatus.IN_TRANSIT=> ('IN TRANSIT', const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
      OrderStatus.DELIVERED => ('DELIVERED',  const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      OrderStatus.COMPLETED => ('COMPLETED',  const Color(0xFFC8E6C9), const Color(0xFF1B5E20)),
      OrderStatus.CANCELLED => ('CANCELLED',  const Color(0xFFFFEBEE), const Color(0xFFC62828)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(t, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
