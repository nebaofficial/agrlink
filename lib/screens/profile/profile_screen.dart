import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../models/delivery_model.dart';
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
    if (currentUser != null) {
      return _buildProfile(context, currentUser!);
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    
    return FutureBuilder<UserModel?>(
      future: authService.getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Error loading profile data')),
          );
        }

        return _buildProfile(context, snapshot.data!);
      },
    );
  }

  Widget _buildProfile(BuildContext context, UserModel currentUser) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    final primaryColor = const Color(0xFF2D6A4F);
    final backgroundColor = const Color(0xFFF9FAFB);

    // Build real location string
    String locationStr = 'Not set';
    if (currentUser.address != null && currentUser.address!.isNotEmpty) {
      locationStr = currentUser.address!;
      if (currentUser.city != null && currentUser.city!.isNotEmpty) {
        locationStr += ', ${currentUser.city}';
      }
    } else if (currentUser.city != null && currentUser.city!.isNotEmpty) {
      locationStr = currentUser.city!;
    }

    // Real member since date
    final memberSince = DateFormat('MMM yyyy').format(currentUser.createdAt);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header with Logo Background
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 60,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Background logo watermark
                  Positioned(
                    right: -20,
                    bottom: -10,
                    child: Opacity(
                      opacity: 0.08,
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                ),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 24,
                                  width: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'AgriLink',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.language, color: Colors.white, size: 22),
                                  tooltip: 'Switch Language',
                                  onPressed: () {
                                    final langService = Provider.of<LanguageService>(context, listen: false);
                                    langService.toggleLanguage();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Language: ${langService.locale.languageCode == 'am' ? 'አማርኛ' : 'English'}'),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                  tooltip: 'Notifications',
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('No new notifications'),
                                        backgroundColor: primaryColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
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
                          currentUser.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getRoleDisplayName(context, currentUser.role),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                      const SizedBox(height: 24),
                      // Role-specific Stats
                      _buildRoleStats(context, currentUser, firestoreService),
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
                        value: currentUser.phone.isNotEmpty ? currentUser.phone : 'N/A',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ContactTile(
                        icon: Icons.mail_outline,
                        label: AppLocalizations.of(context)!.emailAddress,
                        value: currentUser.email ?? 'N/A',
                      ),
                      const Divider(height: 1, indent: 56),
                      _ContactTile(
                        icon: Icons.location_on_outlined,
                        label: AppLocalizations.of(context)!.location,
                        value: locationStr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Account Details (single header, not duplicate)
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
                  _InformationSection(
                    children: [
                      _ContactTile(
                        icon: Icons.calendar_today_outlined,
                        label: AppLocalizations.of(context)!.memberSince,
                        value: memberSince,
                      ),
                      _ContactTile(
                        icon: Icons.verified_user_outlined,
                        label: AppLocalizations.of(context)!.verificationLevel,
                        value: 'Verified',
                      ),
                    ],
                  ),
                ],
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

          // Role-Specific Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
              child: _buildRoleSection(context, currentUser),
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

  Widget _buildRoleStats(BuildContext context, UserModel currentUser, FirestoreService firestoreService) {
    switch (currentUser.role) {
      case UserRole.FARMER:
        return StreamBuilder<List<OrderModel>>(
          stream: firestoreService.streamFarmerOrders(currentUser.uid),
          builder: (context, orderSnapshot) {
            return StreamBuilder<List<ProductModel>>(
              stream: firestoreService.streamFarmerProducts(currentUser.uid),
              builder: (context, productSnapshot) {
                final orders = orderSnapshot.data ?? [];
                final products = productSnapshot.data ?? [];
                final cropsListed = products.length;
                final totalSoldKg = orders.fold<double>(0, (prev, o) => prev + o.quantityKg);
                final earnings = orders.fold<double>(0, (prev, o) => prev + o.totalAmount);

                String volumeStr = totalSoldKg >= 1000
                    ? '${(totalSoldKg / 1000).toStringAsFixed(1)}${AppLocalizations.of(context)!.ton}'
                    : '${totalSoldKg.toInt()}${AppLocalizations.of(context)!.kg}';

                return Row(children: [
                  _StatBox(value: cropsListed.toString(), label: AppLocalizations.of(context)!.cropsListed),
                  const SizedBox(width: 12),
                  _StatBox(value: volumeStr, label: AppLocalizations.of(context)!.totalSold),
                  const SizedBox(width: 12),
                  _StatBox(value: '${NumberFormat.compact().format(earnings)} ETB', label: AppLocalizations.of(context)!.earnings),
                ]);
              },
            );
          },
        );

      case UserRole.BUYER:
        return StreamBuilder<List<OrderModel>>(
          stream: firestoreService.streamBuyerOrders(currentUser.uid),
          builder: (context, orderSnapshot) {
            final orders = orderSnapshot.data ?? [];
            final ordersCount = orders.length;
            final totalSpent = orders.fold<double>(0, (prev, o) => prev + o.totalAmount);
            final totalVolumeKg = orders.fold<double>(0, (prev, o) => prev + o.quantityKg);

            String volumeStr = totalVolumeKg >= 1000
                ? '${(totalVolumeKg / 1000).toStringAsFixed(1)}${AppLocalizations.of(context)!.ton}'
                : '${totalVolumeKg.toInt()}${AppLocalizations.of(context)!.kg}';

            return Row(children: [
              _StatBox(value: ordersCount.toString(), label: AppLocalizations.of(context)!.ordersPlaced),
              const SizedBox(width: 12),
              _StatBox(value: volumeStr, label: AppLocalizations.of(context)!.totalVolume),
              const SizedBox(width: 12),
              _StatBox(value: '${NumberFormat.compact().format(totalSpent)} ETB', label: 'Total Spent'),
            ]);
          },
        );

      case UserRole.AGENT:
        return StreamBuilder<List<DeliveryModel>>(
          stream: firestoreService.streamAllDeliveries(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final verified = all.where((d) => d.confirmedByAgent && d.agentId == currentUser.uid).length;
            final pending = all.where((d) => d.status == DeliveryStatus.DELIVERED && !d.confirmedByAgent).length;
            return StreamBuilder<List<OrderModel>>(
              stream: firestoreService.streamAllOrders(),
              builder: (context, orderSnap) {
                final orders = orderSnap.data ?? [];
                final activeOrders = orders.where((o) =>
                    o.status != OrderStatus.COMPLETED && o.status != OrderStatus.CANCELLED).length;
                return Row(children: [
                  _StatBox(value: verified.toString(), label: 'Verified'),
                  const SizedBox(width: 12),
                  _StatBox(value: pending.toString(), label: 'Pending'),
                  const SizedBox(width: 12),
                  _StatBox(value: activeOrders.toString(), label: 'Active Orders'),
                ]);
              },
            );
          },
        );

      case UserRole.TRANSPORTER:
        return StreamBuilder<List<DeliveryModel>>(
          stream: firestoreService.streamTransporterDeliveries(currentUser.uid),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final completed = all.where((d) =>
                d.status == DeliveryStatus.DELIVERED || d.status == DeliveryStatus.CONFIRMED).length;
            final active = all.where((d) =>
                d.status == DeliveryStatus.ASSIGNED ||
                d.status == DeliveryStatus.PICKED_UP ||
                d.status == DeliveryStatus.IN_TRANSIT).length;
            return Row(children: [
              _StatBox(value: all.length.toString(), label: 'Total Jobs'),
              const SizedBox(width: 12),
              _StatBox(value: active.toString(), label: 'Active'),
              const SizedBox(width: 12),
              _StatBox(value: completed.toString(), label: 'Completed'),
            ]);
          },
        );

      default:
        return Row(children: [
          _StatBox(value: '0', label: 'Activity'),
          const SizedBox(width: 12),
          _StatBox(value: '0', label: 'Tasks'),
          const SizedBox(width: 12),
          _StatBox(value: '0', label: 'Rating'),
        ]);
    }
  }

  Widget _buildRoleSection(BuildContext context, UserModel currentUser) {
    final (String title, IconData icon, Color color, List<_RoleItem> items) = switch (currentUser.role) {
      UserRole.AGENT => (
        'Agent Responsibilities',
        Icons.support_agent,
        const Color(0xFF1565C0),
        [
          _RoleItem(Icons.verified_user, 'Verify Farmers', 'Help farmers register and verify identity'),
          _RoleItem(Icons.fact_check, 'Confirm Deliveries', 'Inspect and confirm delivered goods'),
          _RoleItem(Icons.people, 'Resolve Disputes', 'Mediate between buyers and farmers'),
          _RoleItem(Icons.assessment, 'Submit Reports', 'Document field activities and issues'),
        ],
      ),
      UserRole.TRANSPORTER => (
        'Delivery Duties',
        Icons.local_shipping,
        const Color(0xFFE65100),
        [
          _RoleItem(Icons.inventory, 'Pick Up Goods', 'Collect produce from farmer locations'),
          _RoleItem(Icons.route, 'Transport Safely', 'Deliver goods in proper condition'),
          _RoleItem(Icons.camera_alt, 'Proof of Delivery', 'Take photos at pickup and dropoff'),
          _RoleItem(Icons.schedule, 'Timely Delivery', 'Meet estimated delivery windows'),
        ],
      ),
      UserRole.FARMER => (
        'Farm Management',
        Icons.agriculture,
        const Color(0xFF2E7D32),
        [
          _RoleItem(Icons.add_box, 'List Crops', 'Add and manage your crop listings'),
          _RoleItem(Icons.trending_up, 'Track Sales', 'Monitor orders and revenue'),
          _RoleItem(Icons.inventory_2, 'Manage Stock', 'Keep quantities up to date'),
          _RoleItem(Icons.star, 'Build Reputation', 'Fulfill orders to earn ratings'),
        ],
      ),
      UserRole.BUYER => (
        'Buyer Guide',
        Icons.shopping_cart,
        const Color(0xFF6A1B9A),
        [
          _RoleItem(Icons.search, 'Browse Marketplace', 'Find fresh produce from local farmers'),
          _RoleItem(Icons.shopping_bag, 'Place Orders', 'Order directly from verified farmers'),
          _RoleItem(Icons.payment, 'Secure Payment', 'Pay via escrow for safety'),
          _RoleItem(Icons.delivery_dining, 'Track Delivery', 'Follow your order in real-time'),
        ],
      ),
      _ => (
        'Your Role',
        Icons.person,
        const Color(0xFF2D6A4F),
        <_RoleItem>[],
      ),
    };

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == items.length - 1;
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1B4332))),
                        Text(item.subtitle, style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                      ],
                    )),
                  ]),
                ),
                if (!isLast) const Divider(height: 1, indent: 56),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _RoleItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _RoleItem(this.icon, this.title, this.subtitle);
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
