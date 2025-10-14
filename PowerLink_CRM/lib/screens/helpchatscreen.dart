import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class HelpChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help Chat')),
      drawer: AppDrawer(),
      body: Center(child: Text('This is the Help Chat screen')),
    );
  }
}
