import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';

/// Live delivery tracking screen — used by both buyer and farmer.
class DeliveryTrackingScreen extends StatelessWidget {
  final String orderId;
  final OrderModel order;

  const DeliveryTrackingScreen({
    super.key,
    required this.orderId,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Track Delivery'),
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DeliveryModel?>(
        stream: firestore.streamDeliveryByOrderId(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final delivery = snapshot.data;

          if (delivery == null) {
            return _NoDeliveryView(order: order);
          }

          return _DeliveryTrackingView(
            delivery: delivery,
            order: order,
            firestore: firestore,
          );
        },
      ),
    );
  }
}

// ─── No delivery yet ────────────────────────────────────────────────────────

class _NoDeliveryView extends StatelessWidget {
  final OrderModel order;
  const _NoDeliveryView({required this.order});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
              ),
              child: const Icon(Icons.hourglass_empty, size: 48, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 24),
            const Text('Delivery Pending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 8),
            Text(
              order.status == OrderStatus.PAID
                  ? 'Your delivery job is visible to transporters. A transporter will accept it shortly.'
                  : 'Delivery will be arranged after payment is confirmed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            if (order.expectedDelivery != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8F3DC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event, color: Color(0xFF2D6A4F), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Expected: ${DateFormat('MMM dd, yyyy').format(order.expectedDelivery!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1B4332)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Full tracking view ──────────────────────────────────────────────────────

class _DeliveryTrackingView extends StatelessWidget {
  final DeliveryModel delivery;
  final OrderModel order;
  final FirestoreService firestore;

  const _DeliveryTrackingView({
    required this.delivery,
    required this.order,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Status Banner ──────────────────────────────────────────────
          _StatusBannerCard(status: delivery.status),
          const SizedBox(height: 20),

          // ── Progress Stepper ───────────────────────────────────────────
          _ProgressStepper(status: delivery.status),
          const SizedBox(height: 20),

          // ── Product Info ────────────────────────────────────────────────
          FutureBuilder<ProductModel?>(
            future: firestore.getProduct(order.productId),
            builder: (context, snap) {
              final product = snap.data;
              return _InfoCard(
                title: 'Shipment Details',
                icon: Icons.inventory_2_outlined,
                children: [
                  _InfoRow(Icons.grass, 'Crop', product?.cropName ?? '...'),
                  _InfoRow(Icons.scale, 'Quantity', '${order.quantityKg.toStringAsFixed(0)} kg'),
                  _InfoRow(Icons.attach_money, 'Order Value', 'ETB ${order.totalAmount.toStringAsFixed(0)}'),
                  _InfoRow(Icons.tag, 'Tracking ID', delivery.id.substring(0, 8).toUpperCase()),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // ── Route Info ─────────────────────────────────────────────────
          _InfoCard(
            title: 'Delivery Route',
            icon: Icons.route_outlined,
            children: [
              _RouteVisual(
                pickup: delivery.pickupLocation.isNotEmpty
                    ? delivery.pickupLocation
                    : 'Farm Location',
                dropoff: delivery.dropoffLocation.isNotEmpty
                    ? delivery.dropoffLocation
                    : (order.deliveryAddress ?? 'Buyer Location'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Transporter Info ───────────────────────────────────────────
          if (delivery.transporterId != null)
            FutureBuilder<UserModel?>(
              future: firestore.getUser(delivery.transporterId!),
              builder: (context, snap) {
                if (snap.data == null) return const SizedBox.shrink();
                final transporter = snap.data!;
                return Column(
                  children: [
                    _InfoCard(
                      title: 'Your Transporter',
                      icon: Icons.person_outline,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: const BoxDecoration(color: Color(0xFFD8F3DC), shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: Color(0xFF2D6A4F), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(transporter.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  Text(transporter.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFD8F3DC), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.star, color: Color(0xFF2D6A4F), size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

          // ── Expected Delivery ──────────────────────────────────────────
          if (order.expectedDelivery != null)
            _InfoCard(
              title: 'Timeline',
              icon: Icons.schedule_outlined,
              children: [
                _InfoRow(Icons.event, 'Expected Delivery', DateFormat('EEEE, MMM dd yyyy').format(order.expectedDelivery!)),
                if (delivery.deliveredAt != null)
                  _InfoRow(Icons.check_circle, 'Delivered On', DateFormat('EEEE, MMM dd yyyy').format(delivery.deliveredAt!)),
              ],
            ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─── Status Banner ───────────────────────────────────────────────────────────

class _StatusBannerCard extends StatelessWidget {
  final DeliveryStatus status;
  const _StatusBannerCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      DeliveryStatus.PENDING   => ('Waiting for transporter', Icons.hourglass_empty, const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      DeliveryStatus.ASSIGNED  => ('Transporter assigned', Icons.person_pin, const Color(0xFFDBEAFE), const Color(0xFF2563EB)),
      DeliveryStatus.PICKED_UP => ('Crop picked up', Icons.inventory_2, const Color(0xFFEDE9FE), const Color(0xFF7C3AED)),
      DeliveryStatus.IN_TRANSIT=> ('On the way to you', Icons.local_shipping, const Color(0xFFFFFBEB), const Color(0xFFD97706)),
      DeliveryStatus.DELIVERED => ('Delivered!', Icons.check_circle, const Color(0xFFDCFCE7), const Color(0xFF059669)),
      DeliveryStatus.CONFIRMED => ('Delivery confirmed ✓', Icons.verified, const Color(0xFFD8F3DC), const Color(0xFF2D6A4F)),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: fg.withOpacity(0.3))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: fg.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status', style: TextStyle(fontSize: 12, color: fg.withOpacity(0.7), fontWeight: FontWeight.w500)),
                Text(label, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: fg)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: fg.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(status.value.replaceAll('_', ' '), style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Stepper ────────────────────────────────────────────────────────

class _ProgressStepper extends StatelessWidget {
  final DeliveryStatus status;
  const _ProgressStepper({required this.status});

  int get _currentStep => switch (status) {
    DeliveryStatus.PENDING   => 0,
    DeliveryStatus.ASSIGNED  => 1,
    DeliveryStatus.PICKED_UP => 2,
    DeliveryStatus.IN_TRANSIT=> 3,
    DeliveryStatus.DELIVERED => 4,
    DeliveryStatus.CONFIRMED => 4,
  };

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Order Placed', Icons.receipt_long),
      ('Assigned', Icons.person_pin),
      ('Picked Up', Icons.inventory_2),
      ('In Transit', Icons.local_shipping),
      ('Delivered', Icons.check_circle),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: List.generate(steps.length, (i) {
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;
          final isLast = i == steps.length - 1;

          final color = isDone || isActive
              ? const Color(0xFF2D6A4F)
              : Colors.grey.shade300;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF2D6A4F) : isActive ? const Color(0xFFD8F3DC) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: isDone || isActive ? 2 : 1),
                    ),
                    child: Icon(
                      isDone ? Icons.check : steps[i].$2,
                      size: 14,
                      color: isDone ? Colors.white : isActive ? const Color(0xFF2D6A4F) : Colors.grey.shade400,
                    ),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 32, color: isDone ? const Color(0xFF2D6A4F) : Colors.grey.shade200),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  steps[i].$1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isDone || isActive ? const Color(0xFF1F2937) : Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2D6A4F), size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _RouteVisual extends StatelessWidget {
  final String pickup;
  final String dropoff;
  const _RouteVisual({required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.agriculture, color: Color(0xFF2D6A4F), size: 28),
              const SizedBox(height: 4),
              Text('FROM', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(pickup, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(Icons.circle, size: 6, color: Color(0xFF2D6A4F)),
              SizedBox(width: 2),
              Icon(Icons.more_horiz, color: Color(0xFF2D6A4F)),
              SizedBox(width: 2),
              Icon(Icons.arrow_forward, color: Color(0xFF2D6A4F), size: 20),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.home, color: Color(0xFF3B82F6), size: 28),
              const SizedBox(height: 4),
              Text('TO', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(dropoff, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
            ],
          ),
        ),
      ],
    );
  }
}
