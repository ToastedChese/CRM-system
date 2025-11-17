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
    VoiceAIScreen(),
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

  List<Map<String, dynamic>> _recentInteractions = [];
  List<Map<String, dynamic>> _newLeads = [];
  List<Map<String, dynamic>> _assignedProjects = [];

  bool _loadingInteractions = true;
  bool _loadingLeads = true;
  bool _loadingProjects = true;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        _loadAllData();
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadRecentInteractions(),
      _loadNewLeads(),
      _loadAssignedProjects(),
    ]);
  }

  Future<void> _loadRecentInteractions() async {
  final uid = _userId;
  if (uid == null) {
    setState(() => _loadingInteractions = false);
    return;
  }

  try {
    // Get the employee_id for the current logged-in user
    final empResp = await Supabase.instance.client
        .from('employees')
        .select('employee_id')
        .eq('auth_user_id', uid) // use non-null uid
        .maybeSingle();

    final employeeId = empResp?['employee_id'];
    if (employeeId == null) {
      setState(() => _loadingInteractions = false);
      return;
    }

    // Fetch recent interactions
    final response = await Supabase.instance.client
        .from('employee_recentinteractions')
        .select('*')
        .eq('employee_id', employeeId) // employeeId is int
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
    if (mounted) setState(() => _loadingInteractions = false);
  }
}

  Future<void> _loadNewLeads() async {
    try {
      final response = await Supabase.instance.client
          .from('customers')
          .select('customer_id, first_name, last_name, phone, created_at')
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() {
          _newLeads = List<Map<String, dynamic>>.from(response);
          _loadingLeads = false;
        });
      }
    } catch (e) {
      print("Error loading new leads: $e");
      if (mounted) setState(() => _loadingLeads = false);
    }
  }

  Future<void> _loadAssignedProjects() async {
    final uid = _userId;
    if (uid == null) {
      setState(() => _loadingProjects = false);
      return;
    }

    try {
      // Correct query for UUID filtering
      final response = await Supabase.instance.client
          .from('project_assignments')
          .select('project_id, projects(id, name, description, status, starts_at, due_date)')
          .eq('assignee_user_id', uid);

      if (mounted) {
        setState(() {
          _assignedProjects = List<Map<String, dynamic>>.from(response);
          _loadingProjects = false;
        });
      }
    } catch (e) {
      print("Error loading assigned projects: $e");
      if (mounted) setState(() => _loadingProjects = false);
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${diff.inDays}d";
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

  Widget _buildAssignedProjectsList(Color dynamicColor) {
    if (_loadingProjects) return const Center(child: CircularProgressIndicator());
    if (_assignedProjects.isEmpty) return const Text('No assigned tasks');

    return Column(
      children: _assignedProjects.map((assignment) {
        final project = assignment['projects'];
        final startsAt = project['starts_at'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(project['starts_at']))
            : 'Unknown';
        final dueDate = project['due_date'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(project['due_date']))
            : 'Unknown';
        Color statusColor;
        switch (project['status']) {
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
            title: Text(project['name'] ?? 'Unnamed Task'),
            subtitle: Text('${project['description'] ?? ''}\nStart: $startsAt • Due: $dueDate'),
            trailing: Text(
              project['status'] ?? 'Unknown',
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
    if (_loadingLeads) return const Center(child: CircularProgressIndicator());
    if (_newLeads.isEmpty) return const Text('No new customers');

    return Column(
      children: _newLeads.map((lead) {
        final fullName = '${lead['first_name'] ?? ''} ${lead['last_name'] ?? ''}';
        final createdAt = lead['created_at'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(lead['created_at']))
            : 'Unknown';
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: Icon(Icons.person_add, color: dynamicColor),
            title: Text('New customer joined: $fullName'),
            subtitle: Text('Phone: ${lead['phone'] ?? 'N/A'} • Joined: $createdAt'),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionsList(BuildContext context) {
    if (_loadingInteractions) return const Center(child: CircularProgressIndicator());
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
          _buildAssignedProjectsList(dynamicColor),
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
