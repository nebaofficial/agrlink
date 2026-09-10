import 'package:cloud_firestore/cloud_firestore.dart';

enum TicketStatus { OPEN, IN_PROGRESS, RESOLVED }

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String userRole;
  final String subject;
  final String message;
  final TicketStatus status;
  final String? agentId;
  final String? agentName;
  final String? agentReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.subject,
    required this.message,
    this.status = TicketStatus.OPEN,
    this.agentId,
    this.agentName,
    this.agentReply,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SupportTicketModel(
      id: doc.id,
      userId: data['user_id'] ?? '',
      userName: data['user_name'] ?? '',
      userRole: data['user_role'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      status: TicketStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'OPEN'),
        orElse: () => TicketStatus.OPEN,
      ),
      agentId: data['agent_id'],
      agentName: data['agent_name'],
      agentReply: data['agent_reply'],
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'user_id': userId,
    'user_name': userName,
    'user_role': userRole,
    'subject': subject,
    'message': message,
    'status': status.name,
    'agent_id': agentId,
    'agent_name': agentName,
    'agent_reply': agentReply,
    'created_at': Timestamp.fromDate(createdAt),
    'updated_at': Timestamp.fromDate(updatedAt),
  };

  SupportTicketModel copyWith({
    TicketStatus? status,
    String? agentId,
    String? agentName,
    String? agentReply,
    DateTime? updatedAt,
  }) {
    return SupportTicketModel(
      id: id,
      userId: userId,
      userName: userName,
      userRole: userRole,
      subject: subject,
      message: message,
      status: status ?? this.status,
      agentId: agentId ?? this.agentId,
      agentName: agentName ?? this.agentName,
      agentReply: agentReply ?? this.agentReply,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
