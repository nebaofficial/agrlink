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
  final String paymentMethod;
  final double amount;
  final EscrowStatus escrowStatus;
  final DateTime createdAt;
  final DateTime? releasedAt;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.payerId,
    required this.payeeId,
    required this.paymentMethod,
    required this.amount,
    this.escrowStatus = EscrowStatus.PENDING,
    required this.createdAt,
    this.releasedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      payerId: data['payer_id'] ?? '',
      payeeId: data['payee_id'] ?? '',
      paymentMethod: data['payment_method'] ?? 'TELEBIRR',
      amount: (data['amount'] ?? 0).toDouble(),
      escrowStatus: EscrowStatusExtension.fromString(data['escrow_status'] ?? 'PENDING'),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      releasedAt: data['released_at'] != null 
          ? (data['released_at'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'payer_id': payerId,
      'payee_id': payeeId,
      'payment_method': paymentMethod,
      'amount': amount,
      'escrow_status': escrowStatus.value,
      'created_at': Timestamp.fromDate(createdAt),
      'released_at': releasedAt != null ? Timestamp.fromDate(releasedAt!) : null,
    };
  }

  PaymentModel copyWith({
    EscrowStatus? escrowStatus,
    DateTime? releasedAt,
  }) {
    return PaymentModel(
      id: id,
      orderId: orderId,
      payerId: payerId,
      payeeId: payeeId,
      paymentMethod: paymentMethod,
      amount: amount,
      escrowStatus: escrowStatus ?? this.escrowStatus,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }
}
