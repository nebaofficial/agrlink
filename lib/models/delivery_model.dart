import 'package:cloud_firestore/cloud_firestore.dart';

enum DeliveryStatus {
  PENDING,
  ASSIGNED,
  PICKED_UP,
  IN_TRANSIT,
  DELIVERED,
  CONFIRMED,
}

extension DeliveryStatusExtension on DeliveryStatus {
  String get value {
    switch (this) {
      case DeliveryStatus.PENDING:
        return 'PENDING';
      case DeliveryStatus.ASSIGNED:
        return 'ASSIGNED';
      case DeliveryStatus.PICKED_UP:
        return 'PICKED_UP';
      case DeliveryStatus.IN_TRANSIT:
        return 'IN_TRANSIT';
      case DeliveryStatus.DELIVERED:
        return 'DELIVERED';
      case DeliveryStatus.CONFIRMED:
        return 'CONFIRMED';
    }
  }

  static DeliveryStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return DeliveryStatus.PENDING;
      case 'ASSIGNED':
        return DeliveryStatus.ASSIGNED;
      case 'PICKED_UP':
        return DeliveryStatus.PICKED_UP;
      case 'IN_TRANSIT':
        return DeliveryStatus.IN_TRANSIT;
      case 'DELIVERED':
        return DeliveryStatus.DELIVERED;
      case 'CONFIRMED':
        return DeliveryStatus.CONFIRMED;
      default:
        return DeliveryStatus.PENDING;
    }
  }
}

class DeliveryModel {
  final String id;
  final String orderId;
  final String? transporterId;
  final String pickupLocation;
  final String dropoffLocation;
  final DeliveryStatus status;
  final bool confirmedByAgent;
  final String? agentId;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel({
    required this.id,
    required this.orderId,
    this.transporterId,
    required this.pickupLocation,
    required this.dropoffLocation,
    this.status = DeliveryStatus.PENDING,
    this.confirmedByAgent = false,
    this.agentId,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      transporterId: data['transporter_id'],
      pickupLocation: data['pickup_location'] ?? '',
      dropoffLocation: data['dropoff_location'] ?? '',
      status: DeliveryStatusExtension.fromString(data['delivery_status'] ?? 'PENDING'),
      confirmedByAgent: data['confirmed_by_agent'] ?? false,
      agentId: data['agent_id'],
      deliveredAt: data['delivered_at'] != null 
          ? (data['delivered_at'] as Timestamp).toDate() 
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'transporter_id': transporterId,
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
      'delivery_status': status.value,
      'confirmed_by_agent': confirmedByAgent,
      'agent_id': agentId,
      'delivered_at': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  DeliveryModel copyWith({
    String? transporterId,
    DeliveryStatus? status,
    bool? confirmedByAgent,
    String? agentId,
    DateTime? deliveredAt,
  }) {
    return DeliveryModel(
      id: id,
      orderId: orderId,
      transporterId: transporterId ?? this.transporterId,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      status: status ?? this.status,
      confirmedByAgent: confirmedByAgent ?? this.confirmedByAgent,
      agentId: agentId ?? this.agentId,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
