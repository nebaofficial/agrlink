import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/rbac_service.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../auth/login_screen.dart';
import '../../services/language_service.dart';
import 'package:agrilink/l10n/generated/app_localizations.dart';

String _getRoleDisplayName(BuildContext context, UserRole role) {
  switch (role) {
    case UserRole.FARMER:
      return AppLocalizations.of(context)!.roleFarmer;
    case UserRole.BUYER:
      return AppLocalizations.of(context)!.roleBuyer;
    case UserRole.TRANSPORTER:
      return AppLocalizations.of(context)!.roleTransporter;
    case UserRole.AGENT:
      return AppLocalizations.of(context)!.roleAgent;
    default:
      return role.value;
  }
}

class ProfileScreen extends StatelessWidget {
  final UserModel? currentUser;

  const ProfileScreen({
    super.key,
    this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF2D6A4F);
    final backgroundColor = const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header with Logo and Title
          SliverToBoxAdapter(
            child: Container(
              color: primaryColor,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40), // Spacer for removed menu
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B4332),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Image.asset(
                              'assets/images/logo.png',
                              height: 20,
                              width: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'AgriLink',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _IconButton(
                            icon: Icons.language,
                            onPressed: () {
                              final langService = Provider.of<LanguageService>(context, listen: false);
                              langService.toggleLanguage();
                            },
                          ),
                          const SizedBox(width: 8),
                          _NotificationBadge(count: 2),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.profile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.accountInfo,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Overlapping Profile Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Main Card
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          currentUser!.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoleDisplayName(context, currentUser!.role),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Verification Level
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD1FAE5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)!.faydaVerified,
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Stats Row
                      StreamBuilder<List<OrderModel>>(
                        stream: currentUser!.role == UserRole.FARMER
                            ? firestoreService.streamFarmerOrders(currentUser!.uid)
                            : firestoreService.streamBuyerOrders(currentUser!.uid),
                        builder: (context, orderSnapshot) {
                          return StreamBuilder<List<ProductModel>>(
                            stream: firestoreService.streamFarmerProducts(currentUser!.uid), // For Crops Listed
                            builder: (context, productSnapshot) {
                              final orders = orderSnapshot.data ?? [];
                              final products = productSnapshot.data ?? [];
                              
                              if (currentUser!.role == UserRole.FARMER) {
                                final cropsListed = products.length;
                                final totalSoldKg = orders.fold<double>(0, (prev, o) => prev + o.quantityKg);
                                final earnings = orders.fold<double>(0, (prev, o) => prev + o.totalAmount);
                                
                                String volumeStr = totalSoldKg >= 1000 
                                  ? '${(totalSoldKg / 1000).toStringAsFixed(1)}${AppLocalizations.of(context)!.ton}' 
                                  : '${totalSoldKg.toInt()}${AppLocalizations.of(context)!.kg}';

                                return Row(
                                  children: [
                                    _StatBox(value: cropsListed.toString(), label: AppLocalizations.of(context)!.cropsListed),
                                    const SizedBox(width: 12),
                                    _StatBox(value: volumeStr, label: AppLocalizations.of(context)!.totalSold),
                                    const SizedBox(width: 12),
                                    _StatBox(value: '${NumberFormat.compact().format(earnings)} ETB', label: AppLocalizations.of(context)!.earnings),
                                  ],
                                );
                              } else {
                                // Buyer or other role
                                final ordersCount = orders.length;
                                final totalVolumeKg = orders.fold<double>(0, (prev, o) => prev + o.quantityKg);
                                
                                String volumeStr = totalVolumeKg >= 1000 
                                    ? '${(totalVolumeKg / 1000).toStringAsFixed(1)}${AppLocalizations.of(context)!.ton}' 
                                    : '${totalVolumeKg.toInt()}${AppLocalizations.of(context)!.kg}';

                                return Row(
                                  children: [
                                    _StatBox(value: ordersCount.toString(), label: AppLocalizations.of(context)!.ordersPlaced),
                                    const SizedBox(width: 12),
                                    _StatBox(value: volumeStr, label: AppLocalizations.of(context)!.totalVolume),
                                    const SizedBox(width: 12),
                                    _StatBox(value: currentUser!.rating.toStringAsFixed(1), label: AppLocalizations.of(context)!.avgRating),
                                  ],
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Floating Avatar
                Positioned(
                  top: 0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF409167),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

          // Contact Information
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.contactInfo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InformationSection(
                    children: [
                      _ContactTile(
                        icon: Icons.phone_outlined,
                        label: AppLocalizations.of(context)!.phoneNumber,
                        value: currentUser!.phone ?? 'N/A',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ContactTile(
                        icon: Icons.mail_outline,
                        label: AppLocalizations.of(context)!.emailAddress,
                        value: currentUser!.email ?? 'N/A',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ContactTile(
                        icon: Icons.location_on_outlined,
                        label: AppLocalizations.of(context)!.location,
                        value: AppLocalizations.of(context)!.addisAbaba,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Account Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.accountDetails,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      AppLocalizations.of(context)!.accountDetails,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                  ),
                  _InformationSection(
                    children: [
                      _ContactTile(
                        icon: Icons.calendar_today_outlined,
                        label: AppLocalizations.of(context)!.memberSince,
                        value: 'Oct 2023',
                      ),
                      _ContactTile(
                        icon: Icons.verified_user_outlined,
                        label: AppLocalizations.of(context)!.verificationLevel,
                        value: AppLocalizations.of(context)!.fullVerification,
                      ),
                    ],
                  ),                ],
              ),
            ),
          ),

          // Identity & Security
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.identitySecurity,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.verificationStatus,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A4F),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF74C69D),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.verifiedAccess,
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.shield_outlined, color: Color(0xFF2D6A4F)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logout Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD8F3DC),
                  foregroundColor: const Color(0xFF1B4332),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.signOut,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: Colors.white, size: 28);
  }
}

class _NotificationBadge extends StatelessWidget {
  final int count;

  const _NotificationBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Icon(Icons.notifications_none, color: Colors.white, size: 32),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFF409167),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2D6A4F), width: 2),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFD8F3DC).withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B4332),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationSection extends StatelessWidget {
  final List<Widget> children;

  const _InformationSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFD8F3DC).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2D6A4F), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

