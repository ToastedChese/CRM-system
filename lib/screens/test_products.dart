class Product {
  final String name;
  final double price;
  final String description;

  const Product({
    required this.name,
    required this.price,
    required this.description,
  });
}

const List<Product> mockProducts = [
  Product(
    name: 'Standard CRM Package',
    price: 49.99,
    description: 'Our foundational CRM solution for small businesses.',
  ),
  Product(
    name: 'Premium CRM Suite',
    price: 89.99,
    description: 'Advanced features for growing businesses, including analytics and automation.',
  ),
  Product(
    name: 'Enterprise CRM Platform',
    price: 149.99,
    description: 'A complete, scalable solution for large organizations with dedicated support.',
  ),
  Product(
    name: 'Cloud Storage - 1TB',
    price: 9.99,
    description: 'Securely store and access your data from anywhere.',
  ),
];
