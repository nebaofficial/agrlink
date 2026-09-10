import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/delivery_model.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/product_image.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import 'payment_screen.dart';
import 'delivery_tracking_screen.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = false;
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  OrderModel get order => widget.order;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (order.status != OrderStatus.PENDING || order.autoAcceptAt == null) return;

    _updateTimeRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  void _updateTimeRemaining() {
    if (order.autoAcceptAt == null) return;
    final remaining = order.autoAcceptAt!.difference(DateTime.now());
    if (remaining.isNegative) {
      _countdownTimer?.cancel();
      setState(() => _timeRemaining = Duration.zero);
    } else {
      setState(() => _timeRemaining = remaining);
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final currencyFormat = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, userSnapshot) {
        final currentUserData = userSnapshot.data;
        final isAdmin = currentUserData?.role == UserRole.ADMIN;
        final isFarmerRole = currentUserData?.role == UserRole.FARMER;
        final isBuyerRole = currentUserData?.role == UserRole.BUYER;

        final isActualFarmer = (currentUserData?.uid == order.farmerId && isFarmerRole) || isAdmin;
        final isActualBuyer = (currentUserData?.uid == order.buyerId && isBuyerRole) || isAdmin;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.orderDetails),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(order.status)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(order.status),
                        color: _getStatusColor(order.status),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.statusPending}: ${_getLocalizedStatus(context, order.status)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(order.status),
                              ),
                            ),
                            if (order.autoAccepted)
                              const Text(
                                '⚡ Auto-accepted (farmer didn\'t respond in time)',
                                style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                              ),
                            if (order.status == OrderStatus.PENDING && isActualFarmer)
                              Text(
                                AppLocalizations.of(context)!.waitingForYourAcceptance,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            if (order.status == OrderStatus.PENDING && isActualBuyer)
                              Text(
                                AppLocalizations.of(context)!.waitingForFarmerAcceptance,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Auto-accept countdown timer (for PENDING orders)
                if (order.status == OrderStatus.PENDING && order.autoAcceptAt != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFDE68A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Auto-accept countdown',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _timeRemaining.inSeconds > 0
                                    ? _formatDuration(_timeRemaining)
                                    : 'Processing auto-accept...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _timeRemaining.inHours < 1
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFFD97706),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Product Info
                FutureBuilder<ProductModel?>(
                  future: firestoreService.getProduct(order.productId),
                  builder: (context, snapshot) {
                    final product = snapshot.data;
                    if (product == null) return const SizedBox.shrink();

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.productInformation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ProductImage(
                                    imageUrl: product.imageUrl,
                                    width: 60,
                                    height: 60,
                                    borderRadius: 8,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.cropName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        product.location ?? AppLocalizations.of(context)!.noLocation,
                                        style: TextStyle(color: Colors.grey[600]),
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
                const SizedBox(height: 16),

                // Order Details
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        Text(
                          AppLocalizations.of(context)!.transactionDetails,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: AppLocalizations.of(context)!.orderId,
                          value: order.id.substring(0, 8).toUpperCase(),
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: AppLocalizations.of(context)!.quantity,
                          value: '${order.quantityKg.toStringAsFixed(0)} kg',
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: AppLocalizations.of(context)!.pricePerKg,
                          value: currencyFormat.format(order.agreedPrice),
                        ),
                        const Divider(height: 24),
                        _DetailRow(
                          label: AppLocalizations.of(context)!.totalVolume,
                          value: currencyFormat.format(order.totalAmount),
                          isBold: true,
                          color: const Color(0xFF2D6A4F),
                        ),
                        if (isActualFarmer) ...[
                          const Divider(height: 24),
                          _DetailRow(
                            label: '${AppLocalizations.of(context)!.platformFee} (${order.commissionPerKg.toStringAsFixed(0)} ETB/kg)',
                            value: '- ${currencyFormat.format(order.commission)}',
                            color: const Color(0xFFEA580C),
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.netEarnings,
                            value: currencyFormat.format(order.netToFarmer),
                            isBold: true,
                            color: const Color(0xFF059669),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Info (live stream)
                StreamBuilder<DeliveryModel?>(
                  stream: firestoreService.streamDeliveryByOrderId(order.id),
                  builder: (context, snapshot) {
                    final delivery = snapshot.data;

                    // If no delivery record yet
                    if (delivery == null) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.deliveryInformation,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (order.expectedDelivery != null)
                                _DetailRow(
                                  label: AppLocalizations.of(context)!.expectedDate,
                                  value: dateFormat.format(order.expectedDelivery!),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.deliveryArrangementPending,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.deliveryTracking,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    StatusBadge(
                                      status: delivery.status.value,
                                      type: StatusType.delivery,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (order.expectedDelivery != null)
                                  _DetailRow(
                                    label: AppLocalizations.of(context)!.expectedDate,
                                    value: dateFormat.format(order.expectedDelivery!),
                                  ),
                                const SizedBox(height: 8),
                                _DetailRow(
                                    label: AppLocalizations.of(context)!.trackingId,
                                    value: delivery.id.substring(0, 8).toUpperCase()),
                                const SizedBox(height: 8),
                                if (delivery.transporterId != null)
                                  FutureBuilder<UserModel?>(
                                      future: firestoreService.getUser(delivery.transporterId!),
                                      builder: (context, userSnap) {
                                        if (userSnap.hasData) {
                                          return _DetailRow(
                                            label: AppLocalizations.of(context)!.transporter,
                                            value: userSnap.data!.fullName,
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Track Delivery button
                        ElevatedButton.icon(
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text('Track Delivery'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeliveryTrackingScreen(
                                  orderId: order.id,
                                  order: order,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Actions
                if (isActualFarmer && order.status == OrderStatus.PENDING)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _updateStatus(context, firestoreService, OrderStatus.CANCELLED),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(AppLocalizations.of(context)!.rejectOrder),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateStatus(context, firestoreService, OrderStatus.ACCEPTED),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(AppLocalizations.of(context)!.acceptOrder),
                        ),
                      ),
                    ],
                  ),
                if (isActualBuyer && order.status == OrderStatus.PENDING)
                  OutlinedButton(
                    onPressed: () => _updateStatus(context, firestoreService, OrderStatus.CANCELLED),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancelOrder),
                  ),
                if (isActualBuyer && order.status == OrderStatus.ACCEPTED)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(order: order),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(AppLocalizations.of(context)!.payNowEscrow),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(BuildContext context, FirestoreService service, OrderStatus newStatus) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final updatedOrder = order.copyWith(status: newStatus);
      await service.updateOrder(updatedOrder);
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading dialog
        String localizedStatus = _getLocalizedStatus(context, newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.orderStatusUpdatedTo(localizedStatus)),
            backgroundColor: const Color(0xFF2D6A4F),
          ),
        );
        Navigator.pop(context); // go back to previous screen
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return const Color(0xFFF59E0B);
      case OrderStatus.ACCEPTED:
        return const Color(0xFF3B82F6);
      case OrderStatus.PAID:
        return const Color(0xFF10B981);
      case OrderStatus.IN_TRANSIT:
        return const Color(0xFF8B5CF6);
      case OrderStatus.DELIVERED:
        return const Color(0xFF10B981);
      case OrderStatus.COMPLETED:
        return const Color(0xFF059669);
      case OrderStatus.CANCELLED:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
     switch (status) {
      case OrderStatus.PENDING:
        return Icons.hourglass_empty;
      case OrderStatus.ACCEPTED:
        return Icons.thumb_up;
      case OrderStatus.PAID:
        return Icons.payment;
      case OrderStatus.IN_TRANSIT:
        return Icons.local_shipping;
      case OrderStatus.DELIVERED:
         return Icons.check_circle_outline;
      case OrderStatus.COMPLETED:
         return Icons.check_circle;
      case OrderStatus.CANCELLED:
        return Icons.cancel_outlined;
    }
  }

  String _getLocalizedStatus(BuildContext context, OrderStatus status) {
    switch (status) {
      case OrderStatus.PENDING:
        return AppLocalizations.of(context)!.statusPending;
      case OrderStatus.ACCEPTED:
        return AppLocalizations.of(context)!.statusAccepted;
      case OrderStatus.PAID:
        return AppLocalizations.of(context)!.statusSold;
      case OrderStatus.IN_TRANSIT:
        return AppLocalizations.of(context)!.statusInTransit;
      case OrderStatus.DELIVERED:
        return AppLocalizations.of(context)!.statusDelivered;
      case OrderStatus.COMPLETED:
        return AppLocalizations.of(context)!.saleCompleted('');
      case OrderStatus.CANCELLED:
        return AppLocalizations.of(context)!.statusCancelled;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
     this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
             fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
