import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Represents a product fetched from the database
class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final int stockQuantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stockQuantity,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['product_id'],
      name: map['product_name'],
      description: map['product_description'] ?? 'No description available.',
      // Ensure price is parsed as a double
      price: (map['price'] as num).toDouble(),
      stockQuantity: map['stock_quantity'],
    );
  }
}

// Represents an item in the customer's order
class OrderItem {
  final Product product;
  int quantity;

  OrderItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final List<OrderItem> _orderItems = [];
  Product? _selectedProduct;
  late Future<List<Product>> _productsFuture;
  final _quantityController = TextEditingController(text: '1');
  final _currencyFormat = NumberFormat.currency(locale: 'en_ZA', symbol: 'R');

  @override
  void initState() {
    super.initState();
    _productsFuture = _fetchProducts();
  }

  // Fetches active products from the Supabase database
  Future<List<Product>> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .eq('is_active', true) // Only fetch active products
          .order('product_name', ascending: true);

      final List<Product> products =
          (response as List).map((data) => Product.fromMap(data)).toList();
      return products;
    } catch (e) {
      // Handle errors gracefully in the UI
      debugPrint('Error fetching products: $e');
      throw Exception('Failed to load products.');
    }
  }

  void _addToOrder() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product first.')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    if (quantity <= 0) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity.')),
      );
      return;
    }
    
    final selectedProductToAdd = _selectedProduct!;

    setState(() {
      // Check if the product is already in the order
      final existingItemIndex =
          _orderItems.indexWhere((item) => item.product.id == selectedProductToAdd.id);

      if (existingItemIndex != -1) {
        // If it exists, just update the quantity
        _orderItems[existingItemIndex].quantity += quantity;
      } else {
        // Otherwise, add it as a new item
        _orderItems.add(OrderItem(product: selectedProductToAdd, quantity: quantity));
      }

      // Reset selection after adding
      _selectedProduct = null;
      _quantityController.text = '1';
    });
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedProductToAdd.name} added to order.')),
      );
  }
  
  void _removeItem(int index){
      setState((){
          _orderItems.removeAt(index);
      });
  }

  double get _totalOrderPrice {
    return _orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // FIX: This function handles saving and navigating back
  void _saveAndReturnOrder() {
    // Convert the List<OrderItem> to the List<Map<String, dynamic>> that the MyOrdersScreen expects.
    final orderDataForReturn = _orderItems.map((item) {
      return {
        'name': item.product.name,
        'quantity': item.quantity,
        'total': item.totalPrice,
      };
    }).toList();

    // Now, pop the screen and pass the correctly formatted data.
    Navigator.of(context).pop(orderDataForReturn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
        actions: [
            // "Done" button to confirm the order
            IconButton(
                icon: const Icon(Icons.check),
                // FIX: It now calls the new save function
                onPressed: _orderItems.isEmpty ? null : _saveAndReturnOrder,
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Product Selection Section ---
            _buildProductSelector(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Add to Order'),
              onPressed: _addToOrder,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // --- Order Summary Section ---
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Expanded(child: _buildOrderSummary()),
            const Divider(),
            _buildOrderTotal(),
          ],
        ),
      ),
    );
  }
  
  // Widget for selecting a product and quantity
  Widget _buildProductSelector() {
    return FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products available.'));
        }

        final products = snapshot.data!;
        
        return Column(
          children: [
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Select a Product',
                border: OutlineInputBorder(),
              ),
              items: products.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  child: Text(product.name),
                );
              }).toList(),
              onChanged: (product) {
                setState(() {
                  _selectedProduct = product;
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Price', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                            _selectedProduct == null
                                ? _currencyFormat.format(0)
                                : _currencyFormat.format(_selectedProduct!.price),
                            style: Theme.of(context).textTheme.titleLarge,
                        )
                    ],
                )
              ],
            )
          ],
        );
      },
    );
  }
  
  // Widget to display the list of items in the current order
  Widget _buildOrderSummary() {
    if (_orderItems.isEmpty) {
      return const Center(
        child: Text(
          'Add products to your order to see them here.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      itemCount: _orderItems.length,
      itemBuilder: (context, index) {
        final item = _orderItems[index];
        return ListTile(
          title: Text(item.product.name),
          subtitle: Text(
              '${item.quantity} x ${_currencyFormat.format(item.product.price)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currencyFormat.format(item.totalPrice),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(index),
              )
            ],
          ),
        );
      },
    );
  }

  // Widget to display the total price of the order
  Widget _buildOrderTotal(){
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                Text(
                    _currencyFormat.format(_totalOrderPrice),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                ),
            ],
        ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
