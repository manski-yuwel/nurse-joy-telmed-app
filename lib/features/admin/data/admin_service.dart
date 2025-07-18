import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getPendingDoctorApplications() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .where('verification_status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> updateDoctorVerificationStatus(
      String doctorId, String status) async {
    await _db.collection('users').doc(doctorId).update({
      'verification_status': status,
      'is_verified': status == 'approved',
      'verification_date': Timestamp.now(),
    });
  }
}
