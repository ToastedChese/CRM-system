import 'package:flutter/material.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Employee Dashboard"),
        backgroundColor: const Color(0xFF2C426A),
      ),
      body: const Center(
        child: Text(
          "Well done!",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF182D53),
          ),
        ),
      ),
    );
  }
}
