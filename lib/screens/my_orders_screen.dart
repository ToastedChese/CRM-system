import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/create_order_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Placeholder for orders. In a real app, you'd fetch this from a database.
  final List<Map<String, dynamic>> _orders = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('You have no active orders.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      final newOrder = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
                      );
                      if (newOrder != null) {
                        setState(() {
                          _orders.add(newOrder);
                        });
                      }
                    },
                    child: const Text('Create New Order'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return ListTile(
                  title: Text(order['product'] ?? 'N/A'),
                  subtitle: Text('Quantity: ${order['quantity']}'),
                  trailing: Text('Total: \$${order['total'].toStringAsFixed(2)}'),
                );
              },
            ),
    );
  }
}
