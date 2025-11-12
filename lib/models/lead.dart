class Lead {
  final int id;
  final int? customerId;
  final int? assignedEmployeeId;
  final String? source;
  final String? leadStatus;
  final DateTime dateCreated;

  Lead({
    required this.id,
    this.customerId,
    this.assignedEmployeeId,
    this.source,
    this.leadStatus,
    required this.dateCreated,
  });

  factory Lead.fromRow(Map<String, dynamic> r) => Lead(
    id: r['id'] as int,
    customerId: r['customer_id'] as int?,
    assignedEmployeeId: r['assigned_employee_id'] as int?,
    source: r['source'] as String?,
    leadStatus: r['lead_status'] as String?,
    dateCreated: DateTime.parse(r['date_created'] as String),
  );
}