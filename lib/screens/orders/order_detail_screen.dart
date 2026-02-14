import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/delivery_model.dart';
import '../../widgets/status_badge.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import 'payment_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isFarmer = currentUser?.uid == order.farmerId;
    final isBuyer = currentUser?.uid == order.buyerId;

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
                      Column(
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
                                  child: product.imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Icon(Icons.agriculture, color: Colors.grey),
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
                          label: AppLocalizations.of(context)!.totalVolume, // Reusing totalVolume for Total Amount if needed, or keeping it
                          value: currencyFormat.format(order.totalAmount),
                          isBold: true,
                          color: const Color(0xFF2D6A4F),
                        ),
                        if (isActualFarmer) ...[
                          const Divider(height: 24),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.platformFee,
                            value: '- ${currencyFormat.format(order.commission)}',
                            color: Colors.red[700],
                          ),
                          const Divider(height: 24),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.netEarnings,
                            value: currencyFormat.format(order.netToFarmer),
                            isBold: true,
                            color: const Color(0xFF2D6A4F),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery Info
                FutureBuilder<DeliveryModel?>(
                  future: firestoreService.getDeliveryByOrderId(order.id),
                  builder: (context, snapshot) {
                    final delivery = snapshot.data;

                    // If no delivery record yet (e.g. before payment/assignment)
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
    try {
      final updatedOrder = order.copyWith(status: newStatus);
      await service.updateOrder(updatedOrder);
      if (context.mounted) {
        String localizedStatus = _getLocalizedStatus(context, newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.orderStatusUpdatedTo(localizedStatus))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
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
        return AppLocalizations.of(context)!.statusSold; // Or add statusPaid if needed
      case OrderStatus.IN_TRANSIT:
        return AppLocalizations.of(context)!.statusInTransit;
      case OrderStatus.DELIVERED:
        return AppLocalizations.of(context)!.statusDelivered;
      case OrderStatus.COMPLETED:
        return AppLocalizations.of(context)!.saleCompleted(''); // This is a placeholder, need a better one
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
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
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
