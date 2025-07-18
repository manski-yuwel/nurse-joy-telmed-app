import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:nursejoyapp/notifications/notification_service.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:provider/provider.dart';

class ActivityListPage extends StatefulWidget {
  const ActivityListPage({super.key});


  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile');
    }
  }
  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final userID = Provider.of<AuthService>(context).user!.uid;

    return AppScaffold(
      selectedIndex: 0,
      onItemTapped: _onItemTapped,
      title: 'All Activities',
      body: StreamBuilder<QuerySnapshot>(
              stream: notificationService.getActivities(userID),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No activities found',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                final activities = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index].data() as Map<String, dynamic>;
                    print(activity);
                    final body = notificationService.resolveActivityBody(
                        activity['type'], activity['body']);
                    print(body);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(
                            _getActivityIcon(activity['type']),
                            color: Colors.green,
                          ),
                        ),
                        title: Text(
                          activity['title'] ?? 'Activity',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: _getActivitySubtitle(activity['type'], body),
                        trailing: Text(
                          _formatTimestamp(activity['timestamp']),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          _handleActivityTap(context, body, activity['type']);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
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

  void _handleActivityTap(
      BuildContext context, Map<String, dynamic> body, String type) async {
    if (type == 'appointment' && body['appointmentId'] != null) {
      final doctorUserDetails = await getUserDetails(body['doctorID']);
      print(doctorUserDetails);
      final doctorData = doctorUserDetails.data() as Map<String, dynamic>?; // Make doctorData nullable
      print(doctorData);
      if (context.mounted) {
        if (doctorData != null) {
          context.push('/user-appointment-detail/${body['appointmentId']}', extra: {'doctorData': doctorData});
        } else {
          // Handle the case where doctorData is null, e.g., show an error or a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Doctor details not found.')),
          );
        }
      }
    } else if (type == 'message' && body['chatRoomID'] != null) {
      debugPrint(body['id']);
      final recipientUserDetails = await getUserDetails(body['senderID']);
      final recipientFullName = recipientUserDetails['full_name'];
      if (context.mounted) {
        context.push('/chat/${body['chatRoomID']}', extra: {'recipientID': body['senderID'], 'recipientFullName': recipientFullName});
      }
    }
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
}
