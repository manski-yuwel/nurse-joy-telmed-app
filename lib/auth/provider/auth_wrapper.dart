import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      // Using go_router for navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/signin');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return FutureBuilder<Map<String, dynamic>>(
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
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/home');
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final isSetup = snapshot.data?['is_setup'] ?? false;
          final isDoctor = snapshot.data?['is_doctor'] ?? false;

          // If user is not set up, redirect to profile setup page
          if (!isSetup) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/profile-setup');
            });
          } else {
            // User is set up, go to home screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/home');
            });
          }

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }
}
