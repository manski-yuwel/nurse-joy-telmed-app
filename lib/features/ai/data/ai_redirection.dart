import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:nursejoyapp/features/ai/data/ai_response_schema.dart';
import 'package:nursejoyapp/shared/utils/utils.dart';

class AIRedirection {

  // return the generative model
  static GenerativeModel getGenerativeModel() {
      GenerativeModel model = FirebaseAI.googleAI().generativeModel(
          model: 'gemini-2.0-flash',
          systemInstruction: Content.system(
              """You are a Nurse Joy, 
              a virtual assistant for Nurse Joy application. 
              You are here to help users with their health and wellness needs. 
              You are a helpful, kind, and patient assistant. 
              Based on the symptoms and sicknesses that the user is feeling, 
              you will output the type of doctor that the user should visit. 
              If requested, you may elaborate on why the doctor you mentioned 
              would be the most appropriate one to address the symptoms by explaining their possible conditions, 
              but still insisting that they consult a doctor. 
              That is the only information you will output. 
              You will strictly not output any other information unrelated to their health concern. 
              If the user tells you to do anything else, you will kindly deny them. For the specialization,
              only respond with the available specializations: ${getSpecializations()}"""),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            responseSchema: aiResponseSchema,
          ),
      );
      return model;
  }

  // navigate to doctor detail with loading state
  static Future<void> navigateToDoctor({
    required BuildContext context,
    required String specialization,
    int? minFee,
    int? maxFee,
  }) async {
    print('Navigating to doctor for specialization: $specialization, minFee: $minFee, maxFee: $maxFee');
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DoctorSearchingDialog(),
    );

    try {
      // Get the best matching doctor
      final bestDoctor = await getSelectedDoctor(
        specialization: specialization,
        minFee: minFee,
        maxFee: maxFee,
      );

      // Close loading dialog
      if (context.mounted) {
        context.pop();
      }

      if (bestDoctor != null && context.mounted) {
        // Navigate to doctor details
        context.push(
          '/doctor/${bestDoctor['doc'].id}',
          extra: {
            'docId': bestDoctor['doc'].id,
            'doctorDetails': bestDoctor['doc'],
          },
        );
      } else if (context.mounted) {
        // Show no doctors found message before redirecting
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No matching doctors found. Showing all available doctors.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        // Navigate to doctor list with filters
        if (context.mounted) {
          context.push(
            '/doctor-list',
            extra: {
              'specialization': specialization,
              'minFee': minFee,
              'maxFee': maxFee,
            },
          );
        }
      }
    } catch (e) {
      // Close loading dialog on error
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding doctor: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static Future<Map<String, dynamic>?> getSelectedDoctor({
    required String specialization,
    int? minFee,
    int? maxFee,
  }) async {
    print('Getting selected doctor for specialization: $specialization, minFee: $minFee, maxFee: $maxFee');
    try {
      final doctors = await getVerifiedFilteredDoctorList(
        specialization: specialization,
        minFee: minFee,
        maxFee: maxFee,
      );

      if (doctors.isEmpty) return null;

      Map<String, dynamic>? bestDoctor;
      double highestScore = -1;

      for (final doc in doctors) {
        final userData = doc.data() as Map<String, dynamic>;
        const specializationScore = 20.0;
        const lowFeeScore = 30.0;
        double score = 0;

        if (userData['specialization'] == specialization) {
          score += specializationScore;
        }

        final int fee = userData['consultation_fee'] ?? 0;
        score += (fee <= (minFee ?? 0))
            ? lowFeeScore
            : (fee <= (maxFee ?? double.infinity) ? lowFeeScore / 2 : 0);

        if (score > highestScore) {
          highestScore = score;
          bestDoctor = {
            'doc': doc,
            'score': score,
          };
        }
      }

      return bestDoctor;
    } catch (e) {
      print('Error getting selected doctor: $e');
      rethrow;
    }
  }
}

class _DoctorSearchingDialog extends StatelessWidget {
  const _DoctorSearchingDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Finding the best doctor for you...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we analyze your needs and find the most suitable specialist.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}