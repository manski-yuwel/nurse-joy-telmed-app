import 'package:cloud_firestore/cloud_firestore.dart';

class AIRedirection {


  // filter doctors
  Future<QuerySnapshot> getSpecializedDoctors(String specialization) async {
    return await FirebaseFirestore.instance.collection('users').where('doctor_information.specialization', isEqualTo: specialization).get();
  }



}
  