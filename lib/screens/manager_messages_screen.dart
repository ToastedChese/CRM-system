import 'package:flutter/material.dart';

class ManagerMessagesScreen extends StatefulWidget {
  const ManagerMessagesScreen({super.key});

  @override
  State<ManagerMessagesScreen> createState() => _ManagerMessagesScreenState();
}

class _ManagerMessagesScreenState extends State<ManagerMessagesScreen> {

  final List<Map<String, Object>> _conversations = [
    {
      'name': 'Alex (Customer)',
      'message': 'Thank you for the quick response!',
      'time': '10:45 AM',
      'isRead': true,
    },
    {
      'name': 'Sales Team Group',
      'message': "Jane: Don't forget the 2 PM meeting.",
      'time': '9:30 AM',
      'isRead': false,
    },
     {
      'name': 'John Smith (Employee)',
      'message': 'I have a question about the new leads.',
      'time': 'Yesterday',
      'isRead': true,
    },
  ];

  Color _getDynamicColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return isDarkMode ? Colors.blueAccent : const Color(0xFF182D53);
  }

  @override
  Widget build(BuildContext context) {
    final dynamicColor = _getDynamicColor(context);
    return Scaffold(
      // backgroundColor has been removed to allow theme adaptation
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(
            conversation['name'] as String,
            conversation['message'] as String,
            conversation['time'] as String,
            conversation['isRead'] as bool,
            dynamicColor,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: dynamicColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationTile(String name, String message, String time, bool isRead, Color dynamicColor) {
    final subtitleColor = Theme.of(context).textTheme.bodySmall?.color;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: dynamicColor,
          child: const Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), // Let the theme decide the color
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: subtitleColor), // Use theme's subtitle color
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (!isRead)
              const SizedBox(height: 4),
            if (!isRead)
              CircleAvatar(
                radius: 5,
                backgroundColor: dynamicColor,
              ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
