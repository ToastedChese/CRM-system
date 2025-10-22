import 'package:flutter/material.dart';

class CustomerRequestsScreen extends StatefulWidget {
  const CustomerRequestsScreen({super.key});

  @override
  State<CustomerRequestsScreen> createState() => _CustomerRequestsScreenState();
}

class _CustomerRequestsScreenState extends State<CustomerRequestsScreen> {
  static const Color mainBlue = Color(0xFF182D53);

  // --- Database & Backend Placeholder ---
  /*
  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    // In a real app, you'd fetch this from your database, likely filtering for 'pending' status.
    // final snapshot = await FirebaseFirestore.instance.collection('service_requests').where('status', isEqualTo: 'pending').get();
    // return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }
  */
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, String> request) {
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: mainBlue),
            ),
            const SizedBox(height: 8),
            Text(request['requestType']!, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(request['details']!, style: const TextStyle(fontSize: 14)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date: ${request['date']!}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    TextButton(onPressed: () {}, child: const Text('Assign', style: TextStyle(color: mainBlue))),
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
