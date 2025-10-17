import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'customer.dart';
import 'employee.dart';

class AuthService {
  final String baseUrl = 'http://your-laravel-domain.com/api'; // API URL

  // Customer Signup
  Future<Customer?> signUpCustomer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String address,
    required String customerType,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/customer'),  //need database URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'FirstName': firstName,
        'LastName': lastName,
        'Email': email,
        'Phone': phone,
        'Address': address,
        'CustomerType': customerType,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('customerID', data['customer']['CustomerID']);
        return Customer.fromJson(data['customer']);
      }
    }
    return null;
  }

  // Employee Sign-In
  Future<Employee?> signInEmployee(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/employee'),     //need database URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('employeeID', data['employee']['EmployeeID']);
        return Employee.fromJson(data['employee']);
      }
    }
    return null;
  }
}