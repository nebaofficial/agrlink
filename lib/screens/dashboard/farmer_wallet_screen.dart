import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/payment_model.dart';
import '../../models/order_model.dart';
import '../../widgets/app_branded_header.dart';

const _kPrimaryDark = Color(0xFF1B4332);
const _kPrimary = Color(0xFF2D6A4F);
const _kSurface = Color(0xFFF9FAFB);
const _kLightGreen = Color(0xFFD8F3DC);

/// Farmer Wallet screen — shows earnings, escrow status, and transaction history.
class FarmerWalletScreen extends StatelessWidget {
  const FarmerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final uid = authService.currentUser?.uid ?? '';
    final fmt = NumberFormat.currency(symbol: 'ETB ', decimalDigits: 0);
    final dateFmt = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppBrandedHeader(
              greeting: 'My Wallet',
              subtitle: 'Track earnings & payments',
            ),
          ),

          // Wallet summary cards + transaction list
          SliverToBoxAdapter(
            child: StreamBuilder<List<PaymentModel>>(
              stream: firestoreService.streamFarmerPayments(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: _kPrimary)),
                  );
                }

                final payments = snapshot.data ?? [];
                final releasedPayments = payments
                    .where((p) => p.escrowStatus == EscrowStatus.RELEASED)
                    .toList();
                final heldPayments = payments
                    .where((p) => p.escrowStatus == EscrowStatus.HELD)
                    .toList();

                final totalEarned = releasedPayments.fold<double>(
                    0, (sum, p) => sum + p.farmerAmount);
                final pendingEscrow = heldPayments.fold<double>(
                    0, (sum, p) => sum + p.farmerAmount);

                // This month's income
                final now = DateTime.now();
                final thisMonthPayments = releasedPayments.where((p) =>
                    p.createdAt.year == now.year && p.createdAt.month == now.month);
                final thisMonthIncome = thisMonthPayments.fold<double>(
                    0, (sum, p) => sum + p.farmerAmount);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Summary cards ───
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kPrimaryDark, _kPrimary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.3),
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
                                Icon(Icons.account_balance_wallet,
                                    color: Colors.white70, size: 20),
                                SizedBox(width: 8),
                                Text('Total Earned',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fmt.format(totalEarned),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _MiniStat(
                                    label: 'Pending Escrow',
                                    value: fmt.format(pendingEscrow),
                                    icon: Icons.hourglass_empty,
                                    color: const Color(0xFFFCD34D),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _MiniStat(
                                    label: 'This Month',
                                    value: fmt.format(thisMonthIncome),
                                    icon: Icons.calendar_today,
                                    color: const Color(0xFF6EE7B7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ─── Transaction history ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaction History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryDark,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kLightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${payments.length} total',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (payments.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 56, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Payments will appear here when buyers place orders',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[400]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Transaction cards
                      ...payments.map((payment) => _TransactionCard(
                            payment: payment,
                            fmt: fmt,
                            dateFmt: dateFmt,
                            firestoreService: firestoreService,
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

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 11, color: color, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final PaymentModel payment;
  final NumberFormat fmt;
  final DateFormat dateFmt;
  final FirestoreService firestoreService;

  const _TransactionCard({
    required this.payment,
    required this.fmt,
    required this.dateFmt,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final isReleased = payment.escrowStatus == EscrowStatus.RELEASED;


    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: order + status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<OrderModel?>(
                future: firestoreService.getOrder(payment.orderId),
                builder: (context, snap) {
                  return Text(
                    'Order #${payment.orderId.length > 8 ? payment.orderId.substring(0, 8).toUpperCase() : payment.orderId.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryDark,
                    ),
                  );
                },
              ),
              _EscrowTag(status: payment.escrowStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateFmt.format(payment.createdAt),
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const Divider(height: 20),

          // Commission breakdown
          _BreakdownRow(
            label: 'Total order value',
            value: fmt.format(payment.amount),
            color: Colors.grey[800]!,
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: 'Commission deducted',
            value: '- ${fmt.format(payment.commission)}',
            color: const Color(0xFFEA580C), // orange
          ),
          const SizedBox(height: 6),
          _BreakdownRow(
            label: isReleased ? 'You received' : 'You will receive',
            value: fmt.format(payment.farmerAmount),
            color: const Color(0xFF059669), // green
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _EscrowTag extends StatelessWidget {
  final EscrowStatus status;
  const _EscrowTag({required this.status});

  @override
  Widget build(BuildContext context) {
    final (text, bg, fg) = switch (status) {
      EscrowStatus.PENDING => ('PENDING', const Color(0xFFF3F4F6), const Color(0xFF6B7280)),
      EscrowStatus.HELD => ('HELD', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
      EscrowStatus.RELEASED => ('RELEASED', const Color(0xFFDCFCE7), const Color(0xFF059669)),
      EscrowStatus.REFUNDED => ('REFUNDED', const Color(0xFFFFEBEE), const Color(0xFFC62828)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }
}
