// lib/models/employee.dart
class Employee {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  const Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  String get name =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  /// For JSON parsing or Supabase data
  factory Employee.fromJson(Map<String, dynamic> json) =>
      Employee.fromRow(json);

  /// Flexible factory that reads lowercase or uppercase DB columns.
  factory Employee.fromRow(Map<String, dynamic> row) {
    String pick(List<String> keys) =>
        (keys.map((k) => row[k]).firstWhere((v) => v != null, orElse: () => ' '))
            .toString();

    // ✅ Handles both 'id' and 'employee_id' as primary key
    final rawId = row['id'] ?? row['employee_id'];
    final id = rawId == null ? '' : rawId.toString();

    final first = pick(['first_name', 'FirstName', 'firstName']);
    final last = pick(['last_name', 'LastName', 'lastName']);
    final mail = pick(['email', 'Email']);
    final r = pick(['role', 'Role']);

    return Employee(
      id: id,
      firstName: first,
      lastName: last,
      email: mail,
      role: r,
    );
  }

  Map<String, dynamic> toJson() => {
    // ✅ Use lowercase keys to match DB convention
    'employee_id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'role': role,
  };
}
