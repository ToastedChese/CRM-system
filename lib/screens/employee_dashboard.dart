import 'package:flutter/material.dart';
import 'employee_profile.dart'; // Use consistent relative import
import 'messages_employee.dart'; // Import the new messages screen

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  // Define a consistent dark blue color from the app's theme
  static const Color _primaryColor = Color(0xFF182D53);
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation for bottom bar items
    switch (index) {
      case 0: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeProfile()),
        );
        break;
      case 1: // Messages
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MessagesEmployeeScreen()),
        );
        break;
      // Add navigation for other items here
      case 2: // Voice AI
        print("Navigate to Voice AI screen");
        break;
      case 3: // Gamify
        print("Navigate to Gamify screen");
        break;
      case 4: // Settings
        print("Navigate to Settings screen");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Employee Dashboard',
          style: TextStyle(color: Colors.white), // Ensure text stands out
        ),
        backgroundColor: _primaryColor, // Use consistent color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Ensure back button is white
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildSectionTitle('Assigned Tasks'),
            _buildTaskList(),
            const SizedBox(height: 20),
            _buildSectionTitle('Customer Leads'),
            _buildLeadsList(),
            const SizedBox(height: 20),
            _buildSectionTitle('Recent Interactions'),
            _buildInteractionsList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // To show all labels
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor, // Active icon color
        unselectedItemColor: Colors.grey[600], // Inactive icon color
        items: const [
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

  Widget _buildHeader() {
    return Row(
      children: [
        // Make the avatar a button to navigate to the profile page
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EmployeeProfile()),
            );
          },
          child: const CircleAvatar(
            radius: 30,
            child: Icon(Icons.person, size: 30),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Alex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor, // Apply consistent color
              ),
            ),
            const Text(
              'Today: October 20, 2025',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: _primaryColor, // Apply consistent color
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    // This is mock data. Replace with your actual data fetching logic.
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

  Widget _buildLeadsList() {
    // This is mock data. Replace with your actual data fetching logic.
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
            leading: const Icon(Icons.person, color: _primaryColor),
            title: Text(lead['name']!),
            subtitle: Text('Source: ${lead['source']}'),
            trailing: Text(lead['status']!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionsList() {
    // This is mock data. Replace with your actual data fetching logic.
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
            leading: Icon(icon, color: _primaryColor),
            title: Text('${i['type']} with ${i['with']}'),
            subtitle: Text('Time: ${i['time']}'),
          ),
        );
      }).toList(),
    );
  }
}
