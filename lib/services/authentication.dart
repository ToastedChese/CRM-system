import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/models/customer.dart';
import 'package:powerlink_crm/models/employee.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      // 1. Sign up the user with Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // 2. Create a corresponding profile in the 'customers' table
        final List<Map<String, dynamic>> customerData = await _supabase
            .from('customers')
            .insert({
              'user_id': res.user!.id, // link to auth user
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'phone': phone,
              'address': address,
              'customer_type': customerType,
            })
            .select();

        return Customer.fromJson(customerData.first);
      }
      return null;
    } on AuthException catch (e) {
      print('Supabase sign-up error: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return null;
    }
  }

  // -------------------------------
  // Sign in an employee or customer
  // -------------------------------
  Future<dynamic> signIn(String email, String password) async {
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final userId = res.user!.id;

        // 1) Try employees (by user_id)
        final emp = await _supabase
            .from('employees')
            .select()
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();

        if (emp != null) {
          return Employee.fromJson(emp);
        }

        // 2) Try customers (by user_id)
        var cust = await _supabase
            .from('customers')
            .select()
            .eq('user_id', userId)
            .limit(1)
            .maybeSingle();

        if (cust != null) {
          return Customer.fromJson(cust);
        }

        // 3) No profile yet -> create a minimal customer row (first-time user)
        final inserted = await _supabase
            .from('customers')
            .insert({
              'user_id': userId,
              'email': email, // optional but helpful
            })
            .select()
            .limit(1);

        if (inserted.isNotEmpty) {
          return Customer.fromJson(inserted.first);
        }
      }

      // No match found
      return null;
    } on PostgrestException catch (e) {
      print('PostgrestException (${e.code}): ${e.message}');
      return null;
    } on AuthException catch (e) {
      print('Supabase sign-in error: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return null;
    }
  }

  // -------------------------------
  // Create a new employee profile (for managers)
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
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final List<Map<String, dynamic>> employeeData = await _supabase
            .from('employees')
            .insert({
              'user_id': res.user!.id, // link to auth user
              'first_name': firstName,
              'last_name': lastName,
              'email': email,
              'phone_number': phoneNumber,
              'role': role,
              'hire_date': hireDate?.toIso8601String(),
            })
            .select();

        return Employee.fromJson(employeeData.first);
      }
      return null;
    } on AuthException catch (e) {
      print('Supabase employee creation error: ${e.message}');
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
    } on AuthException catch (e) {
      print('Supabase sign-out error: ${e.message}');
    } catch (e) {
      print('Unexpected sign-out error: $e');
    }
  }
}
