class Customer {
  final String customerId;
  final String? userId; // <- nullable
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? customerType;
  final DateTime dateCreated;

  Customer({
    required this.customerId,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.customerType,
    required this.dateCreated,
  });

 factory Customer.fromJson(Map<String, dynamic> json) {
  return Customer(
    customerId: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString(),
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    email: json['email'] ?? '',
    phone: json['phone'] as String?,
    address: json['address'] as String?,
    customerType: json['customer_type'] as String?,
    dateCreated: json['date_created'] != null
        ? DateTime.parse(json['date_created'])
        : DateTime.now(),
  );
}

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'customer_type': customerType,
      'date_created': dateCreated.toIso8601String(),
    };
  }
}
