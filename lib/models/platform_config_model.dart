import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for the /config/platform Firestore document.
/// All configurable platform values are read from here — never hardcoded in Dart.
class PlatformConfigModel {
  final double commissionPerKg;
  final double agentSharePerKg;
  final int orderAutoAcceptHours;
  final double minOrderKg;
  final int maxAgentFarmers;
  final double deliveryFeeBase;
  final double deliveryFeePerKm;
  final int refundWindowDays;
  final String supportPhone;

  const PlatformConfigModel({
    this.commissionPerKg = 1.00,
    this.agentSharePerKg = 0.10,
    this.orderAutoAcceptHours = 6,
    this.minOrderKg = 10,
    this.maxAgentFarmers = 20,
    this.deliveryFeeBase = 50,
    this.deliveryFeePerKm = 5,
    this.refundWindowDays = 7,
    this.supportPhone = '+251911000000',
  });

  factory PlatformConfigModel.fromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return const PlatformConfigModel();
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlatformConfigModel(
      commissionPerKg: (data['commission_per_kg'] ?? 1.00).toDouble(),
      agentSharePerKg: (data['agent_share_per_kg'] ?? 0.10).toDouble(),
      orderAutoAcceptHours: (data['order_auto_accept_hours'] ?? 6).toInt(),
      minOrderKg: (data['min_order_kg'] ?? 10).toDouble(),
      maxAgentFarmers: (data['max_agent_farmers'] ?? 20).toInt(),
      deliveryFeeBase: (data['delivery_fee_base'] ?? 50).toDouble(),
      deliveryFeePerKm: (data['delivery_fee_per_km'] ?? 5).toDouble(),
      refundWindowDays: (data['refund_window_days'] ?? 7).toInt(),
      supportPhone: data['support_phone'] ?? '+251929073343',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'commission_per_kg': commissionPerKg,
      'agent_share_per_kg': agentSharePerKg,
      'order_auto_accept_hours': orderAutoAcceptHours,
      'min_order_kg': minOrderKg,
      'max_agent_farmers': maxAgentFarmers,
      'delivery_fee_base': deliveryFeeBase,
      'delivery_fee_per_km': deliveryFeePerKm,
      'refund_window_days': refundWindowDays,
      'support_phone': supportPhone,
    };
  }
}
