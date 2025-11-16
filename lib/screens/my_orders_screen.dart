import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/create_order_screen.dart';
import 'package:intl/intl.dart'; // For currency formatting

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  // Each order is a list of product maps. This state now holds a list of orders.
  final List<List<Map<String, dynamic>>> _orders = [];

  // Helper to calculate the total price of a single order
  double _calculateOrderTotal(List<Map<String, dynamic>> orderItems) {
    return orderItems.fold(0.0, (sum, item) {
      final itemTotal = item['total'];
      if (itemTotal is num) {
        return sum + itemTotal;
      }
      return sum;
    });
  }

  // Currency formatter for ZAR
  final currencyFormat = NumberFormat.currency(locale: 'en_ZA', symbol: 'R');

  void _createNewOrder() async {
    final newOrderItems = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
    );

    // If the user created an order, update the state and show a confirmation message.
    if (newOrderItems != null && newOrderItems.isNotEmpty) {
      setState(() {
        _orders.insert(0, newOrderItems); // Add new orders to the top
      });

      // FIX: Show the confirmation message HERE, after the previous screen is gone.
      // This is safe and avoids the '!_debugLocked' crash.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order successfully added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewOrder,
        label: const Text('New Order'),
        icon: const Icon(Icons.add),
      ),
      body: _orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text('You have no active orders.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap the "New Order" button to get started.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 80), // Space for the FAB
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final orderItems = _orders[index];
                final orderTotal = _calculateOrderTotal(orderItems);
                final orderTitle = 'Order #${_orders.length - index}';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 3,
                  child: ListTile(
                    title: Text(orderTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${orderItems.length} items'),
                    trailing: Text(
                      currencyFormat.format(orderTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(orderTitle),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: orderItems.length,
                              itemBuilder: (context, itemIndex) {
                                final item = orderItems[itemIndex];
                                return ListTile(
                                  title: Text(item['name'] as String? ?? 'Unnamed Product'),
                                  subtitle: Text('Quantity: ${item['quantity']}'),
                                  trailing: Text(currencyFormat.format(item['total'] as double? ?? 0.0)),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}