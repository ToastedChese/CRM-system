import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  final String _baseUrl = 'http://genericserver.com'; 

  Future<AppUser?> signUpCustomer({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    required String customerType,
    required String dateCreated,
    required int customerSatisfactionScore,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/signup.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
          'FirstName': firstName,
          'LastName': lastName,
          'Phone': phone,
          'Address': address,
          'CustomerType': customerType,
          'DateCreated': dateCreated,
          'CustomerSatisfactionScore': customerSatisfactionScore,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return AppUser(
          userId: data['user_id'],
          email: email,
          userType: 'customer',
        );
      }
      return null;
    } catch (e) {
      print('Sign-up error: $e');
      return null;
    }
  }

  Future<AppUser?> createEmployeeAccount({
    required String employeeId,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String role,
    required String hireDate,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/AddEmployee.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Email': email,
          'Password': password,
          'EmployeeID': employeeId,
          'FirstName': firstName,
          'LastName': lastName,
          'PhoneNumber': phoneNumber,
          'Role': role,
          'HireDate': hireDate,
          'is_manager': true,
        }),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return AppUser(
          userId: data['user_id'],
          email: email,
          userType: 'employee',
        );
      }
      return null;
    } catch (e) {
      print('Employee creation error: $e');
      return null;
    }
  }

  Future<AppUser?> signIn(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'Email': email, 'Password': password}),
      );
      final data = jsonDecode(response.body);
      if (data['success']) {
        return AppUser.fromMap(data);
      }
      return null;
    } catch (e) {
      print('Sign-in error: $e');
      return null;
    }
  }


  Future<void> signOut() async {
    _currentUser = null; 
  }

  Future<void> signOut() async {}
  AppUser? getCurrentUser() => null;
}