import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';

class AIRedirection {



  Map<String, dynamic> getSelectedDoctor(List<DocumentSnapshot> doctors) {
    Map<String, dynamic> bestDoctor = {};
    
    // score doctors
    for (var doctor in doctors) {

      
    }

    // get the doctor with the highest score



    

    return bestDoctor;
    
  }







  // filter doctors
  Future<List<DocumentSnapshot>> getSpecializedDoctors(String specialization, int? minFee, int? maxFee) async {
    return await getVerifiedFilteredDoctorList(specialization: specialization, minFee: minFee, maxFee: maxFee);
  }



}
  