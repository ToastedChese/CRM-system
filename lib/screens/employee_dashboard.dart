import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powerlink_crm/screens/gamification.dart';
import 'package:powerlink_crm/screens/tasks_screen.dart';
import 'package:powerlink_crm/screens/new_leads.dart';
import 'package:powerlink_crm/screens/voice_ai_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';
import '../data/supabase_service.dart' as svc; 


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
    MessagesScreen(),
    VoiceAiScreen(), // Voice AI screen is now part of the main navigation
    GamificationScreen(), // Using the new screen
    ProfileScreen(),
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
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Gamify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
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
  final _user = Supabase.instance.client.auth.currentUser;
  String? _firstName;
  int? _employeeId;
  List<Map<String, dynamic>> _recentInteractions = [];
  bool _loadingInteractions = true;
  Timer? _refreshTimer;

  late Future<List<svc.Task>> _tasksFuture;
  late Future<List<Map<String, dynamic>>> _leadsFuture;

  @override
  void initState() {
    super.initState();
    _initEmployee();
    _tasksFuture = svc.SupabaseService.myTasks();
    _leadsFuture = svc.SupabaseService.getLeads();
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
    final uid = _user?.id;
    if (uid == null) return;

    try {
      final empResp = await Supabase.instance.client
          .from('employees')
          .select('employee_id, first_name')
          .eq('auth_user_id', uid)
          .maybeSingle();

      if (mounted && empResp != null) {
        setState(() {
          _employeeId = empResp['employee_id'] as int?;
          _firstName = empResp['first_name'] as String?;
        });
        await _loadRecentInteractions();
      } else if (mounted) {
        setState(() {
          _loadingInteractions = false;
        });
      }
    } catch (e) {
      print('Error fetching employee: $e');
      if (mounted) {
        setState(() {
          _loadingInteractions = false;
        });
      }
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

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inHours < 24) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _fmtDateDynamic(dynamic d) {
    if (d == null) return '';
    final dt = d is DateTime ? d : DateTime.tryParse(d.toString());
    if (dt == null) return '';
    return _fmtDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Assigned Tasks',
            color: dynamicColor,
            onSeeAll: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen()));
            },
          ),
          _buildTaskList(),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Customer Leads',
            color: dynamicColor,
            onSeeAll: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewLeadsScreen()));
            },
          ),
          _buildLeadsList(context),
          const SizedBox(height: 20),
          _SectionHeader(title: 'Recent Interactions', color: dynamicColor),
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
    final displayName = _firstName ?? 'Employee';

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
              '$greeting, $displayName',
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
  }

  Widget _buildTaskList() {
    return FutureBuilder<List<svc.Task>>(
      future: _tasksFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snap.hasError) {
          return _InlineError(
            message: snap.error.toString(),
            onRetry: () => setState(
              () => _tasksFuture = svc.SupabaseService.myTasks(),
            ),
          );
        }
        final items = snap.data ?? const <svc.Task>[];
        if (items.isEmpty) {
          return _EmptyCard(
            icon: Icons.checklist_outlined,
            text: 'No tasks assigned yet',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen())),
          );
        }
        final preview = items.take(3).toList();
        return Column(
          children: preview.map((t) {
            final due = t.dueDate != null
                ? ' • Due ${_fmtDate(t.dueDate!)}'
                : '';
            return ListTile(
              leading: Icon(Icons.checklist_outlined, color: _getDynamicColor(context)),
              title: Text(t.title),
              subtitle: Text('${t.status}$due'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TasksScreen())),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLeadsList(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _leadsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snap.hasError) {
          return _InlineError(
            message: snap.error.toString(),
            onRetry: () => setState(
              () => _leadsFuture = svc.SupabaseService.getLeads(),
            ),
          );
        }
        final items = snap.data ?? const <Map<String, dynamic>>[];
        if (items.isEmpty) {
          return _EmptyCard(
            icon: Icons.person_add_alt_1_outlined,
            text: 'No leads yet — tap to view/create',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewLeadsScreen())),
          );
        }
        final preview = items.take(3).toList();
        return Column(
          children: preview.map((m) {
            final source =
                (m['source'] ?? m['lead_source'] ?? m['leadSource'])
                    ?.toString();
            final leadStatus =
                (m['lead_status'] ?? m['leadStatus'] ?? m['status'])
                    ?.toString();
            final created =
                m['date_created'] ?? m['created_at'] ?? m['dateCreated'];
            return ListTile(
              leading: Icon(
                Icons.person_add_alt_1_outlined,
                color: _getDynamicColor(context),
              ),
              title: Text(source ?? 'Lead'),
              subtitle: Text(
                '${leadStatus ?? 'New'} • ${_fmtDateDynamic(created)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewLeadsScreen())),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildInteractionsList(BuildContext context) {
    if (_loadingInteractions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentInteractions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No recent interactions'),
        ),
      );
    }

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

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error: $message',
            style: TextStyle(color: errorColor),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: accent),
        title: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
