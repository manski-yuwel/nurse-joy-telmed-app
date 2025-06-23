import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';

class AIRedirection {
  // navigate to doctor detail with loading state
  static Future<void> navigateToDoctor({
    required BuildContext context,
    required String specialization,
    int? minFee,
    int? maxFee,
  }) async {
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