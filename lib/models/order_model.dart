import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_model.dart';

enum OrderStatus {
  PENDING,
  ACCEPTED,
  PAID,
  IN_TRANSIT,
  DELIVERED,
  COMPLETED,
  CANCELLED,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.PENDING:
        return 'PENDING';
      case OrderStatus.ACCEPTED:
        return 'ACCEPTED';
      case OrderStatus.PAID:
        return 'PAID';
      case OrderStatus.IN_TRANSIT:
        return 'IN_TRANSIT';
      case OrderStatus.DELIVERED:
        return 'DELIVERED';
      case OrderStatus.COMPLETED:
        return 'COMPLETED';
      case OrderStatus.CANCELLED:
        return 'CANCELLED';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.PENDING;
      case 'ACCEPTED':
        return OrderStatus.ACCEPTED;
      case 'PAID':
        return OrderStatus.PAID;
      case 'IN_TRANSIT':
        return OrderStatus.IN_TRANSIT;
      case 'DELIVERED':
        return OrderStatus.DELIVERED;
      case 'COMPLETED':
        return OrderStatus.COMPLETED;
      case 'CANCELLED':
        return OrderStatus.CANCELLED;
      default:
        return OrderStatus.PENDING;
    }
  }
}

class OrderModel {
  final String id;
  final String productId;
  final String buyerId;
  final String farmerId;
  final String? agentId;
  final double quantityKg;
  final double agreedPrice;
  final double totalAmount;
  final double commissionPerKg;
  final double commission;
  final double agentShare;
  final double netToFarmer;
  final OrderStatus status;
  final DateTime? expectedDelivery;
  final String? deliveryAddress;
  final String? deliveryCity;
  final DateTime createdAt;
  final DateTime? autoAcceptAt;
  final bool autoAccepted;
  final ProductModel? product;

  OrderModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.farmerId,
    this.agentId,
    required this.quantityKg,
    required this.agreedPrice,
    required this.totalAmount,
    required this.commissionPerKg,
    required this.commission,
    this.agentShare = 0,
    double? netToFarmer,
    this.status = OrderStatus.PENDING,
    this.expectedDelivery,
    this.deliveryAddress,
    this.deliveryCity,
    required this.createdAt,
    this.autoAcceptAt,
    this.autoAccepted = false,
    this.product,
  }) : netToFarmer = netToFarmer ?? (totalAmount - commission);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final totalAmount = (data['total_amount'] ?? 0).toDouble();
    final quantityKg = (data['quantity_kg'] ?? 0).toDouble();
    final commissionPerKg = (data['commission_per_kg'] ?? 1.0).toDouble();
    // Support both new per-kg model and legacy 5% model
    final commission = (data['commission'] ?? quantityKg * commissionPerKg).toDouble();

    return OrderModel(
      id: doc.id,
      productId: data['product_id'] ?? '',
      buyerId: data['buyer_id'] ?? '',
      farmerId: data['farmer_id'] ?? '',
      agentId: data['agent_id'],
      quantityKg: quantityKg,
      agreedPrice: (data['agreed_price'] ?? 0).toDouble(),
      totalAmount: totalAmount,
      commissionPerKg: commissionPerKg,
      commission: commission,
      agentShare: (data['agent_share'] ?? 0).toDouble(),
      netToFarmer: (data['net_to_farmer'] ?? totalAmount - commission).toDouble(),
      status: OrderStatusExtension.fromString(data['status'] ?? 'PENDING'),
      expectedDelivery: data['expected_delivery'] != null
          ? (data['expected_delivery'] as Timestamp).toDate()
          : null,
      deliveryAddress: data['delivery_address'],
      deliveryCity: data['delivery_city'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      autoAcceptAt: data['auto_accept_at'] != null
          ? (data['auto_accept_at'] as Timestamp).toDate()
          : null,
      autoAccepted: data['auto_accepted'] ?? false,
      product: null, // Enrichment happens separately if needed
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'agent_id': agentId,
      'quantity_kg': quantityKg,
      'agreed_price': agreedPrice,
      'total_amount': totalAmount,
      'commission_per_kg': commissionPerKg,
      'commission': commission,
      'agent_share': agentShare,
      'net_to_farmer': netToFarmer,
      'status': status.value,
      'expected_delivery': expectedDelivery != null
          ? Timestamp.fromDate(expectedDelivery!)
          : null,
      'delivery_address': deliveryAddress,
      'delivery_city': deliveryCity,
      'created_at': Timestamp.fromDate(createdAt),
      'auto_accept_at': autoAcceptAt != null
          ? Timestamp.fromDate(autoAcceptAt!)
          : null,
      'auto_accepted': autoAccepted,
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    DateTime? expectedDelivery,
    String? deliveryAddress,
    String? deliveryCity,
    String? agentId,
    DateTime? autoAcceptAt,
    bool? autoAccepted,
  }) {
    return OrderModel(
      id: id,
      productId: productId,
      buyerId: buyerId,
      farmerId: farmerId,
      agentId: agentId ?? this.agentId,
      quantityKg: quantityKg,
      agreedPrice: agreedPrice,
      totalAmount: totalAmount,
      commissionPerKg: commissionPerKg,
      commission: commission,
      agentShare: agentShare,
      netToFarmer: netToFarmer,
      status: status ?? this.status,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      createdAt: createdAt,
      autoAcceptAt: autoAcceptAt ?? this.autoAcceptAt,
      autoAccepted: autoAccepted ?? this.autoAccepted,
    );
  }
}
