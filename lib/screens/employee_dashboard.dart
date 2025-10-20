import 'package:flutter/material.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  // Custom darkish blue color
  static const Color mainHeadingColor = Color(0xFF2023E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: 20),

            // Tasks Section
            _buildSectionTitle('Assigned Tasks'),
            _buildTaskList(),

            const SizedBox(height: 20),

            // Customer Leads
            _buildSectionTitle('Customer Leads'),
            _buildLeadsList(),

            const SizedBox(height: 20),

            // Customer Interactions
            _buildSectionTitle('Recent Interactions'),
            _buildInteractionsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/profile_placeholder.png'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Welcome, Alex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainHeadingColor, // Apply custom blue here
              ),
            ),
            Text(
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
          color: mainHeadingColor, // Apply custom blue to section titles
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
    final leads = [
      {'name': 'John Smith', 'source': 'Website Form', 'status': 'New'},
      {'name': 'Jane Doe', 'source': 'Referral', 'status': 'Contacted'},
    ];

    return Column(
      children: leads.map((lead) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.blue),
            title: Text(lead['name']!),
            subtitle: Text('Source: ${lead['source']}'),
            trailing: Text(lead['status']!, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractionsList() {
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
          child: ListTile(
            leading: Icon(icon, color: Colors.blueAccent),
            title: Text('${i['type']} with ${i['with']}'),
            subtitle: Text('Time: ${i['time']}'),
          ),
        );
      }).toList(),
    );
  }
}
