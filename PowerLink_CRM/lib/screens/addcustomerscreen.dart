import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class AddCustomerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Customer')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Add Customer screen')),
    );
  }
}
