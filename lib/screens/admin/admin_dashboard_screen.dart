import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../profile/profile_screen.dart';
import '../intro/intro_screen.dart'; // Assuming this exists or will be created/used for logout routing

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    _AdminOverview(),
    _UserManagement(),
    ProfileScreen(), // Admin profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2D6A4F),
        onTap: _onItemTapped,
      ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Platform Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<UserModel>>(
              stream: firestoreService.streamAllUsers(), // Need to implement this in FirestoreService
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final users = snapshot.data!;
                final farmers = users.where((u) => u.role == UserRole.FARMER).length;
                final buyers = users.where((u) => u.role == UserRole.BUYER).length;
                final pendingVerification = users.where((u) => !u.isVerified).length;

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _StatCard(title: 'Total Users', value: users.length.toString(), icon: Icons.group, color: Colors.blue),
                    _StatCard(title: 'Farmers', value: farmers.toString(), icon: Icons.agriculture, color: Colors.green),
                    _StatCard(title: 'Buyers', value: buyers.toString(), icon: Icons.shopping_cart, color: Colors.orange),
                    _StatCard(title: 'Pending Verification', value: pendingVerification.toString(), icon: Icons.verified_user, color: Colors.red),
                  ],
                );
              },
            ),
          ],
        ),
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _UserManagement extends StatelessWidget {
  const _UserManagement();

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: user.isVerified ? Colors.green : Colors.grey,
                  child: Text(user.fullName[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(user.fullName),
                subtitle: Text('${user.role.value} • ${user.email ?? user.phone ?? "No contact"}'),
                trailing: user.isVerified
                    ? const Icon(Icons.verified, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () async {
                           await firestoreService.updateUser(user.copyWith(isVerified: true));
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text('${user.fullName} verified successfully')),
                             );
                           }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D6A4F)),
                        child: const Text('Verify'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
