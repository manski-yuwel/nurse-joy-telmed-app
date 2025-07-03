import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';

class AppointmentDetail extends StatefulWidget {
  AppointmentDetail({super.key, required this.appointmentId, required this.patientData});
  late final AuthService authService;

  final String appointmentId;
  final DocumentSnapshot patientData;

  @override
  State<AppointmentDetail> createState() => _AppointmentDetailState();
}

class _AppointmentDetailState extends State<AppointmentDetail> {
  
  @override 
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Appointment Detail',
      selectedIndex: 0,
      onItemTapped: (index) {},
      actions: [
        IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () {
            final chat = Chat();
            final chatRoomID = chat.generateChatRoomID(widget.authService.currentUser!.uid, widget.patientData.id);
            chat.generateChatRoom(chatRoomID, widget.authService.currentUser!.uid, widget.patientData.id);
            context.go('/chat/$chatRoomID', extra: {
              'recipientID': widget.patientData.id,
              'recipientFullName': '${widget.patientData['first_name']} ${widget.patientData['last_name']}',
            });
          },
        ),
      ],
      body: FutureBuilder<DocumentSnapshot>(
        future: getAppointmentDetails(widget.appointmentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final appointmentData = snapshot.data!.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient: ${widget.patientData['first_name']} ${widget.patientData['last_name']}',
                  ),
                  const SizedBox(height: 8),
                  Text('Date: ${appointmentData['appointmentDateTime'].toDate().toString()}'),
                  const SizedBox(height: 8),
                  Text('Description: ${appointmentData['description']}'),
                  const SizedBox(height: 8),
                  Text('Status: ${appointmentData['status']}'),
                ],
              ),
            );
          } else {
            return const Center(child: Text('No appointment details found'));
          }
        },
      ),
    );
  }
}