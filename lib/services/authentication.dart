import 'package:powerlink_crm/models/manager.dart';
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
      if (!await testConnection()) {
        print('⚠️ Sign-in aborted: no Supabase connection.');
        return null;
      }

      final normalizedEmail = email.trim().toLowerCase();
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      if (res.user == null) {
        print('❌ Supabase Auth sign-in failed: invalid credentials');
        return null;
      }

      final userId = res.user!.id;
      print('DEBUG: user signed in, userId=$userId, email=$normalizedEmail');

      // 1. Check for Manager first
      final managerId = await SupabaseService.getMyManagerId();
      print('DEBUG: managerId lookup returned: $managerId');
      if (managerId != null) {
        final managerData = await _supabase
            .from('managers')
            .select()
            .eq('id', managerId)
            .single();
        print('DEBUG: managerData fetched: $managerData');
        print('✅ Manager signed in: ${res.user!.email}');
        return Manager.fromJson(managerData);
      }

      // Fallback: sometimes the managers table isn't linked by auth_user_id.
      // Try to find a manager row by email and attach the auth user id if found.
      final managerByEmail = await _supabase
          .from('managers')
          .select()
          .eq('email', normalizedEmail)
          .maybeSingle();
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
          return Manager.fromJson(updated);
        } catch (e) {
          print('DEBUG: Failed to update manager auth_user_id: $e');
          // Fall through and continue to employee/customer checks
        }
      }

      // 2. Check for Employee
      final empId = await SupabaseService.getMyEmployeeId();
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
      final custId = await SupabaseService.getMyCustomerId();
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
        'email': normalizedEmail,
      });

      print('⚠️ No profile found — created minimal customer row for $email');
      return Customer.fromJson(inserted);

    } on AuthException catch (e) {
      print('❌ Supabase Auth sign-in error: ${e.message}');
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
    } catch (e) {
      print('An unexpected error occurred: $e');
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
