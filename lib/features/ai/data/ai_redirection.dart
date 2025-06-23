import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';

class AIRedirection {

  Map<String, dynamic> getSelectedDoctor(String? specialization, int? minFee, int? maxFee) {
    Map<String, dynamic> bestDoctor = {};
    double highestScore = -1;

    getVerifiedFilteredDoctorList(specialization: specialization!, minFee: minFee!, maxFee: maxFee!).then((doctors) {
      doctors.forEach((doc) {
      final userData = doc.data() as Map<String, dynamic>;

      const specializationScore = 20.0;
      const lowFeeScore = 30.0;
      double score = 0;

      if (userData['specialization'] == specialization) {
        score += specializationScore;
      }

      int fee = userData['consultation_fee'] ?? 0;
      score += (fee <= minFee) ? lowFeeScore : (fee <= maxFee ? lowFeeScore / 2 : 0);


      if (score > highestScore) {
        highestScore = score;
        bestDoctor = {
          'doc': doc,
          'score': score,
        };
      }
    });
    });

    return bestDoctor;
  }
  

  // navigate to doctor detail
  void navigateToDoctorDetail(BuildContext context, Map<String, dynamic> bestDoctor) {
    context.push('/doctor/${bestDoctor['doc'].id}', extra: {'docId': bestDoctor['doc'].id});
  }
  

  // fallback doctor
  void getFallbackDoctor(BuildContext context, String specialization, int? minFee, int? maxFee) async {
    context.push('/doctor-list', extra: {'specialization': specialization, 'minFee': minFee, 'maxFee': maxFee});
  }

}
  