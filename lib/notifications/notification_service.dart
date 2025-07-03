import 'package:cloud_firestore/cloud_firestore.dart';

/* 
the activity structure should be:

title,
body Map<String, dynamic>,
type,
timestamp
*/


/* 
types would be:
appointment,
message,

if the type is appointment,
the body should include the appointmentID, doctorID, appointmentDateTime

if the type is message,
the body should include the chatRoomID, senderID, recipientID, messageBody
*/
class NotificationService {
  final FirebaseFirestore _firestore;
  
  NotificationService({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;


  Stream<QuerySnapshot> getActivities(String userID) {
    return _firestore.collection('activity_log').where('userID', isEqualTo: userID).orderBy('timestamp', descending: true).limit(5).snapshots();
  }


  Stream<QuerySnapshot> getAllActivities() {
    return _firestore.collection('activity_log').orderBy('timestamp', descending: true).snapshots();
  }


  Future<void> registerActivity(String userID, String title, Map<String, dynamic> body, String type) async {
    await _firestore.collection('activity_log').add({
      'userID': userID,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }


  Map<String, dynamic> resolveActivityBody(String type, Map<String, dynamic> body) {
    switch (type) {
      case 'appointment':
        return {
          'id': body['id'],
          'appointmentID': body['appointmentID'],
          'doctorID': body['doctorID'],
          'appointmentDateTime': body['appointmentDateTime'],
        };
      case 'message':
        return {
          'id': body['id'],
          'chatRoomID': body['chatRoomID'],
          'senderID': body['senderID'],
          'recipientID': body['recipientID'],
          'messageBody': body['messageBody'],
        };
      default:
        return {};
    }
  }



}