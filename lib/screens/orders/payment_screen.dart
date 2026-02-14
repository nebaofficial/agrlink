import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/order_model.dart';
import '../../models/payment_model.dart';
import '../../models/delivery_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'Mobile Money';

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // 1. Create Payment Record
      final payment = PaymentModel(
        id: '', // Assigned by Firestore
        orderId: widget.order.id,
        payerId: widget.order.buyerId,
        payeeId: widget.order.farmerId,
        amount: widget.order.totalAmount,
        paymentMethod: _selectedMethod,
        escrowStatus: EscrowStatus.HELD,
        createdAt: DateTime.now(),
      );

      await firestoreService.createPayment(payment);

      // 2. Update Order Status to PAID
      final updatedOrder = widget.order.copyWith(status: OrderStatus.PAID);
      await firestoreService.updateOrder(updatedOrder);

      // 3. Create Delivery Request (so transporters can see it)
      final delivery = DeliveryModel(
        id: '',
        orderId: widget.order.id,
        pickupLocation: 'Farm Location', // Should be fetched from product
        dropoffLocation: 'Buyer Location', // Should be fetched from buyer profile or checkout
        status: DeliveryStatus.PENDING,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await firestoreService.createDelivery(delivery);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.paymentSuccessful),
            content: Text(AppLocalizations.of(context)!.paymentEscrowSecured),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close payment screen
                  Navigator.of(context).pop(); // Close order detail (optional, or refresh)
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.secureCheckout)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount Card
            Card(
              color: const Color(0xFFF0FDF4),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('Total Amount to Pay',
                        style: TextStyle(color: Color(0xFF166534))),
                    const SizedBox(height: 8),
                    Text(
                      'ETB ${widget.order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment Methods
            _PaymentMethodTile(
              title: 'Telebirr',
              icon: Icons.phone_android,
              isSelected: _selectedMethod == 'Telebirr',
              onTap: () => setState(() => _selectedMethod = 'Telebirr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'CBE Birr',
              icon: Icons.account_balance_wallet,
              isSelected: _selectedMethod == 'CBE Birr',
              onTap: () => setState(() => _selectedMethod = 'CBE Birr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'Chapa (Card/Bank)',
              icon: Icons.credit_card,
              isSelected: _selectedMethod == 'Chapa',
              onTap: () => setState(() => _selectedMethod = 'Chapa'),
            ),

            const Spacer(),

            // Pay Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _processPayment,
              icon: const Icon(Icons.lock),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Pay Securely'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Payments are held in escrow until delivery is confirmed',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2D6A4F) : Colors.grey),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2D6A4F)),
          ],
        ),
      ),
    );
  }
}
