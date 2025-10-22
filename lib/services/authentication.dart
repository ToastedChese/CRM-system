import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powerlink_crm/models/customer.dart';
import 'package:powerlink_crm/models/employee.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Sign up a new customer
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

  // Sign in an employee or customer
  Future<dynamic> signIn(String email, String password) async {
    // TODO: This implementation uses direct Supabase authentication.
    // This should be updated to call the custom Laravel API endpoint for authentication
    // once it is available.
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Check if the user is in the 'employees' table first
        var response = await _supabase
            .from('employees')
            .select()
            .eq('email', email)
            .single();

        if (response != null) {
          return Employee.fromJson(response);
        }

        // If not an employee, check the 'customers' table
        response = await _supabase
            .from('customers')
            .select()
            .eq('email', email)
            .single();

        if (response != null) {
          return Customer.fromJson(response);
        }
      }

      return null;
    } on AuthException catch (e) {
      print('Supabase sign-in error: ${e.message}');
      return null;
    } catch (e) {
      print('An unexpected error occurred: $e');
      return null;
    }
  }
  
  // Create a new employee profile (for managers)
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
      // Create user in Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // Insert profile into the 'employees' table
        final List<Map<String, dynamic>> employeeData = await _supabase
            .from('employees')
            .insert({
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

  // Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      print('Supabase sign-out error: ${e.message}');
    }
  }
}
