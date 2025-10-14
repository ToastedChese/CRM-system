class Customer {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String dateCreated;
  final int customerSatisfactionScore;

  Customer({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateCreated,
    required this.customerSatisfactionScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Phone': phone,
      'Address': address,
      'DateCreated': dateCreated,
      'CustomerSatisfactionScore': customerSatisfactionScore,
    };
  }
}