import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductStatus {
  AVAILABLE,
  RESERVED,
  SOLD,
  UNAVAILABLE,
}

extension ProductStatusExtension on ProductStatus {
  String get value {
    switch (this) {
      case ProductStatus.AVAILABLE:
        return 'AVAILABLE';
      case ProductStatus.RESERVED:
        return 'RESERVED';
      case ProductStatus.SOLD:
        return 'SOLD';
      case ProductStatus.UNAVAILABLE:
        return 'UNAVAILABLE';
    }
  }

  static ProductStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return ProductStatus.AVAILABLE;
      case 'RESERVED':
        return ProductStatus.RESERVED;
      case 'SOLD':
        return ProductStatus.SOLD;
      case 'UNAVAILABLE':
        return ProductStatus.UNAVAILABLE;
      default:
        return ProductStatus.AVAILABLE;
    }
  }
}

class ProductModel {
  final String id;
  final String farmerId;
  final String cropName;
  final String description;
  final double quantityKg;
  final double minOrderKg;
  final double pricePerKg;
  final DateTime? harvestDate;
  final ProductStatus status;
  final String? location;
  final String? imageUrl;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.cropName,
    this.description = '',
    required this.quantityKg,
    this.minOrderKg = 1.0,
    required this.pricePerKg,
    this.harvestDate,
    this.status = ProductStatus.AVAILABLE,
    this.location,
    this.imageUrl,
    required this.createdAt,
  });

  double get totalPrice => quantityKg * pricePerKg;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      farmerId: data['farmer_id'] ?? '',
      cropName: data['crop_name'] ?? '',
      description: data['description'] ?? '',
      quantityKg: (data['quantity_kg'] ?? 0).toDouble(),
      minOrderKg: (data['min_order_kg'] ?? 1.0).toDouble(),
      pricePerKg: (data['price_per_kg'] ?? 0).toDouble(),
      harvestDate: data['harvest_date'] != null
          ? (data['harvest_date'] as Timestamp).toDate()
          : null,
      status: ProductStatusExtension.fromString(data['status'] ?? 'AVAILABLE'),
      location: data['location'],
      imageUrl: data['image_url'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'farmer_id': farmerId,
      'crop_name': cropName,
      'description': description,
      'quantity_kg': quantityKg,
      'min_order_kg': minOrderKg,
      'price_per_kg': pricePerKg,
      'harvest_date': harvestDate != null ? Timestamp.fromDate(harvestDate!) : null,
      'status': status.value,
      'location': location,
      'image_url': imageUrl,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  ProductModel copyWith({
    String? cropName,
    String? description,
    double? quantityKg,
    double? minOrderKg,
    double? pricePerKg,
    DateTime? harvestDate,
    ProductStatus? status,
    String? location,
    String? imageUrl,
  }) {
    return ProductModel(
      id: id,
      farmerId: farmerId,
      cropName: cropName ?? this.cropName,
      description: description ?? this.description,
      quantityKg: quantityKg ?? this.quantityKg,
      minOrderKg: minOrderKg ?? this.minOrderKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      harvestDate: harvestDate ?? this.harvestDate,
      status: status ?? this.status,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}
