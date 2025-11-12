class Task {
  final int id;
  final String title;
  final String? description;
  final int assignedTo; // employees.id
  final int assignedBy; // employees.id (manager)
  final DateTime? dueDate;
  final String status; // e.g. 'Pending' | 'In Progress' | 'Completed'

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.assignedBy,
    this.dueDate,
    required this.status,
  });

  factory Task.fromRow(Map<String, dynamic> r) => Task(
    id: r['id'] as int,
    title: r['title'] as String,
    description: r['description'] as String?,
    assignedTo: r['assigned_to'] as int,
    assignedBy: r['assigned_by'] as int,
    dueDate: r['due_date'] != null
        ? DateTime.parse(r['due_date'] as String)
        : null,
    status: (r['status'] as String?) ?? 'Pending',
  );
}