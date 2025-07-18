import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/features/admin/data/admin_service.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';

class DoctorApplicationsPage extends StatelessWidget {
  const DoctorApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminService adminService = AdminService();

    return AppScaffold(
      title: 'Doctor Applications',
      selectedIndex: 0,
      onItemTapped: (index) {
        // Handle navigation
      },
      body: StreamBuilder<QuerySnapshot>(
        stream: adminService.getPendingDoctorApplications(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending applications.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(data['profile_pic'] ?? ''),
                    child: data['profile_pic'] == null || data['profile_pic'].isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(data['full_name'] ?? 'No Name'),
                  subtitle: Text(data['specialization'] ?? 'No Specialization'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    context.push('/admin/applications/${document.id}');
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
