import 'package:flutter/material.dart';

// --- Database/Service Model (Commented Out) ---
// Mock data models. Replace with your actual data models from your database/backend.
/*
class Message {
  final String sender;
  final String text;
  final DateTime time;
  final bool isRead;

  Message({
    required this.sender,
    required this.text,
    required this.time,
    this.isRead = false,
  });
}

class Conversation {
  final String contactName;
  final String contactImageUrl;
  final List<Message> messages;

  Conversation({
    required this.contactName,
    required this.contactImageUrl,
    required this.messages,
  });

  Message get lastMessage => messages.last;
}

// --- Service to interact with the database (Commented out) ---
class MessagingService {
  // Fetches a list of all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    // Replace with your actual database call
    print("Fetching conversations from the database...");
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    // Mock data
    return [
      Conversation(
        contactName: 'John Smith',
        contactImageUrl: 'assets/images/contact_placeholder_1.png', // Example placeholder
        messages: [
          Message(sender: 'John Smith', text: 'Hey, just checking in on the new proposal.', time: DateTime.now().subtract(const Duration(minutes: 5))),
        ],
      ),
      Conversation(
        contactName: 'Jane Doe',
        contactImageUrl: 'assets/images/contact_placeholder_2.png',
        messages: [
          Message(sender: 'Jane Doe', text: 'Can you send over the report?', time: DateTime.now().subtract(const Duration(hours: 1))),
        ],
      ),
    ];
  }
}
*/

class MessagesEmployeeScreen extends StatefulWidget {
  const MessagesEmployeeScreen({super.key});

  @override
  _MessagesEmployeeScreenState createState() => _MessagesEmployeeScreenState();
}

class _MessagesEmployeeScreenState extends State<MessagesEmployeeScreen> {
  // Use the same primary color for consistency
  static const Color _primaryColor = Color(0xFF182D53);

  // --- State for holding conversation data ---
  // late Future<List<Conversation>> _conversationsFuture;
  // final MessagingService _messagingService = MessagingService();

  @override
  void initState() {
    super.initState();
    // --- Fetch data when the screen loads (Commented Out) ---
    // _conversationsFuture = _messagingService.getConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: _buildConversationList(), // Using mock data for now
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // --- Placeholder for starting a new message ---
          print("New message button tapped");
          // You would typically navigate to a contact selection screen
        },
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add_comment_outlined, color: Colors.white),
      ),
    );
  }

  // --- Widget to build the list using FutureBuilder (Commented Out) ---
  /*
  Widget _buildFutureConversationList() {
    return FutureBuilder<List<Conversation>>(
      future: _conversationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No messages found.'));
        }
        
        final conversations = snapshot.data!;
        return ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            return _buildConversationTile(
              name: conversation.contactName,
              lastMessage: conversation.lastMessage.text,
              time: '10:45 AM', // Format timestamp properly
              isRead: conversation.lastMessage.isRead,
              onTap: () {
                print("Tapped on ${conversation.contactName}'s chat");
                // Navigate to a detailed chat screen
              },
            );
          },
        );
      },
    );
  }
  */

  // Widget that uses mock data for now
  Widget _buildConversationList() {
    // Mock data until backend is connected.
    // Correctly typed and with the syntax error fixed.
    final List<Map<String, Object>> mockConversations = [
      {
        'name': 'John Smith',
        'message': 'Hey, just checking in on the new proposal.',
        'time': '10:45 AM',
        'isRead': false,
      },
      {
        'name': 'Jane Doe',
        'message': 'Can you send over the report?',
        'time': '9:30 AM',
        'isRead': true,
      },
      {
        'name': 'Sales Team',
        'message': "Alex: Don't forget the meeting tomorrow!", // Fixed the apostrophe issue
        'time': 'Yesterday',
        'isRead': false,
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: mockConversations.length,
      separatorBuilder: (context, index) => const Divider(indent: 80, height: 1),
      itemBuilder: (context, index) {
        final conversation = mockConversations[index];
        return _buildConversationTile(
          name: conversation['name'] as String,
          lastMessage: conversation['message'] as String,
          time: conversation['time'] as String,
          isRead: conversation['isRead'] as bool,
          onTap: () {
            print("Tapped on ${conversation['name']}'s chat");
            // Navigate to a detailed chat screen, passing the conversation ID
          },
        );
      },
    );
  }

  Widget _buildConversationTile({
    required String name,
    required String lastMessage,
    required String time,
    required bool isRead,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: const CircleAvatar(
        radius: 28,
        backgroundColor: _primaryColor,
        child: Icon(Icons.person, color: Colors.white, size: 30),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isRead ? Colors.grey[600] : Colors.black87,
          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: isRead ? Colors.grey[600] : _primaryColor,
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          if (!isRead)
            const CircleAvatar(
              radius: 5,
              backgroundColor: _primaryColor,
            )
          else
            const SizedBox(height: 10), // To keep alignment consistent
        ],
      ),
    );
  }
}
