import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/support_ticket_model.dart';
import '../../models/user_model.dart';

// Consistent color palette
const _kPrimaryDark = Color(0xFF1B4332);
const _kPrimary = Color(0xFF2D6A4F);
const _kPrimaryLight = Color(0xFF40916C);
const _kSurface = Color(0xFFF0F7F0);
const _kLightGreen = Color(0xFFD8F3DC);

/// Standalone support screen pushed from agent dashboard.
/// Shows all support tickets from farmers/buyers and lets agents reply.
class AgentSupportScreen extends StatelessWidget {
  final UserModel? currentUser;
  const AgentSupportScreen({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: _kSurface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _kPrimaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Support Requests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPrimaryDark, _kPrimary, _kPrimaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: 10,
                      child: Opacity(
                        opacity: 0.06,
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 120,
                          width: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<SupportTicketModel>>(
              stream: fs.streamAgentSupportTickets(currentUser?.uid ?? ''),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: _kPrimary)),
                  );
                }
                final tickets = snap.data ?? [];
                if (tickets.isEmpty) {
                  return SizedBox(
                    height: 400,
                    child: Center(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: _kLightGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.support_agent, size: 56, color: _kPrimary),
                        ),
                        const SizedBox(height: 20),
                        const Text('No support requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark)),
                        const SizedBox(height: 8),
                        Text('All clear! No pending tickets.', style: TextStyle(color: Colors.grey[600])),
                      ]),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  itemBuilder: (ctx, i) => _TicketCard(ticket: tickets[i], fs: fs, agent: currentUser),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  final FirestoreService fs;
  final UserModel? agent;
  const _TicketCard({required this.ticket, required this.fs, this.agent});

  Color get _statusColor => switch (ticket.status) {
    TicketStatus.OPEN => const Color(0xFFE53935),
    TicketStatus.IN_PROGRESS => const Color(0xFFF57F17),
    TicketStatus.RESOLVED => _kPrimary,
  };

  Color get _statusBg => switch (ticket.status) {
    TicketStatus.OPEN => const Color(0xFFFFEBEE),
    TicketStatus.IN_PROGRESS => const Color(0xFFFFF8E1),
    TicketStatus.RESOLVED => _kLightGreen,
  };

  IconData get _roleIcon => switch (ticket.userRole.toUpperCase()) {
    'FARMER' => Icons.agriculture,
    'BUYER' => Icons.shopping_cart,
    'TRANSPORTER' => Icons.local_shipping,
    _ => Icons.person,
  };

  @override
  Widget build(BuildContext context) {
    final timeAgo = _formatTime(ticket.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBF9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kLightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_roleIcon, color: _kPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ticket.userName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _kPrimaryDark)),
                  Text('${ticket.userRole} • $timeAgo', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(ticket.status.name, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(ticket.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimaryDark)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(ticket.message, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          ),

          // Agent reply (if exists)
          if (ticket.agentReply != null && ticket.agentReply!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kLightGreen,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.reply, size: 14, color: _kPrimary),
                  const SizedBox(width: 6),
                  Text('Agent Reply${ticket.agentName != null ? ' — ${ticket.agentName}' : ''}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kPrimary)),
                ]),
                const SizedBox(height: 6),
                Text(ticket.agentReply!, style: TextStyle(fontSize: 13, color: Colors.grey[800], height: 1.4)),
              ]),
            ),

          // Action buttons
          if (ticket.status != TicketStatus.RESOLVED)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.reply, size: 18),
                    label: const Text('Reply'),
                    onPressed: () => _showReplyDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimary,
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('Resolve'),
                    onPressed: () => _resolve(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ]),
            ),
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _kLightGreen, shape: BoxShape.circle),
              child: Icon(Icons.reply, color: _kPrimary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Reply to Ticket', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimaryDark)),
          ]),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.userName, style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimaryDark)),
              const SizedBox(height: 2),
              Text(ticket.subject, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(ticket.message, style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type your reply...',
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Send Reply'),
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                final updated = ticket.copyWith(
                  agentReply: controller.text.trim(),
                  agentId: agent?.uid,
                  agentName: agent?.fullName,
                  status: TicketStatus.IN_PROGRESS,
                  updatedAt: DateTime.now(),
                );
                await fs.updateSupportTicket(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Reply sent'),
                      backgroundColor: _kPrimary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    try {
      final updated = ticket.copyWith(
        status: TicketStatus.RESOLVED,
        agentId: agent?.uid,
        agentName: agent?.fullName,
        updatedAt: DateTime.now(),
      );
      await fs.updateSupportTicket(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Ticket resolved'),
            backgroundColor: _kPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd').format(dt);
  }
}
