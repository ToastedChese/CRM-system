import 'package:flutter/material.dart';

// Customer messaging screen to interact with employees.
class CustomerMessagesScreen extends StatefulWidget {
  const CustomerMessagesScreen({super.key});

  @override
  State<CustomerMessagesScreen> createState() => _CustomerMessagesScreenState();
}

class _CustomerMessagesScreenState extends State<CustomerMessagesScreen> {
  // Use the same dark blue for consistency.
  static const Color mainBlue = Color(0xFF182D53);

  // --- Mock Data ---
  // This is placeholder data. In a real app, you would fetch this from your database.
  final List<Map<String, dynamic>> _conversations = [
    {
      'name': 'Support Team',
      'message': 'Welcome! How can we help you today?',
      'time': '10:45 AM',
      'isRead': false,
      'avatar': 'S', // Placeholder for avatar
    },
    {
      'name': 'John (Sales Rep)',
      'message': 'Just checking in on your recent inquiry.',
      'time': 'Yesterday',
      'isRead': true,
      'avatar': 'J',
    },
  ];

  /*
  // --- Database Integration Placeholder ---
  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    // TODO: Implement database call to fetch conversation list for the current customer.
    // try {
    //   final userId = FirebaseAuth.instance.currentUser?.uid;
    //   if (userId == null) return;
    //
    //   final snapshot = await FirebaseFirestore.instance
    //       .collection('chats')
    //       .where('participants', arrayContains: userId)
    //       .orderBy('lastMessageTimestamp', descending: true)
    //       .get();
    //
    //   final conversations = snapshot.docs.map((doc) {
    //     // Map Firestore data to your conversation model
    //     return { ...doc.data() };
    //   }).toList();
    //
    //   setState(() {
    //     // _conversations = conversations;
    //   });
    // } catch (e) {
    //   // Handle errors, e.g., show a snackbar
    //   print("Error fetching conversations: $e");
    // }
  }
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: mainBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView.separated(
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: mainBlue,
              child: Text(
                conversation['avatar'],
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              conversation['name'],
              style: TextStyle(
                fontWeight: !(conversation['isRead'] as bool)
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            subtitle: Text(conversation['message']),
            trailing: Text(conversation['time']),
            onTap: () {
              // TODO: Implement navigation to a detailed chat screen.
              // The navigation would pass the conversation/chat ID.
              // Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(chatId: conversation['id'])));
              print("Tapped on ${conversation['name']}'s chat");
            },
          );
        },
      ),
    );
  }
}
