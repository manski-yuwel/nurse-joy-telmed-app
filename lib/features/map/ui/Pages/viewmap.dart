import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:nursejoyapp/shared/widgets/app_drawer.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';

class ViewMapPage extends StatefulWidget {
  const ViewMapPage({Key? key}) : super(key: key);

  @override
  _ViewMapPageState createState() => _ViewMapPageState();
}

class _ViewMapPageState extends State<ViewMapPage> {
  int _selectedIndex = -1;
  late AuthService auth;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context, listen: false);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile/${auth.user!.uid}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Map",
      selectedIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
      onItemTapped: _onItemTapped,
      body: Center(
        child: Image.asset(
          'assets/img/map_placeholder.png',
          fit: BoxFit.fill,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
