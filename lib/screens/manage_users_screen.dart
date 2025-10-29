import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getDynamicColor(BuildContext context, {bool isPrimary = true}) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    if (isPrimary) {
      return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
    } else {
      return isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dynamicPrimaryColor = _getDynamicColor(context);
    
    // Explicitly set the AppBar background to match the Scaffold's background
    final appBarBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: dynamicPrimaryColor,
          unselectedLabelColor: _getDynamicColor(context, isPrimary: false),
          indicatorColor: dynamicPrimaryColor,
          tabs: const [
            Tab(text: 'Employees', icon: Icon(Icons.badge)),
            Tab(text: 'Customers', icon: Icon(Icons.supervisor_account)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UserList(userType: 'Employee'),
          _UserList(userType: 'Customer'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: dynamicPrimaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String userType;
  const _UserList({required this.userType});

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    final trailingIconColor = Theme.of(context).textTheme.bodySmall?.color;
    final items = userType == 'Employee'
        ? ['John Smith', 'Jane Doe', 'Peter Jones']
        : ['TechCorp', 'Global Solutions', 'Innovate LLC'];

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: dynamicColor,
              child: Text(userType[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(items[index]), // Default color will adapt to theme
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: trailingIconColor),
            onTap: () {},
          ),
        );
      },
    );
  }
}
