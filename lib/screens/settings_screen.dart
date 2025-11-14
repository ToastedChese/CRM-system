import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/forgotten_password_screen.dart';
import 'package:powerlink_crm/screens/notification_settings_screen.dart';
import 'package:powerlink_crm/services/authentication.dart'; // Import the AuthService
import 'package:powerlink_crm/services/notification_service.dart'; // Import the NotificationService
import 'appearance_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ListView(
      children: [
        const SizedBox(height: 20),
        _buildSettingsTile(
          context,
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Manage push notifications and email alerts',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.palette_outlined,
          title: 'Appearance',
          subtitle: 'Switch between light and dark mode',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppearanceScreen()),
            );
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.security_outlined,
          title: 'Security',
          subtitle: 'Change your password',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ForgottenPassword()),
            );
          },
        ),
        const Divider(height: 40, thickness: 1),
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: () async {
            // Clear recent notifications before signing out to ensure no data leaks between sessions.
            await NotificationService().clearRecentNotifications();

            await authService.signOut();
            
            if (!context.mounted) return;

            // Clear all screens and push the StartScreen as the new home.
            Navigator.of(context).pushNamedAndRemoveUntil('/start', (Route<dynamic> route) => false);
          },
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final tileColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: tileColor),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}
