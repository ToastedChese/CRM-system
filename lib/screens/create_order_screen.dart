import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/test_products.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String? _selectedProduct;
  final TextEditingController _quantityController = TextEditingController(text: '1');
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with the first product if available
    if (mockProducts.isNotEmpty) {
      _selectedProduct = mockProducts.first.name;
      _calculateTotal();
    }
    _quantityController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = mockProducts.firstWhere((p) => p.name == _selectedProduct).price;
    setState(() {
      _totalPrice = quantity * price;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProduct,
              items: mockProducts.map((product) {
                return DropdownMenuItem<String>(
                  value: product.name,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProduct = value;
                  _calculateTotal();
                });
              },
              decoration: const InputDecoration(labelText: 'Select a product'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
            const SizedBox(height: 20),
            Text(
              'Total: \$${_totalPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final newOrder = {
                  'product': _selectedProduct,
                  'quantity': int.tryParse(_quantityController.text) ?? 0,
                  'total': _totalPrice,
                };
                Navigator.pop(context, newOrder);
              },
              child: const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
