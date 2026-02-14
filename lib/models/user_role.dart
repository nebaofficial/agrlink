enum UserRole {
  FARMER,
  BUYER,
  TRANSPORTER,
  AGENT,
  ADMIN,
}

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.FARMER:
        return 'FARMER';
      case UserRole.BUYER:
        return 'BUYER';
      case UserRole.TRANSPORTER:
        return 'TRANSPORTER';
      case UserRole.AGENT:
        return 'AGENT';
      case UserRole.ADMIN:
        return 'ADMIN';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'FARMER':
        return UserRole.FARMER;
      case 'BUYER':
        return UserRole.BUYER;
      case 'TRANSPORTER':
        return UserRole.TRANSPORTER;
      case 'AGENT':
        return UserRole.AGENT;
      case 'ADMIN':
        return UserRole.ADMIN;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }
}
