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
  final String? buyerId;
  final String? farmerId;
  final String? transporterId;
  final String pickupLocation;
  final String? pickupRegion;
  final String dropoffLocation;
  final DeliveryStatus status;
  final bool confirmedByAgent;
  final String? agentId;
  final double deliveryFee;
  final double distanceKm;
  final DateTime? deliveredAt;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeliveryModel({
    required this.id,
    required this.orderId,
    this.buyerId,
    this.farmerId,
    this.transporterId,
    required this.pickupLocation,
    this.pickupRegion,
    required this.dropoffLocation,
    this.status = DeliveryStatus.PENDING,
    this.confirmedByAgent = false,
    this.agentId,
    this.deliveryFee = 0,
    this.distanceKm = 0,
    this.deliveredAt,
    this.confirmedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeliveryModel(
      id: doc.id,
      orderId: data['order_id'] ?? '',
      buyerId: data['buyer_id'],
      farmerId: data['farmer_id'],
      transporterId: data['transporter_id'],
      pickupLocation: data['pickup_location'] ?? '',
      pickupRegion: data['pickup_region'],
      dropoffLocation: data['dropoff_location'] ?? '',
      status: DeliveryStatusExtension.fromString(data['delivery_status'] ?? 'PENDING'),
      confirmedByAgent: data['confirmed_by_agent'] ?? false,
      agentId: data['agent_id'],
      deliveryFee: (data['delivery_fee'] ?? 0).toDouble(),
      distanceKm: (data['distance_km'] ?? 0).toDouble(),
      deliveredAt: data['delivered_at'] != null
          ? (data['delivered_at'] as Timestamp).toDate()
          : null,
      confirmedAt: data['confirmed_at'] != null
          ? (data['confirmed_at'] as Timestamp).toDate()
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'order_id': orderId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'transporter_id': transporterId,
      'pickup_location': pickupLocation,
      'pickup_region': pickupRegion,
      'dropoff_location': dropoffLocation,
      'delivery_status': status.value,
      'confirmed_by_agent': confirmedByAgent,
      'agent_id': agentId,
      'delivery_fee': deliveryFee,
      'distance_km': distanceKm,
      'delivered_at': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'confirmed_at': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  DeliveryModel copyWith({
    String? transporterId,
    DeliveryStatus? status,
    bool? confirmedByAgent,
    String? agentId,
    double? deliveryFee,
    double? distanceKm,
    DateTime? deliveredAt,
    DateTime? confirmedAt,
  }) {
    return DeliveryModel(
      id: id,
      orderId: orderId,
      buyerId: buyerId,
      farmerId: farmerId,
      transporterId: transporterId ?? this.transporterId,
      pickupLocation: pickupLocation,
      pickupRegion: pickupRegion,
      dropoffLocation: dropoffLocation,
      status: status ?? this.status,
      confirmedByAgent: confirmedByAgent ?? this.confirmedByAgent,
      agentId: agentId ?? this.agentId,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      distanceKm: distanceKm ?? this.distanceKm,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
