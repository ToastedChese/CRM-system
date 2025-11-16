// ignore_for_file: dead_code, unnecessary_type_check, unnecessary_cast

import 'package:supabase_flutter/supabase_flutter.dart';

//tiny Task model used by the task helpers below.

class Task {
  final int id;
  final String title;
  final String? description;
  final int? assignedTo;
  final int? assignedBy;
  final DateTime? dueDate;
  final String status;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedBy,
    this.dueDate,
    required this.status,
  });

  factory Task.fromRow(Map<String, dynamic> row) => Task(
    id: row['id'] as int,
    title: (row['title'] ?? '').toString(),
    description: row['description'] as String?,
    assignedTo: row['assigned_to'] as int?,
    assignedBy: row['assigned_by'] as int?,
    dueDate: row['due_date'] == null
        ? null
        : DateTime.tryParse(row['due_date'].toString()),
    status: (row['status'] ?? '').toString(),
  );

  
}

class SupabaseService {
  static SupabaseClient get _db => Supabase.instance.client;

  // ------------------------------------------------------------
  // IDENTITY HELPERS
  // ------------------------------------------------------------
  static Future<int?> getMyCustomerId([String? uid]) async {
    final userId = uid ?? _db.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _db
        .from('customers')
        .select('customer_id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    return row == null ? null : (row['customer_id'] as num).toInt();
  }

  static Future<int?> getMyEmployeeId([String? uid]) async {
    final userId = uid ?? _db.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _db
        .from('employees')
        .select('employee_id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    return row == null ? null : (row['employee_id'] as num).toInt();
  }

  static Future<int?> getMyManagerId([String? uid]) async {
    final userId = uid ?? _db.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _db
        .from('managers')
        .select('id')
        .eq('auth_user_id', userId)
        .maybeSingle();
    return row == null ? null : (row['id'] as num).toInt();
  }

  static Future<Map<String, dynamic>?> getMyProfileData() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    // Helper to normalize response which can be a Map (single) or List (multiple)
    Map<String, dynamic>? normalizeResult(Object? res) {
      if (res == null) return null;
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is List && res.isNotEmpty) return Map<String, dynamic>.from(res.first as Map);
      return null;
    }

    // 1. Check if the user is an employee
    try {
      final raw = await _db
          .from('employees')
          .select('employee_id, first_name, last_name, email, role, phone, avatar_url')
          .eq('auth_user_id', uid);
      final res = normalizeResult(raw);
      if (res != null) {
        // Normalize keys: some queries may return `id` or `employee_id` depending on select aliasing
        if (!res.containsKey('employee_id') && res.containsKey('id')) {
          res['employee_id'] = res['id'];
        }
        if (!res.containsKey('id') && res.containsKey('employee_id')) {
          res['id'] = res['employee_id'];
        }
        res['type'] = 'employee';
        return res;
      }
    } catch (e) {
      // If Postgrest throws because multiple rows found or other issues, try a safe fallback
      try {
        final rawList = await _db
            .from('employees')
            .select('employee_id, first_name, last_name, email, role, phone, avatar_url')
            .eq('auth_user_id', uid)
            .limit(1);
        final res = normalizeResult(rawList);
        if (res != null) {
          if (!res.containsKey('employee_id') && res.containsKey('id')) {
            res['employee_id'] = res['id'];
          }
          if (!res.containsKey('id') && res.containsKey('employee_id')) {
            res['id'] = res['employee_id'];
          }
          res['type'] = 'employee';
          return res;
        }
      } catch (_) {}
    }

    // 2. Check if the user is a customer
    try {
      final raw = await _db
          .from('customers')
          .select('customer_id, first_name, last_name, email, phone, avatar_url')
          .eq('auth_user_id', uid);
      final res = normalizeResult(raw);
      if (res != null) {
        if (!res.containsKey('customer_id') && res.containsKey('id')) {
          res['customer_id'] = res['id'];
        }
        if (!res.containsKey('id') && res.containsKey('customer_id')) {
          res['id'] = res['customer_id'];
        }
        res['type'] = 'customer';
        return res;
      }
    } catch (e) {
      try {
        final rawList = await _db
            .from('customers')
            .select('customer_id, first_name, last_name, email, phone, avatar_url')
            .eq('auth_user_id', uid)
            .limit(1);
        final res = normalizeResult(rawList);
        if (res != null) {
          if (!res.containsKey('customer_id') && res.containsKey('id')) {
            res['customer_id'] = res['id'];
          }
          if (!res.containsKey('id') && res.containsKey('customer_id')) {
            res['id'] = res['customer_id'];
          }
          res['type'] = 'customer';
          return res;
        }
      } catch (_) {}
    }

    // 3. Check if the user is a manager
    try {
      final raw = await _db
          .from('managers')
          .select('id, first_name, last_name, email, department, phone, avatar_url')
          .eq('auth_user_id', uid);
      final res = normalizeResult(raw);
      if (res != null) {
        // Manager table primary key is `id` — ensure it's present
        if (!res.containsKey('id') && res.containsKey('manager_id')) {
          res['id'] = res['manager_id'];
        }
        res['type'] = 'manager';
        return res;
      }
    } catch (e) {
      try {
        final rawList = await _db
            .from('managers')
            .select('id, first_name, last_name, email, department, phone, avatar_url')
            .eq('auth_user_id', uid)
            .limit(1);
        final res = normalizeResult(rawList);
        if (res != null) {
          if (!res.containsKey('id') && res.containsKey('manager_id')) {
            res['id'] = res['manager_id'];
          }
          res['type'] = 'manager';
          return res;
        }
      } catch (_) {}
    }

    return null; // No profile found
  }

  // ------------------------------------------------------------
  // EMPLOYEES
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> employees() async {
    final res = await _db
        .from('employees')
        .select(
          'id:employee_id, first_name, last_name, email, role, hire_date, created_at',
        )
        .order('employee_id', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> employeesLite() async {
    final res = await _db
        .from('employees')
        .select('employee_id, first_name, last_name')
        .order('first_name');
    return (res as List).cast<Map<String, dynamic>>();
  }

 
  static Future<Map<String, dynamic>> createEmployee(
    Map<String, dynamic> data,
  ) async {
    final row = <String, dynamic>{
      'first_name': (data['first_name'] ?? data['firstName'] ?? '')
          .toString()
          .trim(),
      'last_name': (data['last_name'] ?? data['lastName'] ?? '')
          .toString()
          .trim(),
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'role': (data['role'] ?? 'employee').toString().trim(),
      if (data.containsKey('hire_date')) 'hire_date': data['hire_date'],
      if (data.containsKey('auth_user_id'))
        'auth_user_id': data['auth_user_id'],
      if (data.containsKey('avatar_url')) 'avatar_url': data['avatar_url'].toString().trim(),
    };
    final res = await _db.from('employees').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateEmployee(
      int id,
      Map<String, dynamic> data,
      ) async {
    final updateRow = <String, dynamic>{
      if (data.containsKey('first_name'))
        'first_name': data['first_name'].toString().trim(),
      if (data.containsKey('last_name'))
        'last_name': data['last_name'].toString().trim(),
      if (data.containsKey('email'))
        'email': data['email'].toString().trim().toLowerCase(),
      if (data.containsKey('phone')) 'phone': data['phone'].toString().trim(),
      if (data.containsKey('avatar_url')) 'avatar_url': data['avatar_url'].toString().trim(),
      if (data.containsKey('role')) 'role': data['role'].toString().trim(),
      if (data.containsKey('hire_date')) 'hire_date': data['hire_date'],
    };
    final res = await _db
        .from('employees')
        .update(updateRow)
        .eq('employee_id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // CUSTOMERS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> customers() async {
    final res = await _db
        .from('customers')
        .select(
          'id:customer_id, first_name, last_name, email, phone, address, customer_type, created_at',
        )
        .order('customer_id', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> data,
  ) async {
    final row = <String, dynamic>{
      'first_name': (data['first_name'] ?? data['firstName'] ?? '')
          .toString()
          .trim(),
      'last_name': (data['last_name'] ?? data['lastName'] ?? '')
          .toString()
          .trim(),
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      if (data['phone'] != null) 'phone': data['phone'].toString().trim(),
      if (data['address'] != null) 'address': data['address'].toString().trim(),
      if (data['customer_type'] != null)
        'customer_type': data['customer_type'].toString().trim(),
      if (data.containsKey('auth_user_id'))
        'auth_user_id': data['auth_user_id'],
    };
    final res = await _db.from('customers').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> customerById(int id) async {
    final row = await _db
        .from('customers')
        .select(
          'id:customer_id, first_name, last_name, email, phone, address, customer_type, created_at',
        )
        .eq('customer_id', id)
        .maybeSingle();
    if (row == null) throw Exception('Customer not found');
    return Map<String, dynamic>.from(row as Map);
  }

  static Future<Map<String, dynamic>> updateCustomer(
    int id,
    Map<String, dynamic> data,
  ) async {
    final updateRow = <String, dynamic>{
      if (data.containsKey('first_name'))
        'first_name': data['first_name'].toString().trim(),
      if (data.containsKey('last_name'))
        'last_name': data['last_name'].toString().trim(),
      if (data.containsKey('email'))
        'email': data['email'].toString().trim().toLowerCase(),
      if (data.containsKey('phone')) 'phone': data['phone'].toString().trim(),
      if (data.containsKey('avatar_url')) 'avatar_url': data['avatar_url'].toString().trim(),
      if (data.containsKey('address'))
        'address': data['address'].toString().trim(),
      if (data.containsKey('customer_type'))
        'customer_type': data['customer_type'].toString().trim(),
    };
    final res = await _db
        .from('customers')
        .update(updateRow)
        .eq('customer_id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // MANAGERS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> managers() async {
    final res = await _db
        .from('managers')
        .select(
          // PK is `id` on your table
          'id, first_name, last_name, email, department, role, hire_date, created_at',
        )
        .order('id', ascending: true);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> managersLite() async {
    final res = await _db
        .from('managers')
        .select('id, first_name, last_name')
        .order('first_name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createManager(
    Map<String, dynamic> data,
  ) async {
    final row = <String, dynamic>{
      'first_name': (data['first_name'] ?? data['firstName'] ?? '')
          .toString()
          .trim(),
      'last_name': (data['last_name'] ?? data['lastName'] ?? '')
          .toString()
          .trim(),
      'email': (data['email'] ?? '').toString().trim().toLowerCase(),
      'department': (data['department'] ?? '').toString().trim(),
      'role': (data['role'] ?? 'manager').toString().trim(),
      if (data.containsKey('hire_date')) 'hire_date': data['hire_date'],
      if (data.containsKey('auth_user_id'))
        'auth_user_id': data['auth_user_id'],
    };
    final res = await _db.from('managers').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateManager(
    int id,
    Map<String, dynamic> data,
  ) async {
    final updateRow = <String, dynamic>{
      if (data.containsKey('first_name'))
        'first_name': data['first_name'].toString().trim(),
      if (data.containsKey('last_name'))
        'last_name': data['last_name'].toString().trim(),
      if (data.containsKey('email'))
        'email': data['email'].toString().trim().toLowerCase(),
      if (data.containsKey('department'))
        'department': data['department'].toString().trim(),
      if (data.containsKey('phone')) 'phone': data['phone'].toString().trim(),
      if (data.containsKey('avatar_url')) 'avatar_url': data['avatar_url'].toString().trim(),
      if (data.containsKey('role')) 'role': data['role'].toString().trim(),
    };
    final res = await _db
        .from('managers')
        .update(updateRow)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // SERVICE TICKETS (includes optional manager_id)
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> serviceTickets() async {
    final res = await _db
        .from('service_tickets')
        .select(
          'id, customer_id, employee_id, manager_id, issue_description, status, date_opened, date_closed',
        )
        .order('id');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> serviceTicketsJoinedAll() async {
    final res = await _db
        .from('service_tickets')
        .select('''
          id, customer_id, employee_id, manager_id,
          issue_description, status, date_opened, date_closed,
          customers:customer_id ( first_name, last_name ),
          employees:employee_id ( first_name, last_name ),
          managers:manager_id ( first_name, last_name )
        ''')
        .order('date_opened', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> serviceTicketsForEmployee(
    int employeeId,
  ) async {
    final res = await _db
        .from('service_tickets')
        .select('''
          id, customer_id, employee_id, manager_id,
          issue_description, status, date_opened, date_closed,
          customers:customer_id ( first_name, last_name )
        ''')
        .eq('employee_id', employeeId)
        .order('date_opened', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> serviceTicketsForManager() async {
    return serviceTicketsJoinedAll();
  }

  static Future<Map<String, dynamic>> createServiceTicket({
    required int customerId,
    int? employeeId,
    int? managerId,
    required String issueDescription,
    String status = 'Open',
    DateTime? dateOpened,
  }) async {
    final row = {
      'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (managerId != null) 'manager_id': managerId,
      'issue_description': issueDescription,
      'status': status,
      'date_opened': (dateOpened ?? DateTime.now().toUtc()).toIso8601String(),
    };
    final res = await _db.from('service_tickets').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateServiceTicket(
    int id, {
    int? customerId,
    int? employeeId,
    int? managerId,
    String? issueDescription,
    String? status,
    DateTime? dateOpened,
    DateTime? dateClosed,
  }) async {
    final upd = <String, dynamic>{
      if (customerId != null) 'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (managerId != null) 'manager_id': managerId,
      if (issueDescription != null) 'issue_description': issueDescription,
      if (status != null) 'status': status,
      if (dateOpened != null)
        'date_opened': dateOpened.toUtc().toIso8601String(),
      if (dateClosed != null)
        'date_closed': dateClosed.toUtc().toIso8601String(),
    };
    final res = await _db
        .from('service_tickets')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> closeServiceTicket(
    int id, {
    DateTime? closedAt,
  }) async {
    final upd = <String, dynamic>{
      'status': 'Closed',
      'date_closed': (closedAt ?? DateTime.now().toUtc()).toIso8601String(),
    };
    final res = await _db
        .from('service_tickets')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // AVATAR LOOKUP BY AUTH USER ID (for chat participants fallback)
  // ------------------------------------------------------------
  static Future<String?> avatarByAuthUserId(String userId) async {
    try {
      final emp = await _db
          .from('employees')
          .select('avatar_url')
          .eq('auth_user_id', userId)
          .limit(1)
          .maybeSingle();
      final empUrl = (emp?['avatar_url'] ?? '').toString();
      if (empUrl.isNotEmpty) return empUrl;
    } catch (_) {}

    try {
      final mgr = await _db
          .from('managers')
          .select('avatar_url')
          .eq('auth_user_id', userId)
          .limit(1)
          .maybeSingle();
      final mgrUrl = (mgr?['avatar_url'] ?? '').toString();
      if (mgrUrl.isNotEmpty) return mgrUrl;
    } catch (_) {}

    try {
      final cust = await _db
          .from('customers')
          .select('avatar_url')
          .eq('auth_user_id', userId)
          .limit(1)
          .maybeSingle();
      final custUrl = (cust?['avatar_url'] ?? '').toString();
      if (custUrl.isNotEmpty) return custUrl;
    } catch (_) {}

    return null;
  }

   static Future<void> assignTicketToEmployee(int ticketId, int employeeId) {
     return _db
         .from('service_tickets')
         .update({'employee_id': employeeId, 'manager_id': null})
         .eq('id', ticketId);
   }

   static Future<void> assignTicketToManager(int ticketId, int managerId) {
     return _db
         .from('service_tickets')
         .update({'manager_id': managerId, 'employee_id': null})
         .eq('id', ticketId);
   }

  // ------------------------------------------------------------
  // CAMPAIGNS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> campaigns() async {
    final res = await _db
        .from('campaigns')
        .select('id, name, start_date, end_date, budget, objective')
        .order('id');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createCampaign({
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    num? budget,
    String? objective,
  }) async {
    final row = {
      'name': name,
      if (startDate != null) 'start_date': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'end_date': endDate.toUtc().toIso8601String(),
      if (budget != null) 'budget': budget,
      if (objective != null) 'objective': objective,
    };
    final res = await _db.from('campaigns').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateCampaign(
    int id, {
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    num? budget,
    String? objective,
  }) async {
    final upd = <String, dynamic>{
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'end_date': endDate.toUtc().toIso8601String(),
      if (budget != null) 'budget': budget,
      if (objective != null) 'objective': objective,
    };
    final res = await _db
        .from('campaigns')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // CAMPAIGN PARTICIPATION
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> campaignParticipation() async {
    final res = await _db
        .from('campaign_participation')
        .select('id, campaign_id, customer_id, engagement_level')
        .order('id');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> addCampaignParticipant({
    required int campaignId,
    required int customerId,
    String? engagementLevel,
  }) async {
    final row = {
      'campaign_id': campaignId,
      'customer_id': customerId,
      if (engagementLevel != null) 'engagement_level': engagementLevel,
    };
    final res = await _db
        .from('campaign_participation')
        .insert(row)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateCampaignParticipant(
    int id, {
    int? campaignId,
    int? customerId,
    String? engagementLevel,
  }) async {
    final upd = <String, dynamic>{
      if (campaignId != null) 'campaign_id': campaignId,
      if (customerId != null) 'customer_id': customerId,
      if (engagementLevel != null) 'engagement_level': engagementLevel,
    };
    final res = await _db
        .from('campaign_participation')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // INTERACTIONS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> interactions() async {
    final res = await _db
        .from('interactions')
        .select('id, customer_id, employee_id, date, interaction_type, notes')
        .order('id');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createInteraction({
    required int customerId,
    required int employeeId,
    DateTime? date,
    String? interactionType,
    String? notes,
  }) async {
    final row = {
      'customer_id': customerId,
      'employee_id': employeeId,
      if (date != null) 'date': date.toUtc().toIso8601String(),
      if (interactionType != null) 'interaction_type': interactionType,
      if (notes != null) 'notes': notes,
    };
    final res = await _db.from('interactions').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> updateInteraction(
    int id, {
    int? customerId,
    int? employeeId,
    DateTime? date,
    String? interactionType,
    String? notes,
  }) async {
    final upd = <String, dynamic>{
      if (customerId != null) 'customer_id': customerId,
      if (employeeId != null) 'employee_id': employeeId,
      if (date != null) 'date': date.toUtc().toIso8601String(),
      if (interactionType != null) 'interaction_type': interactionType,
      if (notes != null) 'notes': notes,
    };
    final res = await _db
        .from('interactions')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  // ------------------------------------------------------------
  // LEADS (final: consistent naming for UI + schema)
  // ------------------------------------------------------------

 /// All leads visible to the signed-in user.
  /// RLS should allow both employees and managers to read.
  static Future<List<Map<String, dynamic>>> visibleLeads() async {
    final res = await _db
        .from('leads')
        .select(
          'id, customer_id, assigned_employee_id, source, lead_status, date_created',
        )
        .order('date_created', ascending: false);
    return (res as List).cast<Map<String, dynamic>>();
  }

  /// Optional: simple alias if other parts of the app call getLeads()
  static Future<List<Map<String, dynamic>>> getLeads() => visibleLeads();

  /// Fetch a single lead by id
  static Future<Map<String, dynamic>> leadById(int id) async {
    final row = await _db
        .from('leads')
        .select(
          'id, customer_id, assigned_employee_id, source, lead_status, date_created',
        )
        .eq('id', id)
        .maybeSingle();
    if (row == null) throw Exception('Lead not found');
    return Map<String, dynamic>.from(row as Map);
  }

  /// Create a lead.
  /// - `source` is required for clarity in the UI.
  /// - `customerId` and `assignedEmployeeId` are optional.
  /// - `leadStatus` defaults to 'New'.
  static Future<Map<String, dynamic>> createLead({
    int? customerId,
    int? assignedEmployeeId,
    required String source,
    String leadStatus = 'New',
    DateTime? dateCreated,
  }) async {
    final row = <String, dynamic>{
      if (customerId != null) 'customer_id': customerId,
      if (assignedEmployeeId != null) 'assigned_employee_id': assignedEmployeeId,
      'source': source,
      'lead_status': leadStatus,
      'date_created': (dateCreated ?? DateTime.now().toUtc()).toIso8601String(),
    };

    final res = await _db.from('leads').insert(row).select().single();
    return Map<String, dynamic>.from(res as Map);
  }

  /// Update a lead's details.
  static Future<Map<String, dynamic>> updateLead(
    int id, {
    int? customerId,
    int? assignedEmployeeId,
    String? source,
    String? leadStatus,
    DateTime? dateCreated,
  }) async {
    final upd = <String, dynamic>{
      if (customerId != null) 'customer_id': customerId,
      if (assignedEmployeeId != null) 'assigned_employee_id': assignedEmployeeId,
      if (source != null) 'source': source,
      if (leadStatus != null) 'lead_status': leadStatus,
      if (dateCreated != null) 'date_created': dateCreated.toUtc().toIso8601String(),
    };

    final res = await _db
        .from('leads')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  /// Assign a lead to an employee (employees.employee_id).
  static Future<void> assignLeadToEmployee({
    required int leadId,
    required int employeeId,
  }) async {
    await _db
        .from('leads')
        .update({'assigned_employee_id': employeeId})
        .eq('id', leadId);
  }

  /// Delete a lead (useful for admin tools).
  static Future<void> deleteLead(int id) async {
    await _db.from('leads').delete().eq('id', id);
  }

  // ------------------------------------------------------------
  // CHAT HELPERS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> conversationsMine() async {
    final rows = await _db
        .from('conversations')
        .select('id, title, is_group, created_by, created_at')
        .order('created_at', ascending: false);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createGroupConversation({
    required String title,
    required List<String> participantUserIds,
  }) async {
    final res = await _db.rpc(
      'create_group_conversation_rpc',
      params: {'p_title': title, 'p_participants': participantUserIds},
    );
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<Map<String, dynamic>> getOrCreateDm({
    required String otherUserId,
  }) async {
    final res = await _db.rpc(
      'get_or_create_dm_rpc',
      params: {'p_other': otherUserId},
    );
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> conversationParticipants(
    int conversationId,
  ) async {
    final rows = await _db
        .from('conversation_participants')
        .select('conversation_id, user_id, role, joined_at')
        .eq('conversation_id', conversationId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> conversationMessages(
    int conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final rows = await _db
        .from('messages')
        .select('id, conversation_id, sender_id, body, attachments, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .range(offset, offset + limit - 1);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static RealtimeChannel subscribeMessages({
    required int conversationId,
    required void Function(Map<String, dynamic> row) onInsert,
  }) {
    final ch = _db.channel('messages_conv_$conversationId');
    ch.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId.toString(),
      ),
      callback: (payload) => onInsert(payload.newRecord),
    );
    ch.subscribe();
    return ch;
  }

  // ------------------------------------------------------------
  // REPORTING / DIRECTORY / PROJECTS
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> userDirectory() async {
    final rows = await _db
        .from('user_directory')
        .select('user_id, name, email, kind')
        .order('name');
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> activeProjectsManagers() async {
    final res = await _db
        .from('v_active_projects_per_manager')
        .select('user_id, display_name, email, count')
        .order('display_name');
    return (res as List).cast<Map<String, dynamic>>();
  }

    /// Fetch assigned projects for a given employee/user
  Future<List<Map<String, dynamic>>> getAssignedProjects({
    required int employeeId,
  }) async {
    try {
      final response = await _db
          .from('project_assignments')
          .select('project_id, projects(name, description, status, starts_at, due_date)')
          .eq('assignee_user_id', employeeId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned projects: $e');
      return [];
    }
  }

  /// Fetch assigned tasks for a given employee
  Future<List<Map<String, dynamic>>> getAssignedTasks({
    required int employeeId,
  }) async {
    try {
      final response = await _db
          .from('tasks')
          .select('task_id, title, description, status, due_date, project_id')
          .eq('assigned_to', employeeId)
          .order('due_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching assigned tasks: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> activeProjectsEmployees() async {
    final res = await _db
        .from('v_active_projects_per_employee')
        .select('user_id, display_name, email, count')
        .order('display_name');
    return (res as List).cast<Map<String, dynamic>>();
  }
  

  static Future<List<Map<String, dynamic>>> customersLite() async {
    final res = await _db
        .from('customers')
        .select('customer_id, first_name, last_name, email')
        .order('first_name');
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createCustomerQuick({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final res = await _db
        .from('customers')
        .insert({
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim().toLowerCase(),
        })
        .select('customer_id, first_name, last_name, email')
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<List<Map<String, dynamic>>> searchDirectory(String q) async {
    final res = await _db
        .from('directory_allowed_contacts')
        .select('user_id, display_name, email, avatar_url')
        .or('display_name.ilike.%$q%,email.ilike.%$q%')
        .order('display_name')
        .limit(25);
    return (res as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> createProject({
    required int customerId,
    required String name,
    String? description,
    DateTime? startsAt,
    DateTime? dueDate,
    String status = 'active',
  }) async {
    final res = await _db
        .from('projects')
        .insert({
          'customer_id': customerId,
          'name': name.trim(),
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
          if (dueDate != null) 'due_date': dueDate.toUtc().toIso8601String(),
          'status': status,
          'created_by': _db.auth.currentUser?.id,
        })
        .select(
          'id, customer_id, name, status, starts_at, due_date, created_at',
        )
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  static Future<void> addAssignments({
    required int projectId,
    List<String> managerUserIds = const [],
    List<String> employeeUserIds = const [],
  }) async {
    final rows = <Map<String, dynamic>>[];
    for (final id in managerUserIds) {
      rows.add({
        'project_id': projectId,
        'assignee_user_id': id,
        'role': 'manager',
      });
    }
    for (final id in employeeUserIds) {
      rows.add({
        'project_id': projectId,
        'assignee_user_id': id,
        'role': 'employee',
      });
    }
    if (rows.isEmpty) return;
    await _db.from('project_assignments').insert(rows);
  }

  // ------------------------------------------------------------
  // TASKS + RPC (SCALARS)
  // ------------------------------------------------------------
  static Future<int?> myEmployeeId() async {
    final res = await _db.rpc('current_employee_id'); // scalar
    if (res == null) return null;
    if (res is int) return res;
    if (res is num) return res.toInt();
    return null;
  }

  static Future<bool> amIManager() async {
    final res = await _db.rpc('is_current_user_manager'); // boolean scalar
    if (res == null) return false;
    if (res is bool) return res;
    return res == true;
  }

     static SupabaseClient get _client => Supabase.instance.client;
    static Future<List<Task>> myTasks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('project_assignments')
          .select('project_id, projects(id, name, description, status, starts_at, due_date)')
          .eq('assignee_user_id', userId);

      final List data = response as List<dynamic>? ?? [];

      return data.map((assignment) {
        final project = assignment['projects'];
        return Task(
          id: project['id'],
          title: project['name'] ?? 'Unnamed Task',
          description: project['description'],
          status: project['status'] ?? 'Unknown',
          dueDate: project['due_date'] != null ? DateTime.parse(project['due_date']) : null,
        );
      }).toList();
    } catch (e) {
      print('Error fetching tasks: $e');
      return [];
    }
  }


  static Future<Task> createTask({
    required String title,
    String? description,
    required int assignedToEmployeeId,
    DateTime? dueDate,
    String status = 'Pending',
  }) async {
    final me = await myEmployeeId();
    final row = await _db
        .from('tasks')
        .insert({
          'title': title,
          'description': description,
          'assigned_to': assignedToEmployeeId,
          'assigned_by': me,
          'due_date': dueDate?.toUtc().toIso8601String(),
          'status': status,
        })
        .select()
        .single();

    return Task.fromRow(Map<String, dynamic>.from(row as Map));
  }

  static Future<Task> updateTask({
    required int taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
  }) async {
    final patch = <String, dynamic>{};
    if (title != null) patch['title'] = title;
    if (description != null) patch['description'] = description;
    if (dueDate != null) patch['due_date'] = dueDate.toUtc().toIso8601String();
    if (status != null) patch['status'] = status;

    final row = await _db
        .from('tasks')
        .update(patch)
        .eq('id', taskId)
        .select()
        .single();
    return Task.fromRow(Map<String, dynamic>.from(row as Map));
  }

  // ------------------------------------------------------------
  // PERFORMANCE RECORDS (for Customer Satisfaction / Team Performance)
  // ------------------------------------------------------------
  static Future<List<Map<String, dynamic>>> performanceRecords({
    int limit = 500,
    // If you add created_at later, you can add a DateTimeRange filter here.
  }) async {
    final res = await _db
        .from('performance_records')
        .select('''
          id,
          employee_id,
          period,
          task_completed,
          customer_satisfaction_score,
          notes,
          employees:employee_id ( first_name, last_name )
        ''')
        .order('id', ascending: false)
        .limit(limit);

    return (res as List).cast<Map<String, dynamic>>();
  }

  // ----------------------------- COMPANY RATINGS -----------------------------
  static Future<int?> _customerIdForCurrentUser() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _db
        .from('customers')
        .select('customer_id')
        .eq('auth_user_id', uid)
        .maybeSingle();
    if (row == null) return null;
    return (row['customer_id'] as num).toInt();
  }

  /// Customers create a rating for the company.
  /// Writes: company_ratings(auth_user_id, customer_id?, stars, comment?)
  static Future<Map<String, dynamic>> createCompanyRating({
    required int stars,
    String? comment,
  }) async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) {
      throw Exception('Not signed in');
    }

    final customerId = await _customerIdForCurrentUser();

    final payload = <String, dynamic>{
      'auth_user_id': uid,
      'stars': stars.clamp(1, 5),
    };
    if (customerId != null) payload['customer_id'] = customerId;
    if (comment != null && comment.trim().isNotEmpty) {
      payload['comment'] = comment.trim();
    }

    final res = await _db
        .from('company_ratings')
        .insert(payload)
        .select()
        .single();
    return Map<String, dynamic>.from(res as Map);
  }

  /// Summary for managers (client-side aggregate to avoid PostgREST alias quirks).
  /// Returns: { "overall": { "avg": <double>, "count": <int> } }
  static Future<Map<String, dynamic>> companyRatingsSummaryAggregate() async {
    final rows = await _db.from('company_ratings').select('stars');
    if (rows is! List) {
      return {
        'overall': {'avg': 0.0, 'count': 0},
      };
    }
    final list = rows.cast<Map<String, dynamic>>();
    final count = list.length;
    if (count == 0) {
      return {
        'overall': {'avg': 0.0, 'count': 0},
      };
    }
    final sum = list.fold<num>(0, (s, r) => s + (r['stars'] as num));
    final avg = sum.toDouble() / count;
    return {
      'overall': {'avg': avg, 'count': count},
    };
  }

  /// Recent ratings for managers. If you have a FK customers(customer_id) -> company_ratings(customer_id),
  /// this will also include customer first/last name; otherwise it will still return the basic fields.
  static Future<List<Map<String, dynamic>>> recentCompanyRatings({
    int limit = 20,
  }) async {
    // Try to include customer name via FK; if there is no FK, fallback still works with base fields.
    final rows = await _db
        .from('company_ratings')
        .select('''
        id,
        customer_id,
        auth_user_id,
        stars,
        comment,
        created_at,
        customers:customer_id ( first_name, last_name )
      ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).cast<Map<String, dynamic>>();
  }

  // ----------------------------- MEETINGS -----------------------------
  static Future<List<Map<String, dynamic>>> meetingsUpcoming({
    int limit = 20,
  }) async {
    final rows = await _db
        .from('meetings')
        .select('id, title, date_time, organizer, description')
        .gte('date_time', DateTime.now().toUtc().toIso8601String())
        .order('date_time', ascending: true)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> meetingById(int id) async {
    final row = await _db
        .from('meetings')
        .select('id, title, date_time, organizer, description')
        .eq('id', id)
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  static Future<Map<String, dynamic>> createMeeting({
    required String title,
    required DateTime dateTime,
    required int organizerEmployeeId,
    String? description, 
  }) async {
    final payload = <String, dynamic>{
      'title': title.trim(),
      'date_time': dateTime.toUtc().toIso8601String(),
      'organizer': organizerEmployeeId,
    };
    if (description != null && description.trim().isNotEmpty) {
      
      payload['description'] = description.trim();
    }

    final row = await _db.from('meetings').insert(payload).select().single();
    return Map<String, dynamic>.from(row as Map);
  }

  static Future<Map<String, dynamic>> updateMeeting({
    required int id,
    String? title,
    DateTime? dateTime,
    int? organizerEmployeeId,
    String? description, // requires 'description' column
  }) async {
    final upd = <String, dynamic>{};
    if (title != null) upd['title'] = title.trim();
    if (dateTime != null) upd['date_time'] = dateTime.toUtc().toIso8601String();
    if (organizerEmployeeId != null) upd['organizer'] = organizerEmployeeId;
    if (description != null) upd['description'] = description.trim();

    final row = await _db
        .from('meetings')
        .update(upd)
        .eq('id', id)
        .select()
        .single();
    return Map<String, dynamic>.from(row as Map);
  }

  static Future<void> deleteMeeting(int id) async {
    await _db.from('meetings').delete().eq('id', id);
  }

  // ----------------------- MEETING ATTENDANCE -----------------------
  static Future<List<Map<String, dynamic>>> attendeesByMeeting(
    int meetingId,
  ) async {
    final rows = await _db
        .from('meeting_attendance')
        .select('id, meeting_id, employee_id, attendance_status')
        .eq('meeting_id', meetingId);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>> setAttendance({
    required int meetingId,
    required int employeeId,
    required String attendanceStatus, // e.g. "present" | "absent" | "late"
  }) async {
    // upsert-like behavior: try update, else insert
    final existing = await _db
        .from('meeting_attendance')
        .select('id')
        .eq('meeting_id', meetingId)
        .eq('employee_id', employeeId)
        .maybeSingle();

    if (existing != null) {
      final row = await _db
          .from('meeting_attendance')
          .update({'attendance_status': attendanceStatus})
          .eq('id', existing['id'])
          .select()
          .single();
      return Map<String, dynamic>.from(row as Map);
    }

    final row = await _db
        .from('meeting_attendance')
        .insert({
          'meeting_id': meetingId,
          'employee_id': employeeId,
          'attendance_status': attendanceStatus,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(row as Map);
  }
}
