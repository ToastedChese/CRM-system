import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class VisitsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Visits')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Visits screen')),
    );
  }
}
