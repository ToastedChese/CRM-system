import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// Convert to StatefulWidget
class BrowseProductsScreen extends StatefulWidget {
  const BrowseProductsScreen({super.key});

  @override
  State<BrowseProductsScreen> createState() => _BrowseProductsScreenState();
}

class _BrowseProductsScreenState extends State<BrowseProductsScreen> {
  // Define a Future to hold the data
  late final Future<List<Map<String, dynamic>>> _productsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch products from the 'products' table where 'is_active' is true
    _productsFuture = Supabase.instance.client
        .from('products')
        .select()
        .eq('is_active', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Products'),
      ),
      // Use a FutureBuilder to handle the async operation
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          // 1. Handle loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Handle error state
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 3. Handle no data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products available at the moment.'));
          }

          // 4. Handle success state
          final products = snapshot.data!;
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final price = product['price'];
              // Handle potential null or non-numeric price values gracefully
              final priceString = (price is num)
                  ? 'R${price.toStringAsFixed(2)}'
                  : 'Price not set';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(
                    product['product_name'] ?? 'Unnamed Product', // Use data from Supabase
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(product['product_description'] ?? 'No description available.'), // Use data from Supabase
                  trailing: Text(priceString),
                  onTap: () {
                    // Optional: Navigate to a product detail screen in the future
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
