import 'package:flutter/material.dart';
import 'package:powerlink_crm/services/authentication.dart'; // Import the AuthService
import 'package:powerlink_crm/screens/appearance_screen.dart';

class CustomerSettingsScreen extends StatelessWidget {
  const CustomerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ListView(
      children: [
        const SizedBox(height: 20),
        _buildSettingsTile(
          context,
          icon: Icons.subscriptions_outlined,
          title: 'Manage Subscription',
          subtitle: 'View your plan, billing history, and invoices',
          onTap: () {
            print("Navigate to Subscription Management");
          },
        ),
        _buildSettingsTile(
          context,
          icon: Icons.payment_outlined,
          title: 'Payment Information',
          subtitle: 'Update your credit card or other payment methods',
          onTap: () {
            print("Navigate to Payment Information");
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
          subtitle: 'Change your password and manage account security',
          onTap: () {
            print("Navigate to Customer Security");
          },
        ),
        const Divider(height: 40, thickness: 1),
        _buildSettingsTile(
          context,
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          onTap: () async {
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
    final theme = Theme.of(context);
    final tileColor = color ?? theme.textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: tileColor),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(color: color?.withOpacity(0.8)),
      ),
      onTap: onTap,
    );
  }
}
