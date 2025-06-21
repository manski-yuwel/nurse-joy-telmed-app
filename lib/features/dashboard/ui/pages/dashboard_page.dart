import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart' show getUserDetails;
import 'package:nursejoyapp/notifications/notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  User? user;
  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ... (existing widgets until the end of the prescriptions card)

            // NurseJoy AI Chat Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to NurseJoy AI chat
                  context.go('/nursejoy-ai');
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.pink[100],
                        child: Icon(
                          Icons.medical_services,
                          size: 30,
                          color: Colors.pink,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "NurseJoy AI",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Get instant health advice from our AI assistant",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Recent Activities Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history, size: 24, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          "Recent Activities",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (user != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: notificationService.getActivities(user!.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'No recent activities',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var activity = snapshot.data!.docs[index].data()
                                  as Map<String, dynamic>;
                              final body = notificationService.resolveActivityBody(activity['type'], activity['body']);

                              debugPrint(activity.toString());
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Icon(
                                    _getActivityIcon(activity['type']),
                                    color: Colors.green,
                                  ),
                                ),
                                title: Text(activity['title'] ?? 'New Activity'),
                                subtitle: Text(
                                  _formatTimestamp(activity['timestamp']),
                                  style: TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  _handleActivityTap(body, activity['type'],context);
                                },
                              );
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'message':
        return Icons.message;
      case 'prescription':
        return Icons.medication;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      return '${timestamp.toDate().toString().substring(0, 10)}';
    }
    return 'Recent';
  }

  void _handleActivityTap(Map<String, dynamic> body, String type, BuildContext context) async {
    if (type == 'appointment' && body['appointmentID'] != null) {
      final doctorUserDetails = await getUserDetails(body['doctorID']);
      if (context.mounted) {
        context.go(
          '/appointment/${body['appointmentID']}',
          extra: doctorUserDetails,
        );
      }
    } else if (type == 'message' && body['chatRoomID'] != null) {
      final recipientUserDetails = await getUserDetails(body['senderID']);
      final recipientFullName = recipientUserDetails['full_name'];
      if (context.mounted) {
        context.go(
          '/chat/${body['chatRoomID']}',
          extra: {'recipientID': body['senderID'], 'recipientFullName': recipientFullName},
        );
      }
    }
  }
}