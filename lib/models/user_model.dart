import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String phone;
  final String? email;
  final UserRole role;
  final String? faydaId;
  final bool isVerified;
  final double rating;
  final String? address;
  final String? city;
  final String? agentId;
  final bool autoAcceptOrders;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.phone,
    this.email,
    required this.role,
    this.faydaId,
    this.isVerified = false,
    this.rating = 5.0,
    this.address,
    this.city,
    this.agentId,
    this.autoAcceptOrders = false,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      fullName: data['full_name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      role: UserRoleExtension.fromString(data['role'] ?? 'FARMER'),
      faydaId: data['fayda_id'],
      isVerified: data['is_verified'] ?? false,
      rating: (data['rating'] ?? 5.0).toDouble(),
      address: data['address'],
      city: data['city'],
      agentId: data['agent_id'],
      autoAcceptOrders: data['auto_accept_orders'] ?? false,
      createdAt: data['created_at'] != null
          ? (data['created_at'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role.value,
      'fayda_id': faydaId,
      'is_verified': isVerified,
      'rating': rating,
      'address': address,
      'city': city,
      'agent_id': agentId,
      'auto_accept_orders': autoAcceptOrders,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? fullName,
    String? phone,
    String? email,
    UserRole? role,
    String? faydaId,
    bool? isVerified,
    double? rating,
    String? address,
    String? city,
    String? agentId,
    bool? autoAcceptOrders,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      faydaId: faydaId ?? this.faydaId,
      isVerified: isVerified ?? this.isVerified,
      rating: rating ?? this.rating,
      address: address ?? this.address,
      city: city ?? this.city,
      agentId: agentId ?? this.agentId,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      createdAt: createdAt,
    );
  }
}
