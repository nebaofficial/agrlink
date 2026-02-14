import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../marketplace/marketplace_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/my_orders_screen.dart';
import '../profile/profile_screen.dart';
import '../logistics/delivery_dashboard_screen.dart';
import '../../models/user_role.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/language_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.getCurrentUserData();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  List<Widget> _screens() {
    if (_currentUser?.role == null) return [];
    
    final role = _currentUser!.role;
    if (role == UserRole.ADMIN) {
      return [
        const AdminDashboardScreen(),
      ];
    }
    
    final List<Widget> screens = [
      DashboardScreen(currentUser: _currentUser),
      const MarketplaceScreen(),
    ];

    if (role == UserRole.TRANSPORTER || role == UserRole.AGENT) {
      screens.add(const DeliveryDashboardScreen());
    } else if (role == UserRole.BUYER) {
      screens.add(MyOrdersScreen(currentUser: _currentUser));
    }
    // Farmer explicitly avoids this section per user request

    screens.add(ProfileScreen(currentUser: _currentUser));
    return screens;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_currentUser!.role == UserRole.ADMIN) {
       return const AdminDashboardScreen();
    }

    final isLogisticsUser = _currentUser!.role == UserRole.TRANSPORTER || 
                           _currentUser!.role == UserRole.AGENT;
    final isBuyer = _currentUser!.role == UserRole.BUYER;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(_currentUser?.role == UserRole.FARMER ? Icons.grass_outlined : Icons.dashboard_outlined),
            activeIcon: Icon(_currentUser?.role == UserRole.FARMER ? Icons.grass : Icons.dashboard),
            label: _currentUser?.role == UserRole.FARMER 
                ? AppLocalizations.of(context)!.myFarm
                : AppLocalizations.of(context)!.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.store_outlined),
            activeIcon: const Icon(Icons.store),
            label: AppLocalizations.of(context)!.market,
          ),
          if (isLogisticsUser)
            BottomNavigationBarItem(
              icon: const Icon(Icons.local_shipping_outlined),
              activeIcon: const Icon(Icons.local_shipping),
              label: AppLocalizations.of(context)!.logistics,
            )
          else if (isBuyer)
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
}
