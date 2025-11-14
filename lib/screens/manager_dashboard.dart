import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/profile_screen.dart';
import 'package:powerlink_crm/screens/settings_screen.dart';
import 'messages_screen.dart';
import 'manage_users_screen.dart';
import 'customer_requests_screen.dart';

// KPI target screens (file-name imports)
import 'active_projects.dart';
import 'team_performance.dart';
import 'customer_satisfaction.dart';
import 'new_leads.dart';
import 'meetings_screen.dart';
import 'project_create_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    _ManagerHomePage(),
    MessagesScreen(),
    ManageUsersScreen(),
    CustomerRequestsScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Ensure no back button appears
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        selectedFontSize: 12,
        unselectedFontSize: 12,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ------------------------ MANAGER HOME PAGE (Private Widget) ------------------------
class _ManagerHomePage extends StatelessWidget {
  const _ManagerHomePage();

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    // Use a bright, readable accent color for dark mode
    return isDarkMode ? Colors.blueAccent : theme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final kpiData = {
      'active_projects': '12',
      'customer_satisfaction': '92%',
      'team_performance': 'Excellent',
      'new_leads': '8',
    };
    final dynamicColor = _getDynamicColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dynamicColor,
            ),
          ),
          const SizedBox(height: 16),
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
                color: dynamicColor,
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
                color: dynamicColor,
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
                color: dynamicColor,
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
                color: dynamicColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewLeadsScreen()),
                ),
              ),
              _buildKpiCard(
                context,
                title: 'Meetings',
                value: 'Plan & Log',
                icon: Icons.event_note,
                color: dynamicColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MeetingsScreen()),
                ),
              ),
               _buildKpiCard(
                context,
                title: 'Create Project',
                value: 'Start a new project',
                icon: Icons.add_circle_outline,
                color: dynamicColor,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProjectCreateScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: dynamicColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            context,
            'New service request from "TechCorp" was assigned to Jane Doe.',
          ),
          _buildActivityItem(
            context,
            'Employee "John Smith" completed a task for "Innovate LLC".',
          ),
          _buildActivityItem(
            context,
            'A new customer "Global Solutions" was successfully onboarded.',
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String activity) {
    final dynamicColor = _getDynamicColor(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: Icon(Icons.history, color: dynamicColor),
        title: Text(activity, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
