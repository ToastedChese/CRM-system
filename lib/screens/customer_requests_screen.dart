import 'package:flutter/material.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {

  final List<Map<String, String>> _requests = [
    {
      'customer': 'TechCorp',
      'requestType': 'Technical Support',
      'details': 'Server is down, need immediate assistance.',
      'date': '2024-07-30',
    },
    {
      'customer': 'Global Solutions',
      'requestType': 'Billing Inquiry',
      'details': 'Question about the last invoice.',
      'date': '2024-07-29',
    },
    {
      'customer': 'Innovate LLC',
      'requestType': 'New Feature Request',
      'details': 'Requesting an export-to-CSV feature.',
      'date': '2024-07-29',
    },
  ];

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The background now correctly adapts to the theme.
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request, _getDynamicColor(context));
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, String> request, Color dynamicColor) {
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request['customer']!,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dynamicColor),
            ),
            const SizedBox(height: 8),
            Text(request['requestType']!, style: TextStyle(fontWeight: FontWeight.w600, color: subtitleColor)),
            const SizedBox(height: 4),
            Text(request['details']!, style: const TextStyle(fontSize: 14)), // Default color adapts to theme
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${request['date']!}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    TextButton(onPressed: () {}, child: Text('Assign', style: TextStyle(color: dynamicColor))),
                    TextButton(onPressed: () {}, child: const Text('Resolve', style: TextStyle(color: Colors.green))),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
