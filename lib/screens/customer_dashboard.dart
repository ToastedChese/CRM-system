import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/customer_profile_screen.dart';
import 'package:powerlink_crm/screens/customer_support_screen.dart';
import 'package:powerlink_crm/screens/customer_settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _HomePage(),
    const CustomerSupportScreen(),
    const CustomerProfileScreen(),
    const CustomerSettingsScreen(),
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
        elevation: 0,
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// ------------------------ HOME PAGE ------------------------
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  Stream<List<Map<String, dynamic>>>? _customerStream;
  final _user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _customerStream = Supabase.instance.client
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('email', _user.email!)
          .limit(1);
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

  @override
  Widget build(BuildContext context) {
    if (_customerStream == null) {
      return _buildContent(context, 'Guest');
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _customerStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildContent(context, '...');
        }
        if (snapshot.hasError) {
          return _buildContent(context, 'Friend');
        }
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final customerData = snapshot.data!.first;
          final firstName = customerData['first_name'] ?? 'Friend';
          return _buildContent(context, firstName);
        }
        return _buildContent(context, 'Friend');
      },
    );
  }

  Widget _buildContent(BuildContext context, String firstName) {
    final textTheme = Theme.of(context).textTheme;
    final dynamicColor = _getDynamicColor(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, dynamicColor, firstName),
          const SizedBox(height: 20),
          Text(
            'Quick Actions',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: dynamicColor),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            context,
            icon: Icons.shopping_bag,
            title: 'My Orders',
            description: 'View and track your past and ongoing orders.',
            color: dynamicColor,
          ),
          _buildActionCard(
            context,
            icon: Icons.store,
            title: 'Browse Products',
            description: 'Explore more products and services available.',
            color: dynamicColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color dynamicColor, String firstName) {
    final theme = Theme.of(context);
    final greeting = _getGreeting();

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
              "$greeting, $firstName",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: dynamicColor,
              ),
            ),
            Text(
              'Welcome back!',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(description),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.textTheme.bodySmall?.color),
        onTap: () {},
      ),
    );
  }
}
