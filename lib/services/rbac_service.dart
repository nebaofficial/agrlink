import '../models/user_role.dart';
import '../models/user_model.dart';

class RBACService {
  // Check if user has specific role
  static bool hasRole(UserModel? user, UserRole role) {
    return user?.role == role;
  }

  // Check if user is admin
  static bool isAdmin(UserModel? user) {
    return hasRole(user, UserRole.ADMIN);
  }

  // Check if user is farmer
  static bool isFarmer(UserModel? user) {
    return hasRole(user, UserRole.FARMER);
  }

  // Check if user is buyer
  static bool isBuyer(UserModel? user) {
    return hasRole(user, UserRole.BUYER);
  }

  // Check if user is transporter
  static bool isTransporter(UserModel? user) {
    return hasRole(user, UserRole.TRANSPORTER);
  }

  // Check if user is agent
  static bool isAgent(UserModel? user) {
    return hasRole(user, UserRole.AGENT);
  }

  // Check if user can create products
  static bool canCreateProduct(UserModel? user) {
    return isFarmer(user) || isAdmin(user);
  }

  // Check if user can edit specific product
  static bool canEditProduct(UserModel? user, String productOwnerId) {
    if (user == null) return false;
    return (isFarmer(user) && user.uid == productOwnerId) || isAdmin(user);
  }

  // Check if user can delete specific product
  static bool canDeleteProduct(UserModel? user, String productOwnerId) {
    return canEditProduct(user, productOwnerId);
  }

  // Check if user can create orders
  static bool canCreateOrder(UserModel? user) {
    return isBuyer(user) || isAdmin(user);
  }

  // Check if user can view specific order
  static bool canViewOrder(UserModel? user, String buyerId, String farmerId) {
    if (user == null) return false;
    return user.uid == buyerId || user.uid == farmerId || isAdmin(user);
  }

  // Check if user can update delivery
  static bool canUpdateDelivery(UserModel? user, String? transporterId) {
    if (user == null) return false;
    return (isTransporter(user) && user.uid == transporterId) || 
           isAgent(user) || 
           isAdmin(user);
  }

  // Check if user can confirm delivery
  static bool canConfirmDelivery(UserModel? user) {
    return isAgent(user) || isAdmin(user);
  }

  // Check if user can manage users
  static bool canManageUsers(UserModel? user) {
    return isAdmin(user);
  }

  // Check if user can view analytics
  static bool canViewAnalytics(UserModel? user) {
    return isAdmin(user) || isAgent(user);
  }

  // Get role display name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.FARMER:
        return 'Farmer';
      case UserRole.BUYER:
        return 'Buyer';
      case UserRole.TRANSPORTER:
        return 'Transporter';
      case UserRole.AGENT:
        return 'Agent';
      case UserRole.ADMIN:
        return 'Administrator';
    }
  }
}
