import 'package:flutter/material.dart';

class ManagerMessagesScreen extends StatefulWidget {
  const ManagerMessagesScreen({super.key});

  @override
  State<ManagerMessagesScreen> createState() => _ManagerMessagesScreenState();
}

class _ManagerMessagesScreenState extends State<ManagerMessagesScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  // --- Database & Backend Placeholder ---
  /*
  Future<List<Map<String, dynamic>>> _fetchConversations() async {
    // In a real app, you would fetch this from your database (e.g., Firestore)
    // and filter conversations where the manager is a participant.
    // await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      {
        'id': 'chat1',
        'name': 'Alex (Customer)',
        'message': 'Thank you for the quick response!',
        'time': '10:45 AM',
        'isRead': true,
        'avatarUrl': '...'
      },
      {
        'id': 'chat2',
        'name': 'Sales Team Group',
        'message': 'Jane: Meeting confirmed for 2 PM.',
        'time': '9:30 AM',
        'isRead': false,
        'avatarUrl': '...'
      },
    ];
  }
  */
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildConversationTile(
            conversation['name'] as String,
            conversation['message'] as String,
            conversation['time'] as String,
            conversation['isRead'] as bool,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // In a real app, this would open a screen to select a user/group to message.
        },
        backgroundColor: mainBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationTile(String name, String message, String time, bool isRead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: mainBlue,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          message,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            if (!isRead)
              const SizedBox(height: 4),
            if (!isRead)
              const CircleAvatar(
                radius: 5,
                backgroundColor: mainBlue,
              ),
          ],
        ),
        onTap: () {
          // In a real app, this would navigate to the detailed chat screen for this conversation.
          // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(conversationId: ...)));
        },
      ),
    );
  }
}
