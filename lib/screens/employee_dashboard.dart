import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powerlink_crm/screens/gamification.dart';
import 'package:powerlink_crm/screens/tasks_screen.dart';
import 'package:powerlink_crm/screens/new_leads.dart';
import 'package:powerlink_crm/screens/voice_ai_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/supabase_service.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    _DashboardHomePage(),
    MessagesScreen(),
    VoiceAiScreen(),
    GamificationScreen(),
    ProfileScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_outlined),
              activeIcon: Icon(Icons.message),
              label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: 'Voice AI'),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'Gamify'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

class _DashboardHomePage extends StatefulWidget {
  const _DashboardHomePage();

  @override
  State<_DashboardHomePage> createState() => _DashboardHomePageState();
}

class _DashboardHomePageState extends State<_DashboardHomePage> {
  final SupabaseService _svc = SupabaseService();
  String? _userId = Supabase.instance.client.auth.currentUser?.id;
  int? _employeeId;

  List<Map<String, dynamic>> _recentInteractions = [];
  bool _loadingInteractions = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initEmployee();

    // Auto-refresh every 10 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadRecentInteractions(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initEmployee() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final empResp = await Supabase.instance.client
          .from('employees')
          .select('employee_id, first_name')
          .eq('auth_user_id', uid)
          .maybeSingle();

      if (empResp != null) {
        setState(() {
          _employeeId = empResp['employee_id'] as int?;
        });

        await _loadRecentInteractions();
      } else {
        setState(() {
          _employeeId = null;
          _loadingInteractions = false;
        });
      }
    } catch (e) {
      print('Error fetching employee: $e');
      setState(() {
        _loadingInteractions = false;
      });
    }
  }

  Future<void> _loadRecentInteractions() async {
    final empId = _employeeId;
    if (empId == null) return;

    try {
      final response = await Supabase.instance.client
          .from('employee_recentinteractions')
          .select('*')
          .eq('employee_id', empId)
          .order('timestamp', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _recentInteractions = List<Map<String, dynamic>>.from(response);
          _loadingInteractions = false;
        });
      }
    } catch (e) {
      print("Error loading interactions: $e");
      if (mounted) {
        setState(() {
          _loadingInteractions = false;
        });
      }
    }
  }

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.blueAccent
        : theme.primaryColor;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentDate() {
    return DateFormat('MMMM d, yyyy').format(DateTime.now());
  }

  Widget _buildInteractionsList(BuildContext context) {
    if (_loadingInteractions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentInteractions.isEmpty) return const Text('No recent interactions');

    return Column(
      children: _recentInteractions.map((i) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                (i['target_name'] ?? 'U')[0].toUpperCase(),
              ),
            ),
            title: Text(i['target_name'] ?? 'Unknown'),
            subtitle: Text(
              i['description'] ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              i['timestamp'] != null
                  ? _timeAgo(DateTime.parse(i['timestamp']))
                  : '',
            ),
          ),
        );
      }).toList(),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(dynamicColor),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Assigned Tasks',
            color: dynamicColor,
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TasksScreen(),
                ),
              );
            },
          ),
          _buildTaskList(),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Customer Leads',
            color: dynamicColor,
            onSeeAll: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewLeadsScreen(),
                ),
              );
            },
          ),
          _buildLeadsList(dynamicColor),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Recent Interactions', color: dynamicColor),
          _buildInteractionsList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(Color dynamicColor) {
    final greeting = _getGreeting();
    final currentDate = _getCurrentDate();

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
              greeting,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: dynamicColor,
              ),
            ),
            Text('Today: $currentDate'),
          ],
        ),
      ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(task['title']!),
            trailing: Text(
              task['status']!,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeadsList(Color dynamicColor) {
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
            trailing: Text(
              lead['status']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.color,
    this.onSeeAll,
  });

  final String title;
  final Color color;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See all'),
            ),
        ],
      ),
    );
  }
}
