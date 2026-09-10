import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/payment_model.dart';

import '../../models/user_model.dart';

const _kPrimaryDark = Color(0xFF1B4332);
const _kPrimary = Color(0xFF2D6A4F);

/// Admin screen for one-tap escrow release.
/// Shows payments with status HELD that have confirmed deliveries.
class EscrowReleaseScreen extends StatelessWidget {
  const EscrowReleaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFmt = DateFormat('MMM dd, yyyy • HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Escrow Release'),
        backgroundColor: _kPrimaryDark,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<PaymentModel>>(
        stream: fs.streamHeldPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _kPrimary));
          }

          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF6EE7B7), width: 2),
                    ),
                    child: const Icon(Icons.check_circle,
                        size: 48, color: _kPrimary),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'All payments released',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No pending escrow payments to release',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              return _EscrowCard(
                payment: payments[index],
                fs: fs,
                fmt: fmt,
                dateFmt: dateFmt,
              );
            },
          );
        },
      ),
    );
  }
}

class _EscrowCard extends StatefulWidget {
  final PaymentModel payment;
  final FirestoreService fs;
  final NumberFormat fmt;
  final DateFormat dateFmt;

  const _EscrowCard({
    required this.payment,
    required this.fs,
    required this.fmt,
    required this.dateFmt,
  });

  @override
  State<_EscrowCard> createState() => _EscrowCardState();
}

class _EscrowCardState extends State<_EscrowCard> {
  bool _releasing = false;

  Future<void> _release() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Release'),
        content: Text(
          'Release ${widget.fmt.format(widget.payment.farmerAmount)} to farmer?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: _kPrimary),
            child: const Text('Release Payment',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _releasing = true);
    try {
      final auth =
          Provider.of<AuthService>(context, listen: false);
      await widget.fs.releaseEscrowAtomic(
        paymentId: widget.payment.id,
        orderId: widget.payment.orderId,
        adminUid: auth.currentUser?.uid ?? '',
      );

      // TODO: Send FCM to farmer: "ETB X has been released to your account"
      // TODO: Send FCM to buyer: "Your order is complete. Thank you."

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Released ${widget.fmt.format(widget.payment.farmerAmount)} to farmer'),
            backgroundColor: _kPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _releasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order + escrow status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${widget.payment.orderId.length > 8 ? widget.payment.orderId.substring(0, 8).toUpperCase() : widget.payment.orderId.toUpperCase()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'HELD',
                  style: TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Farmer info
          FutureBuilder<UserModel?>(
            future: widget.fs.getUser(widget.payment.payeeId),
            builder: (ctx, snap) {
              final farmer = snap.data;
              return Row(
                children: [
                  const Icon(Icons.person, size: 16, color: _kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Farmer: ${farmer?.fullName ?? '...'}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),

          // Amount details
          Row(
            children: [
              const Icon(Icons.payments, size: 16, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                'Total: ${widget.fmt.format(widget.payment.amount)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Text(
                'Commission: ${widget.fmt.format(widget.payment.commission)}',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFFEA580C)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Created: ${widget.dateFmt.format(widget.payment.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Release amount + button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Farmer receives',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      widget.fmt.format(widget.payment.farmerAmount),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _releasing ? null : _release,
                  icon: _releasing
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open, size: 18),
                  label: Text(_releasing ? 'Releasing...' : 'Release'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
