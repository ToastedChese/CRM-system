import 'package:flutter/foundation.dart';

class Customer {
  final int customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? customerType;
  final DateTime dateCreated;

  Customer({
    required this.customerId,
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
      customerId: json['customer_id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      customerType: json['customer_type'] as String?,
      dateCreated: DateTime.parse(json['date_created'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customer_id': customerId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'customer_type': customerType,
      'date_created': dateCreated.toIso8601String(),
    };
  }

  Customer copyWith({
    int? customerId,
    String? firstName,
    String? lastName,
    String? email,
    ValueGetter<String?>? phone,
    ValueGetter<String?>? address,
    ValueGetter<String?>? customerType,
    DateTime? dateCreated,
  }) {
    return Customer(
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone != null ? phone() : this.phone,
      address: address != null ? address() : this.address,
      customerType: customerType != null ? customerType() : this.customerType,
      dateCreated: dateCreated ?? this.dateCreated,
    );
  }
}
