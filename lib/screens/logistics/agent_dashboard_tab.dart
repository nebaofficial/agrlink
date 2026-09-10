import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/delivery_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../models/support_ticket_model.dart';
import '../../widgets/app_branded_header.dart';
import 'agent_support_screen.dart';

// Consistent color palette — same as profile_screen
const _kPrimaryDark = Color(0xFF1B4332);
const _kPrimary = Color(0xFF2D6A4F);
const _kSurface = Color(0xFFF9FAFB);
const _kLightGreen = Color(0xFFD8F3DC);

class AgentDashboardTab extends StatelessWidget {
  final UserModel? currentUser;
  final void Function(int)? onSwitchTab;
  const AgentDashboardTab({super.key, this.currentUser, this.onSwitchTab});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    final agentId = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        slivers: [
          // ─── Header (shared branded header) ───
          SliverToBoxAdapter(
            child: AppBrandedHeader(
              greeting: 'Hello, ${currentUser?.fullName ?? 'Agent'}',
              subtitle: 'Manage field tasks',
            ),
          ),

          // ─── Stats cards — scoped by agentId ───
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<DeliveryModel>>(
                stream: fs.streamAgentDeliveries(agentId),
                builder: (ctx, deliverySnap) {
                  final all = deliverySnap.data ?? [];
                  final pending = all.where((d) => d.status == DeliveryStatus.PENDING).length;
                  final toConfirm = all.where((d) => d.status == DeliveryStatus.DELIVERED && !d.confirmedByAgent).length;
                  final confirmed = all.where((d) => d.confirmedByAgent).length;

                  return StreamBuilder<List<SupportTicketModel>>(
                    stream: fs.streamAgentSupportTickets(agentId),
                    builder: (ctx, ticketSnap) {
                      final openTickets = (ticketSnap.data ?? [])
                          .where((t) => t.status != TicketStatus.RESOLVED)
                          .length;

                      return Column(children: [
                        Row(children: [
                          _card('Pending\nVerifications', '$pending',
                            Icons.hourglass_empty, const Color(0xFFF57F17),
                            () => onSwitchTab?.call(1)),
                          const SizedBox(width: 12),
                          _card('Deliveries to\nConfirm', '$toConfirm',
                            Icons.local_shipping, const Color(0xFFE65100),
                            () => onSwitchTab?.call(1)),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _card('Support\nRequests', '$openTickets',
                            Icons.headset_mic, const Color(0xFF1565C0),
                            () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => AgentSupportScreen(currentUser: currentUser),
                            ))),
                          const SizedBox(width: 12),
                          _card('Completed\nTasks', '$confirmed',
                            Icons.check_circle, _kPrimary,
                            () => onSwitchTab?.call(1)),
                        ]),
                      ]);
                    },
                  );
                },
              ),
            ),
          ),

          // ─── Quick actions ───
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _action(context, 'Verify\nFarmer', Icons.verified_user, _kPrimary,
                      () => onSwitchTab?.call(1)),
                    const SizedBox(width: 12),
                    _action(context, 'Confirm\nDelivery', Icons.fact_check, const Color(0xFF1565C0),
                      () => onSwitchTab?.call(1)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    _action(context, 'Support\nTickets', Icons.headset_mic, const Color(0xFFF57F17),
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => AgentSupportScreen(currentUser: currentUser),
                      ))),
                    const SizedBox(width: 12),
                    _action(context, 'Orders &\nReports', Icons.assessment, const Color(0xFF6A1B9A),
                      () => onSwitchTab?.call(2)),
                  ]),
                ],
              ),
            ),
          ),

          // ─── Orders summary — scoped by agentId ───
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: StreamBuilder<List<OrderModel>>(
                stream: fs.streamAgentOrders(agentId),
                builder: (ctx, snap) {
                  final orders = snap.data ?? [];
                  final active = orders.where((o) =>
                    o.status != OrderStatus.COMPLETED && o.status != OrderStatus.CANCELLED).length;
                  return InkWell(
                    onTap: () => onSwitchTab?.call(2),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kLightGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt_long, color: _kPrimary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$active active orders', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kPrimaryDark)),
                            Text('${orders.length} total', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        )),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ),

          // ─── Tips ───
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kLightGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.lightbulb_outline, color: _kPrimary, size: 18),
                      SizedBox(width: 8),
                      Text('Agent Tips', style: TextStyle(fontWeight: FontWeight.bold, color: _kPrimaryDark)),
                    ]),
                    SizedBox(height: 8),
                    Text('• Verify deliveries when marked as delivered', style: TextStyle(fontSize: 13, color: _kPrimary)),
                    Text('• Help farmers register on the platform', style: TextStyle(fontSize: 13, color: _kPrimary)),
                    Text('• Resolve buyer/farmer disputes promptly', style: TextStyle(fontSize: 13, color: _kPrimary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String label, String value, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, String label, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ]),
        ),
      ),
    );
  }
}
