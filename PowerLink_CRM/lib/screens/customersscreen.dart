import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class CustomersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Customers')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Customers screen')),
    );
  }
}
