import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../marketplace/marketplace_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/farmer_wallet_screen.dart';
import '../orders/my_orders_screen.dart';
import '../profile/profile_screen.dart';
import '../logistics/agent_home_screen.dart';
import '../logistics/transporter_home_screen.dart';
import '../admin/escrow_release_screen.dart';
import '../../models/user_role.dart';

import 'package:agrilink/l10n/generated/app_localizations.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _error = null);
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.getCurrentUserData();

      // Also process expired orders on app startup
      if (user != null) {
        final fs = Provider.of<FirestoreService>(context, listen: false);
        fs.processExpiredOrders();
      }

      if (mounted) {
        if (user == null) {
          setState(() => _error = 'User profile not found. Please log in again.');
        } else {
          setState(() => _currentUser = user);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show error state with retry option
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC2626)),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load user data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadUserData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Transporters get their own full 4-tab home screen
    if (_currentUser!.role == UserRole.TRANSPORTER) {
      return TransporterHomeScreen(currentUser: _currentUser);
    }

    // Agents get their own dedicated 4-tab home screen
    if (_currentUser!.role == UserRole.AGENT) {
      return AgentHomeScreen(currentUser: _currentUser);
    }

    // Admin: 3-tab layout (Escrow Release + User Overview + Profile)
    if (_currentUser!.role == UserRole.ADMIN) {
      return _buildAdminLayout();
    }

    // Farmer: 3-tab layout (My Farm + Marketplace + Wallet)
    if (_currentUser!.role == UserRole.FARMER) {
      return _buildFarmerLayout();
    }

    // Buyer: 4-tab layout (Dashboard + Marketplace + Orders + Profile)
    return _buildBuyerLayout();
  }

  // ═══════════════════════════════════════════════════════════════════
  // FARMER LAYOUT: My Farm | Marketplace | Wallet
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildFarmerLayout() {
    final screens = [
      DashboardScreen(currentUser: _currentUser),
      const MarketplaceScreen(),
      const FarmerWalletScreen(),
      ProfileScreen(currentUser: _currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, screens.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.grass_outlined),
            activeIcon: const Icon(Icons.grass),
            label: AppLocalizations.of(context)!.myFarm,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: AppLocalizations.of(context)!.market,
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D6A4F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUYER LAYOUT: Dashboard | Marketplace | Orders | Profile
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBuyerLayout() {
    final screens = [
      DashboardScreen(currentUser: _currentUser),
      const MarketplaceScreen(),
      MyOrdersScreen(currentUser: _currentUser),
      ProfileScreen(currentUser: _currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, screens.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: AppLocalizations.of(context)!.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: AppLocalizations.of(context)!.market,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            activeIcon: const Icon(Icons.assignment),
            label: AppLocalizations.of(context)!.orders,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D6A4F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADMIN LAYOUT: Escrow Release | Users | Profile
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildAdminLayout() {
    final screens = [
      const EscrowReleaseScreen(),
      _AdminOverviewTab(currentUser: _currentUser),
      ProfileScreen(currentUser: _currentUser),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex.clamp(0, screens.length - 1),
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex.clamp(0, screens.length - 1),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_open_outlined),
            activeIcon: Icon(Icons.lock_open),
            label: 'Escrow',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2D6A4F),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }
}

/// Simple admin overview showing user stats.
class _AdminOverviewTab extends StatelessWidget {
  final UserModel? currentUser;
  const _AdminOverviewTab({this.currentUser});

  @override
  Widget build(BuildContext context) {
    final fs = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Users & Overview'),
        backgroundColor: const Color(0xFF1B4332),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: fs.streamAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          final farmers = users.where((u) => u.role == UserRole.FARMER).length;
          final buyers = users.where((u) => u.role == UserRole.BUYER).length;
          final transporters = users.where((u) => u.role == UserRole.TRANSPORTER).length;
          final agents = users.where((u) => u.role == UserRole.AGENT).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Platform Users',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatCard(title: 'Total Users', value: '${users.length}', icon: Icons.group, color: const Color(0xFF3B82F6)),
                    _StatCard(title: 'Farmers', value: '$farmers', icon: Icons.agriculture, color: const Color(0xFF10B981)),
                    _StatCard(title: 'Buyers', value: '$buyers', icon: Icons.shopping_cart, color: const Color(0xFFF59E0B)),
                    _StatCard(title: 'Transporters', value: '$transporters', icon: Icons.local_shipping, color: const Color(0xFF8B5CF6)),
                    _StatCard(title: 'Agents', value: '$agents', icon: Icons.support_agent, color: const Color(0xFFEC4899)),
                    _StatCard(
                      title: 'Unverified',
                      value: '${users.where((u) => !u.isVerified).length}',
                      icon: Icons.warning,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Recent Users',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
                const SizedBox(height: 12),
                ...users.take(10).map((user) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: user.isVerified ? const Color(0xFF10B981) : Colors.grey,
                        radius: 18,
                        child: Text(
                          user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              '${user.role.value} • ${user.email ?? user.phone}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      if (user.isVerified)
                        const Icon(Icons.verified, color: Color(0xFF10B981), size: 20)
                      else
                        ElevatedButton(
                          onPressed: () async {
                            await fs.updateUser(user.copyWith(isVerified: true));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${user.fullName} verified ✅')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D6A4F),
                            minimumSize: const Size(70, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text('Verify', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                    ],
                  ),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
