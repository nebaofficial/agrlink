import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/platform_config_model.dart';

/// ChangeNotifier that loads and caches platform config from Firestore.
/// All screens read config values from this provider — never from Dart constants.
class PlatformConfigProvider extends ChangeNotifier {
  PlatformConfigModel _config = const PlatformConfigModel();
  bool _isLoaded = false;
  String? _error;

  PlatformConfigModel get config => _config;
  bool get isLoaded => _isLoaded;
  String? get error => _error;

  // Convenience getters used throughout the app
  double get commissionPerKg => _config.commissionPerKg;
  double get agentSharePerKg => _config.agentSharePerKg;
  int get orderAutoAcceptHours => _config.orderAutoAcceptHours;
  double get minOrderKg => _config.minOrderKg;
  int get maxAgentFarmers => _config.maxAgentFarmers;
  double get deliveryFeeBase => _config.deliveryFeeBase;
  double get deliveryFeePerKm => _config.deliveryFeePerKm;
  int get refundWindowDays => _config.refundWindowDays;
  String get supportPhone => _config.supportPhone;

  /// Load config from Firestore /config/platform.
  /// Falls back to safe defaults if document doesn't exist.
  Future<void> loadConfig() async {
    try {
      _error = null;
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('platform')
          .get();
      _config = PlatformConfigModel.fromFirestore(doc);
      _isLoaded = true;
      debugPrint('✅ Platform config loaded: commission=${_config.commissionPerKg} ETB/kg');
    } catch (e) {
      _error = e.toString();
      // Keep safe defaults — app still works without Firestore config
      _isLoaded = true;
      debugPrint('⚠️ Failed to load platform config, using defaults: $e');
    }
    notifyListeners();
  }

  /// Calculate commission for a given quantity.
  double calculateCommission(double quantityKg) {
    return quantityKg * _config.commissionPerKg;
  }

  /// Calculate agent share for a given quantity.
  double calculateAgentShare(double quantityKg) {
    return quantityKg * _config.agentSharePerKg;
  }

  /// Calculate net amount to farmer after commission deduction.
  double calculateNetToFarmer(double totalAmount, double quantityKg) {
    return totalAmount - calculateCommission(quantityKg);
  }

  /// Calculate delivery fee for a given distance.
  double calculateDeliveryFee(double distanceKm) {
    return _config.deliveryFeeBase + (distanceKm * _config.deliveryFeePerKm);
  }
}
