import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/support_ticket_model.dart';
import '../../models/user_role.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  static const _primaryGreen = Color(0xFF2D6A4F);
  static const _lightGreen = Color(0xFFD8F3DC);
  static const _darkGreen = Color(0xFF1B4332);

  final List<_HelpTopic> _topics = const [
    _HelpTopic(icon: Icons.inventory_2_outlined, title: 'Issue with my crop listing', color: Color(0xFF2D6A4F), description: 'Having trouble listing your crops? We can help you add, edit, or remove your crop listings.'),
    _HelpTopic(icon: Icons.payments_outlined, title: 'Payment problem', color: Color(0xFFD97706), description: 'Issues with receiving payments, escrow holds, or transaction errors.'),
    _HelpTopic(icon: Icons.local_shipping_outlined, title: 'Delivery issue', color: Color(0xFF3B82F6), description: 'Transporter not showing up, wrong delivery address, or delivery not confirmed.'),
    _HelpTopic(icon: Icons.verified_user_outlined, title: 'Account verification', color: Color(0xFF7C3AED), description: 'Help with account verification, phone number update, or account access issues.'),
    _HelpTopic(icon: Icons.help_outline, title: 'Other problem', color: Color(0xFF6B7280), description: 'Something else is wrong? Describe your issue and our team will help.'),
  ];

  final List<_FaqItem> _faqs = const [
    _FaqItem(question: 'How to add a crop?', answer: 'Go to "My Farm" dashboard → tap "List New Crop" → fill in crop name, quantity, price per kg, harvest date, and location → tap Save.'),
    _FaqItem(question: 'How do I get paid?', answer: 'When a buyer places an order and pays, the money is held in escrow. Once delivery is confirmed by the agent, the payment (minus 5% platform fee) is released to your linked mobile money account.'),
    _FaqItem(question: 'Why is my crop not visible?', answer: 'Your crop listing must be in "AVAILABLE" status. If the quantity reaches 0 after orders, it is marked SOLD. You can add a new listing or edit the crop to increase quantity.'),
    _FaqItem(question: 'How long does delivery take?', answer: 'Delivery time depends on distance and available transporters. Once a transporter accepts, you will see their name and real-time status updates.'),
    _FaqItem(question: 'What is the 5% platform fee?', answer: 'AgriLink charges a 5% commission on each completed sale. This covers payment processing, delivery coordination, and platform maintenance.'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: _primaryGreen,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Support & Help', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Align(alignment: Alignment(0.85, 0.3), child: Icon(Icons.support_agent, size: 80, color: Colors.white12)),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // My Tickets section
                if (currentUserId != null) ...[
                  _sectionHeader('My Tickets', Icons.confirmation_number_outlined),
                  const SizedBox(height: 12),
                  _MyTicketsSection(userId: currentUserId),
                  const SizedBox(height: 28),
                ],

                _sectionHeader('Quick Help Topics', Icons.bolt_outlined),
                const SizedBox(height: 12),
                ...List.generate(_topics.length, (i) {
                  final topic = _topics[i];
                  return _HelpTopicCard(topic: topic, onTap: () => _showTopicSheet(topic));
                }),
                const SizedBox(height: 28),
                _sectionHeader('Contact Support', Icons.contact_support_outlined),
                const SizedBox(height: 12),
                _ContactCard(icon: Icons.phone, title: 'Call Support', subtitle: '+251 911 123 456', color: _primaryGreen, bgColor: _lightGreen, onTap: () => _showContactAction('Call Support', '+251 911 123 456', 'Dial this number to speak with our team.')),
                const SizedBox(height: 10),
                _ContactCard(icon: Icons.chat, title: 'WhatsApp Support', subtitle: 'Chat with us on WhatsApp', color: Color(0xFF25D366), bgColor: Color(0xFFDCF8C6), onTap: () => _showContactAction('WhatsApp Support', '+251 911 123 456', 'Open WhatsApp and message this number.')),
                const SizedBox(height: 10),
                _ContactCard(icon: Icons.mail_outline, title: 'Send Message', subtitle: 'support@agrilink.et', color: Color(0xFF3B82F6), bgColor: Color(0xFFDBEAFE), onTap: () => _showMessageSheet(context)),
                const SizedBox(height: 28),
                _sectionHeader('Frequently Asked Questions', Icons.quiz_outlined),
                const SizedBox(height: 12),
                ..._faqs.map((faq) => _FaqTile(faq: faq)),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule, color: _primaryGreen, size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text('Support available Mon–Sat, 8:00 AM – 6:00 PM (EAT)', style: TextStyle(fontSize: 13, color: _darkGreen))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: _lightGreen, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _primaryGreen, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _darkGreen)),
      ],
    );
  }

  void _showTopicSheet(_HelpTopic topic) {
    final msgController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool sending = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: topic.color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(topic.icon, color: topic.color, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(topic.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 12),
                Text(topic.description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 20),
                TextField(
                  controller: msgController,
                  maxLines: 3,
                  enabled: !sending,
                  decoration: InputDecoration(hintText: 'Describe your issue...', filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(sending ? 'Sending...' : 'Send to Support'),
                    onPressed: sending ? null : () async {
                      if (msgController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please describe your issue')),
                        );
                        return;
                      }
                      setSheetState(() => sending = true);
                      await _submitTicket(topic.title, msgController.text.trim());
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitTicket(String subject, String message) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final fs = Provider.of<FirestoreService>(context, listen: false);
      final userData = await authService.getCurrentUserData();

      if (userData == null) return;

      final ticket = SupportTicketModel(
        id: '',
        userId: userData.uid,
        userName: userData.fullName,
        userRole: userData.role.value,
        subject: subject,
        message: message,
        status: TicketStatus.OPEN,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await fs.createSupportTicket(ticket);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Ticket submitted! An agent will respond soon.'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    }
  }

  void _showMessageSheet(BuildContext context) {
    final msgController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send a Message', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Your message will be sent to a support agent.', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            TextField(controller: msgController, maxLines: 5, decoration: InputDecoration(hintText: 'Type your message here...', filled: true, fillColor: const Color(0xFFF9FAFB), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send Message'),
                onPressed: () async {
                  if (msgController.text.trim().isEmpty) return;
                  await _submitTicket('General Support', msgController.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactAction(String title, String contact, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: Text(contact, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332)))),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF2D6A4F)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: contact));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ Copied $contact'),
                        backgroundColor: _primaryGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

/// Shows the user's own tickets with agent replies
class _MyTicketsSection extends StatelessWidget {
  final String userId;
  const _MyTicketsSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);
    return StreamBuilder<List<SupportTicketModel>>(
      stream: fs.streamUserSupportTickets(userId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F))));
        }
        final tickets = snap.data ?? [];
        if (tickets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.grey[400], size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('No tickets yet. Tap a topic below to get help.', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
            ]),
          );
        }
        return Column(
          children: tickets.take(3).map((t) => _UserTicketCard(ticket: t)).toList(),
        );
      },
    );
  }
}

class _UserTicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  const _UserTicketCard({required this.ticket});

  Color get _statusColor => switch (ticket.status) {
    TicketStatus.OPEN => const Color(0xFFE53935),
    TicketStatus.IN_PROGRESS => const Color(0xFFF57F17),
    TicketStatus.RESOLVED => const Color(0xFF2E7D32),
  };

  String get _statusLabel => switch (ticket.status) {
    TicketStatus.OPEN => 'Waiting',
    TicketStatus.IN_PROGRESS => 'Replied',
    TicketStatus.RESOLVED => 'Resolved',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(ticket.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1B4332)))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(_statusLabel, style: TextStyle(color: _statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(ticket.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        if (ticket.agentReply != null && ticket.agentReply!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.reply, size: 14, color: Color(0xFF2E7D32)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Agent${ticket.agentName != null ? ' ${ticket.agentName}' : ''}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 2),
                  Text(ticket.agentReply!, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
                ]),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 6),
        Text(DateFormat('MMM dd, yyyy • h:mm a').format(ticket.createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      ]),
    );
  }
}

class _HelpTopic {
  final IconData icon;
  final String title;
  final Color color;
  final String description;
  const _HelpTopic({required this.icon, required this.title, required this.color, required this.description});
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

class _HelpTopicCard extends StatelessWidget {
  final _HelpTopic topic;
  final VoidCallback onTap;
  const _HelpTopicCard({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: topic.color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(topic.icon, color: topic.color, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Text(topic.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ContactCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Tap', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final _FaqItem faq;
  const _FaqTile({required this.faq});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _expanded ? const Color(0xFF2D6A4F).withOpacity(0.4) : Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.faq.question, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _expanded ? const Color(0xFF2D6A4F) : const Color(0xFF1F2937))),
          leading: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: _expanded ? const Color(0xFFD8F3DC) : const Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: Icon(_expanded ? Icons.remove : Icons.add, size: 16, color: _expanded ? const Color(0xFF2D6A4F) : Colors.grey[500]),
          ),
          onExpansionChanged: (val) => setState(() => _expanded = val),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.faq.answer, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6)),
            ),
          ],
        ),
      ),
    );
  }
}
