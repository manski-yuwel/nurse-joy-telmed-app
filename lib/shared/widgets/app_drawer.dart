import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final mediaQuery = MediaQuery.of(context);
    final appBarHeight = kToolbarHeight + mediaQuery.padding.top;

    return Drawer(
      child: Column(
        children: [
          Container(
            height: appBarHeight,
            width: double.infinity,
            color: const Color(0xFF58f0d7),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: const Text('Home'),
                  onTap: () {
                    context.go('/home');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: const Text('Profile'),
                  onTap: () {
                    final auth =
                        Provider.of<AuthService>(context, listen: false);
                    context.go('/profile/${auth.user!.uid}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emergency_outlined),
                  title: const Text('Activate Emergency Mode'),
                  onTap: () {
                    context.go('/emergency');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Settings'),
                  onTap: () {
                    context.go('/settings');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('View Map'),
                  onTap: () {
                    context.go('/viewmap');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  title: const Text('Logout'),
                  onTap: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      context.go('/signin');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
