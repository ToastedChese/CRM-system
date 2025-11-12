import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powerlink_crm/screens/gamify_screen.dart';
import 'package:powerlink_crm/screens/voice_ai_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

// Main stateful widget that acts as the navigation shell
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  // List of the main pages for the dashboard
  static const List<Widget> _pages = <Widget>[
    _DashboardHomePage(), // The main dashboard view
    ProfileScreen(),
    MessagesScreen(),
    VoiceAiScreen(), // Voice AI screen is now part of the main navigation
    GamifyScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    // The navigation is now handled entirely by the IndexedStack.
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        automaticallyImplyLeading: false,
      ),
      // Use IndexedStack to preserve the state of each page when switching
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none),
            activeIcon: Icon(Icons.mic),
            label: 'Voice AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.games_outlined),
            activeIcon: Icon(Icons.games),
            label: 'Gamify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// The content for the "Home" tab of the dashboard
class _DashboardHomePage extends StatefulWidget {
  const _DashboardHomePage();

  @override
  State<_DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<_DashboardHomePage> {
  Stream<Map<String, dynamic>>? _employeeStream;
  final _user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      // Use the actual column names used in the DB and SupabaseService:
      // - primary key column: `employee_id`
      // - link to auth user: `auth_user_id`
      _employeeStream = Supabase.instance.client
          .from('employees')
          .stream(primaryKey: ['employee_id'])
          .eq('auth_user_id', _user.id)
          // the realtime stream returns a List; normalize to a Map (first row or empty map)
          .map((event) {
            final list = event as List;
            if (list.isNotEmpty) {
              return Map<String, dynamic>.from(list.first as Map);
            }
            return <String, dynamic>{};
          });
    }
  }

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : theme.primaryColor;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getCurrentDate() {
    return DateFormat('MMMM d, yyyy').format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Assigned Tasks'),
          _buildTaskList(),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Customer Leads'),
          _buildLeadsList(context),
          const SizedBox(height: 20),
          _buildSectionTitle(context, 'Recent Interactions'),
          _buildInteractionsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();
    final currentDate = _getCurrentDate();
    final dynamicColor = _getDynamicColor(context);

    return StreamBuilder<Map<String, dynamic>>(
        stream: _employeeStream,
        builder: (context, snapshot) {
          String firstName = '...';
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            firstName = snapshot.data!['first_name'] ?? 'Employee';
          } else if (snapshot.connectionState == ConnectionState.done) {
            firstName = 'Employee';
          }

          return Row(
            children: [
              const CircleAvatar(
                radius: 30,
                child: Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, $firstName',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: dynamicColor,
                    ),
                  ),
                  Text(
                    'Today: $currentDate',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          );
        });
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final dynamicColor = _getDynamicColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: dynamicColor,
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final tasks = [
      {'title': 'Follow up with client #123', 'status': 'In Progress'},
      {'title': 'Prepare proposal for new lead', 'status': 'Pending'},
      {'title': 'Team meeting at 3 PM', 'status': 'Completed'},
    ];

    return Column(
      children: tasks.map((task) {
        Color statusColor;
        switch (task['status']) {
          case 'Completed':
            statusColor = Colors.green;
            break;
          case 'In Progress':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            title: Text(task['title']!),
            trailing: Text(
              task['status']!,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeadsList(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    final leads = [
      {'name': 'John Smith', 'source': 'Website Form', 'status': 'New'},
      {'name': 'Jane Doe', 'source': 'Referral', 'status': 'Contacted'},
    ];

    return Column(
      children: leads.map((lead) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(Icons.person, color: dynamicColor),
            title: Text(lead['name']!),
            subtitle: Text('Source: ${lead['source']}'),
            trailing: Text(lead['status']!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionsList(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    final interactions = [
      {'type': 'Call', 'with': 'John Smith', 'time': '10:00 AM'},
      {'type': 'Email', 'with': 'Jane Doe', 'time': 'Yesterday'},
      {'type': 'Meeting', 'with': 'Team', 'time': 'Tomorrow 3 PM'},
    ];

    return Column(
      children: interactions.map((i) {
        IconData icon;
        switch (i['type']) {
          case 'Call':
            icon = Icons.phone;
            break;
          case 'Email':
            icon = Icons.email;
            break;
          default:
            icon = Icons.people;
        }
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(icon, color: dynamicColor),
            title: Text('${i['type']} with ${i['with']}'),
            subtitle: Text('Time: ${i['time']}'),
          ),
        );
      }).toList(),
    );
  }
}
