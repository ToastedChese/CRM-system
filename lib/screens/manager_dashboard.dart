import 'package:flutter/material.dart';
import 'manager_profile_screen.dart';
import 'manager_messages_screen.dart';
import 'manage_users_screen.dart';
import 'customer_requests_screen.dart';

// KPI target screens (file-name imports)
import 'active_projects.dart';
import 'team_performance.dart';
import 'customer_satisfaction.dart';
import 'new_leads.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;
  static const Color mainBlue = Color(0xFF182D53);

  final List<Widget> _pages = const [
    _ManagerHomePage(),
    ManagerMessagesScreen(),
    ManageUsersScreen(),
    CustomerRequestsScreen(),
    ManagerProfileScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manager Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: mainBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Manage'),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------------ MANAGER HOME PAGE (Private Widget) ------------------------
class _ManagerHomePage extends StatelessWidget {
  const _ManagerHomePage();
  static const Color mainBlue = Color(0xFF182D53);

  @override
  Widget build(BuildContext context) {
    final kpiData = {
      'active_projects': '12',
      'customer_satisfaction': '92%',
      'team_performance': 'Excellent',
      'new_leads': '8',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 16),

          // KPI grid (tappable cards)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildKpiCard(
                context,
                title: 'Active Projects',
                value: kpiData['active_projects']!,
                icon: Icons.folder,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ActiveProjectsScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'Customer Satisfaction',
                value: kpiData['customer_satisfaction']!,
                icon: Icons.sentiment_satisfied,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CustomerSatisfactionScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'Team Performance',
                value: kpiData['team_performance']!,
                icon: Icons.star,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TeamPerformanceScreen(),
                  ),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'New Leads This Week',
                value: kpiData['new_leads']!,
                icon: Icons.show_chart,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewLeadsScreen()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            'New service request from "TechCorp" was assigned to Jane Doe.',
          ),
          _buildActivityItem(
            'Employee "John Smith" completed a task for "Innovate LLC".',
          ),
          _buildActivityItem(
            'A new customer "Global Solutions" was successfully onboarded.',
          ),
        ],
      ),
    );
  }

  /// Tappable KPI card
  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: mainBlue),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: mainBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: const Icon(Icons.history, color: mainBlue),
        title: Text(activity, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
