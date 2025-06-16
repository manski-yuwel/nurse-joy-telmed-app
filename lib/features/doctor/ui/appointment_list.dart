import 'package:flutter/material.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';

class AppointmentList extends StatelessWidget {
  const AppointmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      selectedIndex: 0,
      onItemTapped: (index) {},
      title: 'Appointments',
      body: const Center(
        child: Text('Appointments List'),
      ),
    );
  }
}
