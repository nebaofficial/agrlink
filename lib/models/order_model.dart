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
  final double quantityKg;
  final double agreedPrice;
  final double totalAmount;
  final double commission;
  final double netToFarmer;
  final OrderStatus status;
  final DateTime? expectedDelivery;
  final DateTime createdAt;
  final ProductModel? product;

  OrderModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.farmerId,
    required this.quantityKg,
    required this.agreedPrice,
    required this.totalAmount,
    double? commission,
    double? netToFarmer,
    this.status = OrderStatus.PENDING,
    this.expectedDelivery,
    required this.createdAt,
    this.product,
  })  : commission = commission ?? (totalAmount * 0.05), // 5% default commission
        netToFarmer = netToFarmer ?? (totalAmount * 0.95);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final totalAmount = (data['total_amount'] ?? 0).toDouble();
    return OrderModel(
      id: doc.id,
      productId: data['product_id'] ?? '',
      buyerId: data['buyer_id'] ?? '',
      farmerId: data['farmer_id'] ?? '',
      quantityKg: (data['quantity_kg'] ?? 0).toDouble(),
      agreedPrice: (data['agreed_price'] ?? 0).toDouble(),
      totalAmount: totalAmount,
      commission: (data['commission'] ?? totalAmount * 0.05).toDouble(),
      netToFarmer: (data['net_to_farmer'] ?? totalAmount * 0.95).toDouble(),
      status: OrderStatusExtension.fromString(data['status'] ?? 'PENDING'),
      expectedDelivery: data['expected_delivery'] != null
          ? (data['expected_delivery'] as Timestamp).toDate()
          : null,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      product: null, // Enrichment happens separately if needed
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'product_id': productId,
      'buyer_id': buyerId,
      'farmer_id': farmerId,
      'quantity_kg': quantityKg,
      'agreed_price': agreedPrice,
      'total_amount': totalAmount,
      'commission': commission,
      'net_to_farmer': netToFarmer,
      'status': status.value,
      'expected_delivery': expectedDelivery != null 
          ? Timestamp.fromDate(expectedDelivery!) 
          : null,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  OrderModel copyWith({
    OrderStatus? status,
    DateTime? expectedDelivery,
  }) {
    return OrderModel(
      id: id,
      productId: productId,
      buyerId: buyerId,
      farmerId: farmerId,
      quantityKg: quantityKg,
      agreedPrice: agreedPrice,
      totalAmount: totalAmount,
      commission: commission,
      netToFarmer: netToFarmer,
      status: status ?? this.status,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      createdAt: createdAt,
    );
  }
}
