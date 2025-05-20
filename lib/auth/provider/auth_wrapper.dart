import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/signing/ui/pages/signin_page.dart';
import 'package:nursejoyapp/main.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/profile/ui/pages/profile_setup.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      return const SigninPage();
    } else {
      return FutureBuilder<bool>(
        future: authService.isUserSetup(),
        builder: (context, snapshot) {
          // While we're checking the setup status, show a loading indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          // If there's an error, log it and proceed to home screen as fallback
          if (snapshot.hasError) {
            print('Error checking user setup: ${snapshot.error}');
            return const HomeScreen();
          }

          final isSetup = snapshot.data ?? false;

          // If user is not set up, redirect to profile setup page
          if (!isSetup) {
            return const ProfileSetup();
          }

          // User is set up, go to home screen
          return const HomeScreen();
        },
      );
    }
  }
}
