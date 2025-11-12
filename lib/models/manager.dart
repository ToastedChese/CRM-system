// lib/models/manager.dart
class Manager {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String department;
  final String role;

  const Manager({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.department,
    required this.role,
  });

  String get name =>
      [firstName, lastName].where((s) => s.isNotEmpty).join(' ').trim();

  /// Used by authentication or JSON parsing
  factory Manager.fromJson(Map<String, dynamic> json) => Manager.fromRow(json);

  /// Used by Supabase row results
  factory Manager.fromRow(Map<String, dynamic> row) {
    String pick(List<String> keys) =>
        (keys.map((k) => row[k]).firstWhere((v) => v != null, orElse: () => '')
        as String)
            .toString();

    final rawId = row['id'];
    final id = rawId == null ? '' : rawId.toString();

    final first = pick(['first_name', 'FirstName', 'firstName']);
    final last = pick(['last_name', 'LastName', 'lastName']);
    final mail = pick(['email', 'Email']);
    final dept = pick(['department', 'Department']);
    final r = pick(['role', 'Role']);

    return Manager(
      id: id,
      firstName: first,
      lastName: last,
      email: mail,
      department: dept,
      role: r.isEmpty ? 'Manager' : r,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'email': email,
    'department': department,
    'role': role,
  };
}