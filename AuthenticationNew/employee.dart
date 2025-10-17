class Employee {
  final String employeeID;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String role;
  final String hireDate;

  Employee({
    required this.employeeID,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.hireDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeID: json['EmployeeID'],
      firstName: json['FirstName'],
      lastName: json['LastName'],
      email: json['Email'],
      phoneNumber: json['PhoneNumber'],
      role: json['Role'],
      hireDate: json['HireDate'],
    );
  }
}