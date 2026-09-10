import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/platform_config_provider.dart';
import '../../models/order_model.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'Telebirr';

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final config = Provider.of<PlatformConfigProvider>(context, listen: false);

      // Calculate commission splits from config
      final commission = widget.order.commission;
      final agentShare = widget.order.quantityKg * config.agentSharePerKg;
      final farmerAmount = widget.order.totalAmount - commission;

      // Get real locations for delivery
      final product = await firestoreService.getProduct(widget.order.productId);
      final pickupLocation = product?.location ?? 'Farm Location';

      // Build dropoff from order's delivery address + city
      String dropoffLocation = 'Buyer Location';
      if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty) {
        dropoffLocation = widget.order.deliveryAddress!;
        if (widget.order.deliveryCity != null && widget.order.deliveryCity!.isNotEmpty) {
          dropoffLocation += ', ${widget.order.deliveryCity}';
        }
      } else if (widget.order.deliveryCity != null && widget.order.deliveryCity!.isNotEmpty) {
        dropoffLocation = widget.order.deliveryCity!;
      }

      // ATOMIC: All 4 operations succeed together or all fail
      await firestoreService.processPaymentAtomic(
        order: widget.order,
        paymentMethod: _selectedMethod,
        commission: commission,
        agentShare: agentShare,
        farmerAmount: farmerAmount,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        agentId: widget.order.agentId,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.paymentSuccessful),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.paymentEscrowSecured),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Text('Payment held in escrow', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Text('Stock updated', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 8),
                          Text('Delivery job created', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: Color(0xFF2D6A4F), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'From: $pickupLocation',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.pin_drop, color: Color(0xFF2D6A4F), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To: $dropoffLocation',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFFD97706), size: 14),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Simulated payment — real gateway in Year 2',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close payment screen
                  Navigator.of(context).pop(); // Close order detail
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
                    const SizedBox(height: 8),
                    Text(
                      '${widget.order.quantityKg.toStringAsFixed(0)} kg × ETB ${widget.order.agreedPrice.toStringAsFixed(0)}/kg',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Delivery info summary
            if (widget.order.deliveryAddress != null && widget.order.deliveryAddress!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop, color: Color(0xFF2563EB), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivering to',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            '${widget.order.deliveryAddress}${widget.order.deliveryCity != null ? ', ${widget.order.deliveryCity}' : ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A5F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Payment Methods — all simulated for MVP
            _PaymentMethodTile(
              title: 'Telebirr',
              subtitle: 'Ethio Telecom mobile money',
              icon: Icons.phone_android,
              isSelected: _selectedMethod == 'Telebirr',
              onTap: () => setState(() => _selectedMethod = 'Telebirr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'CBE Birr',
              subtitle: 'Commercial Bank of Ethiopia',
              icon: Icons.account_balance_wallet,
              isSelected: _selectedMethod == 'CBE Birr',
              onTap: () => setState(() => _selectedMethod = 'CBE Birr'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'Chapa',
              subtitle: 'Card / Bank transfer',
              icon: Icons.credit_card,
              isSelected: _selectedMethod == 'Chapa',
              onTap: () => setState(() => _selectedMethod = 'Chapa'),
            ),
            const SizedBox(height: 12),
            _PaymentMethodTile(
              title: 'Santim Pay',
              subtitle: 'Multi-bank wallet',
              icon: Icons.account_balance,
              isSelected: _selectedMethod == 'Santim Pay',
              onTap: () => setState(() => _selectedMethod = 'Santim Pay'),
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
  final String? subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.title,
    this.subtitle,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2D6A4F)),
          ],
        ),
      ),
    );
  }
}
