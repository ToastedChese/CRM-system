import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Login screen')),
    );
  }
}
