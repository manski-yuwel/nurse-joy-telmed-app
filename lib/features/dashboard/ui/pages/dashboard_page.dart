import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart' show getUserDetails;
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:nursejoyapp/features/dashboard/ui/pages/activity_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
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
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [

            // NurseJoy AI Chat Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () {
                  // Navigate to NurseJoy AI chat
                  context.go('/ai');
                },
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.pink[100],
                        child: const Icon(
                          Icons.medical_services,
                          size: 30,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "NurseJoy AI",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Get instant health advice from our AI assistant",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Recent Activities Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
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
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ActivityListPage(),
                              ),
                            );
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (user != null)
                      StreamBuilder<QuerySnapshot>(
                        stream: notificationService.getActivities(user!.uid),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'No recent activities',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          // Show only the most recent 3 activities in the dashboard
                          final recentActivities = snapshot.data!.docs.take(3).toList();

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentActivities.length,
                            itemBuilder: (context, index) {
                              var activity = recentActivities[index].data()
                                  as Map<String, dynamic>;
                              final body = notificationService.resolveActivityBody(
                                  activity['type'], activity['body']);

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Icon(
                                    _getActivityIcon(activity['type']),
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                  ),
                                  title: Text(
                                    activity['title'] ?? 'New Activity',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: _getActivitySubtitle(activity['type'], body),
                                  trailing: Text(
                                    _formatTimestamp(activity['timestamp']),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  onTap: () {
                                    _handleActivityTap(body, activity['type'], context);
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

  Widget? _getActivitySubtitle(String type, Map<String, dynamic> body) {
    if (type == 'appointment') {
      return Text(
        "Appointment Time: ${DateFormat('MMM d, yyyy – h:mm a').format(DateTime.parse(body['appointmentDateTime']))}",
        style: const TextStyle(fontSize: 14),
      );
    } else if (type == 'message') {
      return Text(
        body['messageBody'] ?? 'New message',
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return null;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final now = DateTime.now();
      final date = timestamp.toDate();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    }
    return 'Recent';
  }




  void _handleActivityTap(Map<String, dynamic> body, String type, BuildContext context) async {
    if (type == 'appointment' && body['id'] != null) {
      final doctorUserDetails = await getUserDetails(body['doctorID']);
      // convert to map
      final doctorUserDetailsMap = doctorUserDetails.data() as Map<String, dynamic>;
      if (context.mounted) {
        context.push(
          '/user-appointment-detail/${body['id']}',
          extra: {'doctorData': doctorUserDetailsMap},
        );
      }
    } else if (type == 'message' && body['id'] != null) {
      final recipientUserDetails = await getUserDetails(body['senderID']);
      final recipientFullName = recipientUserDetails['full_name'];
      if (context.mounted) {
        context.push(
          '/chat/${body['chatRoomID']}',
          extra: {'recipientID': body['senderID'], 'recipientFullName': recipientFullName},
        );
      }
    }
  }
}