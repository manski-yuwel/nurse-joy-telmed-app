import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key});
  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
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

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        // Navigate to chat
        context.go('/chat');
        break;
      case 1:
        // Navigate to dashboard (home)
        context.go('/home');
        break;
      case 2:
        // Navigate to profile
        context.go('/profile/${auth.user!.uid}');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Appointments',
      selectedIndex: 1,
      onItemTapped: _handleNavigation,
      body: FutureBuilder(
        future: getAppointmentList(auth.user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final appointment = snapshot.data!.docs[index];

                return FutureBuilder(
                  future: getUserDetails(appointment['patientId']),
                  builder: (context, patientDetails) {
                    if (patientDetails.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (patientDetails.hasError) {
                      return Center(
                          child: Text('Error: ${patientDetails.error}'));
                    } else if (patientDetails.hasData) {
                      if (patientDetails.data != null) {
                        final patientData = patientDetails.data!;
                        final patientName =
                            '${patientData['first_name']} ${patientData['last_name']}';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            title: Text(patientName),
                            subtitle: Text(appointment['appointmentDateTime']
                                .toDate()
                                .toString()),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Chat button for each appointment
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  onPressed: () {
                                    final chatRoomID = _generateChatRoomID(
                                      auth.user!.uid,
                                      appointment['patientId'],
                                    );
                                    context.go('/chat/$chatRoomID', extra: {
                                      'recipientID': appointment['patientId'],
                                      'recipientFullName': patientName,
                                    });
                                  },
                                  tooltip: 'Chat with patient',
                                ),
                                // Profile button for patient
                                IconButton(
                                  icon: const Icon(Icons.person_outline),
                                  onPressed: () {
                                    context.go(
                                        '/profile/${appointment['patientId']}');
                                  },
                                  tooltip: 'View patient profile',
                                ),
                              ],
                            ),
                            onTap: () {
                              context.go(
                                  '/appointment-detail/${appointment.id}',
                                  extra: {
                                    'patientData': patientData,
                                  });
                            },
                          ),
                        );
                      }
                      return const Center(
                          child: Text('No patient details found'));
                    } else {
                      return const Center(child: Text('No appointments found'));
                    }
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('No appointments found'));
          }
        },
      ),
    );
  }

  // Helper method to generate consistent chat room IDs
  String _generateChatRoomID(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
