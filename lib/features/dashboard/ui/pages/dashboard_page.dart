import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatelessWidget {
const DashboardPage({ super.key });

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Dashboard: ${user?.email}')),
    );
  }
}
