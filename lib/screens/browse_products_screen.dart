import 'package:flutter/material.dart';
import 'package:powerlink_crm/screens/test_products.dart';

class BrowseProductsScreen extends StatelessWidget {
  const BrowseProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Products'),
      ),
      body: ListView.builder(
        itemCount: mockProducts.length,
        itemBuilder: (context, index) {
          final product = mockProducts[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(product.description),
              trailing: Text('\$${product.price.toStringAsFixed(2)}'),
              onTap: () {
                // You could navigate to a product detail screen here
              },
            ),
          );
        },
      ),
    );
  }
}
