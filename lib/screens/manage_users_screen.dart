import 'package:flutter/material.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color mainBlue = Color(0xFF182D53);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 0, // Hide the appbar, but keep it for the tab bar
        bottom: TabBar(
          controller: _tabController,
          labelColor: mainBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: mainBlue,
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
        onPressed: () {
          // In a real app, show a dialog or new screen to add a user based on the current tab.
          // final userType = _tabController.index == 0 ? 'Employee' : 'Customer';
          // print('Add new $userType');
        },
        backgroundColor: mainBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ------------------------ USER LIST (Private Widget) ------------------------
class _UserList extends StatelessWidget {
  final String userType;
  const _UserList({required this.userType});

  // --- Database & Backend Placeholder ---
  /*
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    // In a real app, you would fetch users from a specific collection based on userType.
    // final collection = userType == 'Employee' ? 'employees' : 'customers';
    // final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    // return snapshot.docs.map((doc) => doc.data()).toList();
  }
  */

  @override
  Widget build(BuildContext context) {
    // Dummy data
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
              backgroundColor: const Color(0xFF182D53),
              child: Text(userType[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(items[index]),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // In a real app, navigate to a detail screen for this user.
            },
          ),
        );
      },
    );
  }
}
