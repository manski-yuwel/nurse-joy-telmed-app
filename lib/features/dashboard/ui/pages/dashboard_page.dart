import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
const DashboardPage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF58f0d7),
        title: const Text('Dashboard'),
      ),
      body: Center(
        child: Text('Dashboard')
      )
    );
  }
}