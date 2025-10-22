import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text('PowerLink CRM', style: TextStyle(color: Colors.white, fontSize: 22)),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () => Navigator.pushNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: Icon(Icons.people),
            title: Text('Customers'),
            onTap: () => Navigator.pushNamed(context, '/customers'),
          ),
          ListTile(
            leading: Icon(Icons.add),
            title: Text('Add Customer'),
            onTap: () => Navigator.pushNamed(context, '/addCustomer'),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Visits'),
            onTap: () => Navigator.pushNamed(context, '/visits'),
          ),
          ListTile(
            leading: Icon(Icons.chat),
            title: Text('Help Chat'),
            onTap: () => Navigator.pushNamed(context, '/helpChat'),
          ),
          ListTile(
            leading: Icon(Icons.analytics),
            title: Text('Reports'),
            onTap: () => Navigator.pushNamed(context, '/reports'),
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }
}
