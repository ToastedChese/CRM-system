import 'package:powerlink_crm/data/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/models/customer.dart';
import 'package:powerlink_crm/models/employee.dart';
import 'package:powerlink_crm/data/supabase_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // -----------------------------------------------------
  // Quick health check to confirm Supabase connectivity
  // -----------------------------------------------------
  Future<bool> testConnection() async {
    try {
      await SupabaseService.customers();
      print('✅ Supabase database connection OK');
      return true;
    } on PostgrestException catch (e) {
      print('❌ Database connection failed: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Could not reach Supabase: $e');
      return false;
    }
  }

  // -------------------------------
  // Sign up a new customer
  // -------------------------------
  Future<Customer?> signUpCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phone,
    String? address,
    String? customerType,
  }) async {
    try {
      if (!await testConnection()) {
        print('⚠️ Signup aborted: no Supabase connection.');
        return null;
      }

      final normalizedEmail = email.trim().toLowerCase();
      final AuthResponse res = await _supabase.auth.signUp(
        email: normalizedEmail,
        password: password,
      );

      if (res.user == null) {
        print('⚠️ Supabase signup returned null user for $email');
        return null;
      }

      final data = await SupabaseService.createCustomer({
        'auth_user_id': res.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': normalizedEmail,
        'phone': phone,
        'address': address,
        'customer_type': customerType,
      });

      print('✅ Customer registered: ${res.user!.email}');
      return Customer.fromJson(data);
    } on AuthException catch (e) {
      print('❌ Supabase Auth signup error: ${e.message}');
      return null;
    } on PostgrestException catch (e) {
      print('❌ Database insert error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected signup error: $e');
      return null;
    }
  }

  // -------------------------------
  // Sign in an employee, manager or customer
  // -------------------------------
  Future<dynamic> signIn(String email, String password) async {
    try {
      print('DEBUG: AuthService.signIn called — email="$email" pwdLen=${password.length}');
      if (!await testConnection()) {
        print('⚠️ Sign-in aborted: no Supabase connection.');
        return null;
      }

      // Keep the original-case trimmed email for authentication. Lowercasing
      // previously caused valid manager logins to fail when the stored auth
      // email contained uppercase letters. We'll still prepare a lowercase
      // variant for DB lookups as a fallback.
      final trimmedEmail = email.trim();
      final lowerEmail = trimmedEmail.toLowerCase();
      // We'll attempt multiple sign-in attempts to match behavior across branches.
      // Order:
      // 1) email=trimmedEmail, password=raw
      // 2) email=lowerEmail,   password=raw
      // 3) email=trimmedEmail, password=trimmedPassword
      // 4) email=lowerEmail,   password=trimmedPassword
      // Stop on first successful AuthResponse with a non-null user.
      final attempts = <Map<String, String>>[
        {'email': trimmedEmail, 'password': password, 'label': 'trimEmail+rawPwd'},
        {'email': lowerEmail, 'password': password, 'label': 'lowerEmail+rawPwd'},
        {'email': trimmedEmail, 'password': password.trim(), 'label': 'trimEmail+trimPwd'},
        {'email': lowerEmail, 'password': password.trim(), 'label': 'lowerEmail+trimPwd'},
      ];

      AuthResponse? res;
      Object? lastErr;

      for (final a in attempts) {
        final eMail = a['email']!;
        final pwd = a['password']!;
        final label = a['label']!;
        try {
          print('DEBUG: sign-in attempt: $label email=$eMail pwdLen=${pwd.length}');
          final candidate = await _supabase.auth.signInWithPassword(
            email: eMail,
            password: pwd,
          );
          if (candidate.user != null) {
            res = candidate;
            print('DEBUG: sign-in success on attempt: $label');
            break;
          } else {
            print('DEBUG: sign-in attempt returned no user: $label');
          }
        } catch (e) {
          lastErr = e;
          print('DEBUG: sign-in attempt threw for $label: $e');
        }
      }

      // If after all attempts no user, run diagnostics and return null.
      if (res == null || res.user == null) {
        print('❌ Supabase Auth sign-in failed after multiple attempts: invalid credentials');
        try {
          final dynamic maybeErr = res as dynamic? ?? lastErr;
          final errMsg = maybeErr?.error?.message ?? maybeErr?.toString();
          if (errMsg != null) print('DEBUG: signIn error detail: $errMsg');
        } catch (_) {}

        // Diagnostic: attempt to query auth.users for both email variants. This may
        // fail with anon-key permissions, but in SQL editor it is accessible.
        try {
          print('DEBUG: attempting to query auth.users for diagnostics');
          final orig = await _supabase.from('auth.users').select('id,email,raw_user_meta_data').eq('email', trimmedEmail).limit(1).maybeSingle();
          final lower = await _supabase.from('auth.users').select('id,email,raw_user_meta_data').eq('email', lowerEmail).limit(1).maybeSingle();
          print('DEBUG: auth.users orig=$orig');
          print('DEBUG: auth.users lower=$lower');
        } catch (e) {
          print('DEBUG: auth.users query failed (likely permission): $e');
        }

        print('DEBUG: AuthService.signIn returning null (failed auth)');
        return null;
      }

      // DEBUG: print the raw AuthResponse object for deeper diagnostics
      try {
        print('DEBUG: AuthResponse: user=${res.user}, session=${res.session}');
      } catch (e) {
        print('DEBUG: Could not print full AuthResponse: $e');
      }

      final userId = res.user!.id;
      print('DEBUG: user signed in, userId=$userId, email=$lowerEmail');

      // After sign-in, print current session and currentUser from client
      try {
        final curSession = _supabase.auth.currentSession;
        final curUser = _supabase.auth.currentUser;
        print('DEBUG: Supabase currentSession=${curSession != null ? 'present' : 'null'}');
        print('DEBUG: Supabase currentUser=${curUser != null ? curUser.email : 'null'}');
      } catch (e) {
        print('DEBUG: Could not read current session/user: $e');
      }

      // 1. Check for Manager first
      final managerId = await SupabaseService.getMyManagerId(userId);
      print('DEBUG: managerId lookup returned: $managerId');
      if (managerId != null) {
        final managerData = await _supabase
            .from('managers')
            .select()
            .eq('id', managerId)
            .single();
        print('DEBUG: managerData fetched: $managerData');
        print('✅ Manager signed in: ${res.user!.email}');

        // Return as an Employee object to be compatible with the UI
        final employeeCompatData = {
          'employee_id': managerData['id'],
          'auth_user_id': managerData['auth_user_id'] ?? userId,
          'first_name': managerData['first_name'],
          'last_name': managerData['last_name'],
          'email': managerData['email'],
          'role': 'Manager', // Explicitly set role for UI logic
          'hire_date': managerData['created_at'], // Use created_at as hire_date
        };
        return Employee.fromJson(employeeCompatData);
      }

      // Fallback: sometimes the managers table isn't linked by auth_user_id.
      // Try to find a manager row by email and attach the auth user id if found.
      // Try to find a manager row by email. Try exact-case first, then lowercase
      // as a fallback to handle inconsistent casing in the database.
      var managerByEmail = await _supabase
          .from('managers')
          .select()
          .eq('email', trimmedEmail)
          .maybeSingle();
      if (managerByEmail == null && lowerEmail != trimmedEmail) {
        managerByEmail = await _supabase
            .from('managers')
            .select()
            .eq('email', lowerEmail)
            .maybeSingle();
      }
      print('DEBUG: managerByEmail lookup returned: $managerByEmail');
      if (managerByEmail != null) {
        // If this manager row lacks auth_user_id, update it to link the account.
        try {
          final managerIdFromRow = (managerByEmail['id'] is int) ? managerByEmail['id'] as int : (managerByEmail['id'] as num).toInt();
          final updated = await _supabase
              .from('managers')
              .update({'auth_user_id': userId})
              .eq('id', managerIdFromRow)
              .select()
              .single();
          print('DEBUG: Updated manager row with auth_user_id: $updated');
          print('✅ Manager signed in (by email): ${res.user!.email}');

          // Return as an Employee object to be compatible with the UI
          final employeeCompatData = {
            'employee_id': updated['id'],
            'auth_user_id': updated['auth_user_id'] ?? userId,
            'first_name': updated['first_name'],
            'last_name': updated['last_name'],
            'email': updated['email'],
            'role': 'Manager', // Explicitly set role for UI logic
            'hire_date': updated['created_at'], // Use created_at as hire_date
          };
          return Employee.fromJson(employeeCompatData);
        } catch (e) {
          print('DEBUG: Failed to update manager auth_user_id: $e');
          // Fall through and continue to employee/customer checks
        }
      }

      // 2. Check for Employee
      final empId = await SupabaseService.getMyEmployeeId(userId);
      print('DEBUG: employeeId lookup returned: $empId');
      if (empId != null) {
        final empData = await _supabase
            .from('employees')
            .select()
            .eq('employee_id', empId)
            .single();
        print('DEBUG: empData fetched: $empData');
        print('✅ Employee signed in: ${res.user!.email}');
        return Employee.fromJson(empData);
      }

      // 3. Check for Customer
      final custId = await SupabaseService.getMyCustomerId(userId);
      print('DEBUG: customerId lookup returned: $custId');
      if (custId != null) {
        final custData = await SupabaseService.customerById(custId);
        print('DEBUG: custData fetched: $custData');
        print('✅ Customer signed in: ${res.user!.email}');
        return Customer.fromJson(custData);
      }

      // 4. Fallback: If no profile exists, create a minimal customer row
      final inserted = await SupabaseService.createCustomer({
        'auth_user_id': userId,
        'email': lowerEmail,
      });

      print('⚠️ No profile found — created minimal customer row for $email');
      return Customer.fromJson(inserted);

    } on AuthException catch (e, st) {
      print('❌ Supabase Auth sign-in error: ${e.message}');
      print('❌ Full AuthException: $e');
      print('❌ Stack: $st');
      return null;
    } on PostgrestException catch (e) {
      print('❌ Database sign-in error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected sign-in error: $e');
      return null;
    }
  }


  // -------------------------------
  // Create a new employee profile
  // -------------------------------
  Future<Employee?> createEmployeeAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? phoneNumber,
    String? role,
    DateTime? hireDate,
  }) async {
    try {
      if (!await testConnection()) {
        print('⚠️ Employee creation aborted: no Supabase connection.');
        return null;
      }

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        print('⚠️ Failed to create auth user for $email');
        return null;
      }

      final data = await SupabaseService.createEmployee({
        'auth_user_id': res.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'hire_date': hireDate?.toIso8601String(),
      });

      print('✅ Employee account created for $email');
      return Employee.fromJson(data);
    } on AuthException catch (e) {
      print('❌ Supabase Auth employee creation error: ${e.message}');
      return null;
    } on PostgrestException catch (e) {
      print('❌ Database employee insert error: ${e.message}');
      return null;
    } catch (e) {
      print('❌ Unexpected employee creation error: $e');
      return null;
    }
  }

  // -------------------------------
  // Sign out the current user
  // -------------------------------
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      print('✅ User signed out successfully.');
    } on AuthException catch (e) {
      print('❌ Supabase sign-out error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected sign-out error: $e');
    }
  }
}
