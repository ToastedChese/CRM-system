import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/models/customer.dart';
import 'package:powerlink_crm/models/employee.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // -----------------------------------------------------
  // Quick health check to confirm Supabase connectivity
  // -----------------------------------------------------
  Future<bool> testConnection() async {
    try {
      final result = await _supabase.from('customers').select('id').limit(1);
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

      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user == null) {
        print('⚠️ Supabase signup returned null user for $email');
        return null;
      }

      final data = await _supabase.from('customers').insert({
        'user_id': res.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'address': address,
        'customer_type': customerType,
      }).select();

      if (data.isEmpty) {
        print('⚠️ Failed to insert customer profile for $email');
        return null;
      }

      print('✅ Customer registered: ${res.user!.email}');
      return Customer.fromJson(data.first);
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
  // Sign in an employee or customer
  // -------------------------------
  Future<dynamic> signIn(String email, String password) async {
    try {
      if (!await testConnection()) {
        print('⚠️ Sign-in aborted: no Supabase connection.');
        return null;
      }

      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user == null) {
        print('❌ Supabase Auth sign-in failed: invalid credentials');
        return null;
      }

      final userId = res.user!.id;

      // Check employees table
      final emp = await _supabase
          .from('employees')
          .select('id, user_id, first_name, last_name, email, role')
          .eq('user_id', userId)
          .maybeSingle();

      if (emp != null) {
        print('✅ Employee signed in: ${res.user!.email}');
        return Employee.fromJson(emp);
      }

      // Check customers table
      final cust = await _supabase
          .from('customers')
          .select('id, user_id, first_name, last_name, email, phone, customer_type')
          .eq('user_id', userId)
          .maybeSingle();

      if (cust != null) {
        print('✅ Customer signed in: ${res.user!.email}');
        return Customer.fromJson(cust);
      }

      // If no profile exists, create a minimal customer row
      final inserted = await _supabase.from('customers').insert({
        'user_id': userId,
        'email': email,
      }).select();

      if (inserted.isNotEmpty) {
        print('⚠️ No profile found — created minimal customer row for $email');
        return Customer.fromJson(inserted.first);
      }

      return null;
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

      final data = await _supabase.from('employees').insert({
        'user_id': res.user!.id,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        'role': role,
        'hire_date': hireDate?.toIso8601String(),
      }).select();

      if (data.isEmpty) {
        print('⚠️ Failed to insert employee profile for $email');
        return null;
      }

      print('✅ Employee account created for $email');
      return Employee.fromJson(data.first);
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
