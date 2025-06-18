import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';

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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Appointments',
      selectedIndex: 0,
      onItemTapped: (index) {},
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
                // render the patient name and the appointment date and time
                final appointment = snapshot.data!.docs[index];

                return FutureBuilder(
                  future: getUserDetails(appointment['patientId']),
                  builder: (context, patientDetails) {
                    if (patientDetails.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (patientDetails.hasError) {
                      return Center(child: Text('Error: ${patientDetails.error}'));
                    } else if (patientDetails.hasData) {
                      if (patientDetails.data != null) {
                        final patientData = patientDetails.data!;
                        final patientName = '${patientData['first_name']} ${patientData['last_name']}';
                        return ListTile(
                          title: Text(patientName),
                          subtitle: Text(appointment['appointmentDateTime'].toDate().toString()),
                        );
                      }
                      return const Center(child: Text('No patient details found'));
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


