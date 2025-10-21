import 'package:flutter/material.dart';
import 'service_request.dart'; // Make sure this exists

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  int _selectedIndex = 0;
  static const Color mainBlue = Color(0xFF2023E8);

  final List<Widget> _pages = const [
    _HomePage(),
    _MessagesPlaceholder(),
    ServiceRequestPage(),
    _ProfilePlaceholder(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: mainBlue,
        elevation: 0,
        title: const Text(
          'Customer Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: mainBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Support'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------------ HOME PAGE ------------------------
class _HomePage extends StatelessWidget {
  const _HomePage();

  static const Color mainBlue = Color(0xFF2023E8);

  @override
  Widget build(BuildContext context) {
    final products = [
      {'name': 'Premium Package', 'description': 'Access to premium tools and reports', 'price': 'R499/month'},
      {'name': 'Standard Package', 'description': 'Basic analytics and insights', 'price': 'R299/month'},
      {'name': 'Consultation Session', 'description': '1-on-1 with an expert', 'price': 'R199/session'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 10),
          _buildActionCard(
            icon: Icons.shopping_bag,
            title: 'My Orders',
            description: 'View and track your past and ongoing orders.',
          ),
          _buildActionCard(
            icon: Icons.store,
            title: 'Browse Products',
            description: 'Explore more products and services available.',
          ),
          _buildActionCard(
            icon: Icons.support_agent,
            title: 'Contact Employee',
            description: 'Reach out to an employee for direct assistance.',
          ),
          const SizedBox(height: 25),
          const Text(
            'Available Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: mainBlue,
            ),
          ),
          const SizedBox(height: 10),
          ...products.map((p) {
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(p['description']!),
                trailing: Text(
                  p['price']!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: mainBlue),
                ),
              ),
            );
          }).toList(),
        ],
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
              'Good Morning, Alex',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainBlue,
              ),
            ),
            Text(
              'Welcome back!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: mainBlue, size: 30),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: mainBlue)),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}

// ------------------------ MESSAGES PLACEHOLDER ------------------------
class _MessagesPlaceholder extends StatelessWidget {
  const _MessagesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Messages tab will be implemented later.'),
    );
  }
}

// ------------------------ PROFILE PLACEHOLDER ------------------------
class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Profile tab will be implemented later.'),
    );
  }
}
