import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../profile/profile_screen.dart';
import 'agent_dashboard_tab.dart';
import 'agent_tasks_tab.dart';
import 'agent_reports_tab.dart';

/// Dedicated agent experience with 4-tab bottom navigation.
class AgentHomeScreen extends StatefulWidget {
  final UserModel? currentUser;
  const AgentHomeScreen({super.key, this.currentUser});

  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  int _currentTab = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      AgentDashboardTab(
        currentUser: widget.currentUser,
        onSwitchTab: (index) => setState(() => _currentTab = index),
      ),
      AgentTasksTab(currentUser: widget.currentUser),
      AgentReportsTab(currentUser: widget.currentUser),
      ProfileScreen(currentUser: widget.currentUser),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentTab, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (i) => setState(() => _currentTab = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2D6A4F),
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.task_outlined), activeIcon: Icon(Icons.task), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.assessment_outlined), activeIcon: Icon(Icons.assessment), label: 'Reports'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
