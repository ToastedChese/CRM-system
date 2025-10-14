import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reports')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Reports screen')),
    );
  }
}
