class Customer {
  final String customerID;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String customerType;
  final String dateCreated;

  Customer({
    required this.customerID,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.customerType,
    required this.dateCreated,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerID: json['CustomerID'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      email: json['Email'],
      phone: json['Phone'],
      address: json['Address'],
      customerType: json['CustomerType'],
      dateCreated: json['DateCreated'],
    );
  }
}