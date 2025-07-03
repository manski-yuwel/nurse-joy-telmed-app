
import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:provider/provider.dart';

class UserAppointmentDetail extends StatefulWidget {
  UserAppointmentDetail({super.key, required this.appointmentId, required this.doctorData});
  late final AuthService authService;

  final String appointmentId;
  final DocumentSnapshot doctorData;

  @override
  State<UserAppointmentDetail> createState() => _UserAppointmentDetailState();
}

class _UserAppointmentDetailState extends State<UserAppointmentDetail> {
  int _selectedIndex = 1; // Home is selected by default
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile/${widget.authService.currentUser?.uid}');
    }
  }
  
  @override 
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.authService = Provider.of<AuthService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Appointment Detail',
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      actions: [
        IconButton(
          icon: Icon(Icons.chat),
          onPressed: () {
            final chat = Chat();
            final chatRoomID = chat.generateChatRoomID(widget.authService.currentUser!.uid, widget.doctorData.id);
            chat.generateChatRoom(chatRoomID, widget.authService.currentUser!.uid, widget.doctorData.id);
            context.go('/chat/$chatRoomID', extra: {
              'recipientID': widget.doctorData.id,
              'recipientFullName': '${widget.doctorData['first_name']} ${widget.doctorData['last_name']}',
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
                    'Doctor: ${widget.doctorData['first_name']} ${widget.doctorData['last_name']}',
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