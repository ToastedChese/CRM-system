class Employee {
  final String employeeId;
  final String? userId; // <- nullable
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? role;
  final DateTime? hireDate;

  Employee({
    required this.employeeId,
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.role,
    this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
  return Employee(
    employeeId: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString(),
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    email: json['email'] ?? '',
    phoneNumber: json['phone_number'] as String?,
    role: json['role'] as String?,
    hireDate: json['hire_date'] != null
        ? DateTime.parse(json['hire_date'])
        : null,
  );
}

  Map<String, dynamic> toMap() {
    return {
      'employee_id': employeeId,
      'user_id': userId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'role': role,
      'hire_date': hireDate?.toIso8601String(),
    };
  }
}
