import 'package:cloud_firestore/cloud_firestore.dart';

enum EscrowStatus {
  PENDING,
  HELD,
  RELEASED,
  REFUNDED,
}

extension EscrowStatusExtension on EscrowStatus {
  String get value {
    switch (this) {
      case EscrowStatus.PENDING:
        return 'PENDING';
      case EscrowStatus.HELD:
        return 'HELD';
      case EscrowStatus.RELEASED:
        return 'RELEASED';
      case EscrowStatus.REFUNDED:
        return 'REFUNDED';
    }
  }

  static EscrowStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return EscrowStatus.PENDING;
      case 'HELD':
        return EscrowStatus.HELD;
      case 'RELEASED':
        return EscrowStatus.RELEASED;
      case 'REFUNDED':
        return EscrowStatus.REFUNDED;
      default:
        return EscrowStatus.PENDING;
    }
  }
}

class PaymentModel {
  final String id;
  final String orderId;
  final String payerId;
  final String payeeId;
  final String? agentId;
  final String paymentMethod;
  final double amount;
  final double commission;
  final double agentShare;
  final double farmerAmount;
  final EscrowStatus escrowStatus;
  final bool isSimulated;
  final DateTime createdAt;
  final DateTime? releasedAt;
  final String? releasedBy;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.payerId,
    required this.payeeId,
    this.agentId,
    required this.paymentMethod,
    required this.amount,
    this.commission = 0,
    this.agentShare = 0,
    double? farmerAmount,
    this.escrowStatus = EscrowStatus.PENDING,
    this.isSimulated = true,
    required this.createdAt,
    this.releasedAt,
    this.releasedBy,
  }) : farmerAmount = farmerAmount ?? (amount - commission);

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] ?? 0).toDouble();
    final commission = (data['commission'] ?? 0).toDouble();
    return PaymentModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      payerId: data['payer_id'] ?? '',
      payeeId: data['payee_id'] ?? '',
      agentId: data['agent_id'],
      paymentMethod: data['payment_method'] ?? 'TELEBIRR',
      amount: amount,
      commission: commission,
      agentShare: (data['agent_share'] ?? 0).toDouble(),
      farmerAmount: (data['farmer_amount'] ?? amount - commission).toDouble(),
      escrowStatus: EscrowStatusExtension.fromString(data['escrow_status'] ?? 'PENDING'),
      isSimulated: data['is_simulated'] ?? true,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      releasedAt: data['released_at'] != null
          ? (data['released_at'] as Timestamp).toDate()
          : null,
      releasedBy: data['released_by'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'payer_id': payerId,
      'payee_id': payeeId,
      'agent_id': agentId,
      'payment_method': paymentMethod,
      'amount': amount,
      'commission': commission,
      'agent_share': agentShare,
      'farmer_amount': farmerAmount,
      'escrow_status': escrowStatus.value,
      'is_simulated': isSimulated,
      'created_at': Timestamp.fromDate(createdAt),
      'released_at': releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
      'released_by': releasedBy,
    };
  }

  PaymentModel copyWith({
    EscrowStatus? escrowStatus,
    DateTime? releasedAt,
    String? releasedBy,
  }) {
    return PaymentModel(
      id: id,
      orderId: orderId,
      payerId: payerId,
      payeeId: payeeId,
      agentId: agentId,
      paymentMethod: paymentMethod,
      amount: amount,
      commission: commission,
      agentShare: agentShare,
      farmerAmount: farmerAmount,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      isSimulated: isSimulated,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
      releasedBy: releasedBy ?? this.releasedBy,
    );
  }
}
