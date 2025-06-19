import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';

class UserAppointmentList extends StatefulWidget {
  const UserAppointmentList({super.key});
  @override
  State<UserAppointmentList> createState() => _UserAppointmentListState();
}

class _UserAppointmentListState extends State<UserAppointmentList> {
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
        future: getUserAppointmentList(auth.user!.uid),
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
                  future: getUserDetails(appointment['doctorID']),
                  builder: (context, doctorProfile) {
                    if (doctorProfile.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (doctorProfile.hasError) {
                      return Center(
                          child: Text('Error: ${doctorProfile.error}'));
                    } else if (doctorProfile.hasData) {
                      if (doctorProfile.data != null) {
                        final doctorData = doctorProfile.data!;
                        final doctorName =
                            '${doctorData['first_name']} ${doctorData['last_name']}';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: ListTile(
                            title: Text(doctorName),
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
                                    final chatInstance = Chat();
                                    final chatRoomID = chatInstance.generateChatRoomID(
                                      auth.user!.uid,
                                      appointment['doctorID'],
                                    );
                                    context.go('/chat/$chatRoomID', extra: {
                                      'recipientID': appointment['doctorID'],
                                      'recipientFullName': doctorName,
                                    });
                                  },
                                  tooltip: 'Chat with doctor',
                                ),
                                // Profile button for patient
                                IconButton(
                                  icon: const Icon(Icons.person_outline),
                                  onPressed: () async {
                                    final doctorDetails = await getDoctorDetails(appointment['doctorID']);
                                    context.go(
                                        '/doctor/${appointment['doctorID']}', extra: {
                                      'doctorDetails': doctorDetails,
                                      'userDetails': doctorData,
                                    });
                                  },
                                  tooltip: 'View doctor profile',
                                ),
                              ],
                            ),
                            onTap: () {
                              context.go(
                                  '/user-appointment-detail/${appointment.id}',
                                  extra: {
                                    'doctorData': doctorData,
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

}
