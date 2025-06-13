import 'package:flutter/material.dart';
import '../widgets/base_page.dart';
import 'package:go_router/go_router.dart';

class WaitVerificationPage extends StatelessWidget {
  const WaitVerificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Account Pending Verification",
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            "Thank you for registering as a healthcare professional!\n\nOur administrators are now reviewing your credentials. This usually takes less than 24 hours. You'll receive an email notification once your account has been approved.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(color: Color(0xFF58f0d7)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/signin'),
              icon: const Icon(Icons.login),
              label: const Text('Back to Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}