import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/signing/ui/pages/signin_page.dart';
import 'package:nursejoyapp/main.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return user == null ? SigninPage() : HomeScreen();
  }
}
