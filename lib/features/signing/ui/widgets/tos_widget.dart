import 'package:flutter/material.dart';

class TermsAndPrivacyDialog extends StatefulWidget {
  const TermsAndPrivacyDialog({super.key});

  @override
  State<TermsAndPrivacyDialog> createState() => _TermsAndPrivacyDialogState();
}

class _TermsAndPrivacyDialogState extends State<TermsAndPrivacyDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToEnd = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final current = _scrollController.offset;
      if (!_hasScrolledToEnd && current >= maxScroll - 20) {
        setState(() => _hasScrolledToEnd = true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    children: const [
                      Text(
                        "Terms of Service",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "1. Acceptance of Terms\n"
                        "By using Nurse Joy, you agree to these Terms of Service and any applicable laws.\n",
                      ),
                      Text(
                        "2. User Accounts\n"
                        "You are responsible for providing accurate information and safeguarding your login credentials.\n",
                      ),
                      Text(
                        "3. AI Assistance\n"
                        "Nurse Joy provides AI-based support and guidance. It is not a substitute for licensed medical advice.\n",
                      ),
                      Text(
                        "4. Healthcare Consultations\n"
                        "Health advice and consultations provided are AI-generated or doctor-guided, not clinical diagnoses.\n",
                      ),
                      Text(
                        "5. Payment System\n"
                        "Payments are processed securely through PayMongo. The app does not support wallet-to-wallet transfers or hold funds internally.\n",
                      ),
                      Text(
                        "6. Appointment Bookings\n"
                        "Booking a doctor initiates a service request. It is subject to confirmation by the doctor.\n",
                      ),
                      Text(
                        "7. Refunds\n"
                        "Refund requests must be made within 7 days of payment. Final decisions rest with platform administrators.\n",
                      ),
                      Text(
                        "8. Profile Management\n"
                        "Users are expected to maintain accurate and up-to-date personal and medical information in their profiles.\n",
                      ),
                      Text(
                        "9. Notifications\n"
                        "You agree to receive important notifications related to bookings, health prompts, and account activities.\n",
                      ),
                      Text(
                        "10. System Reliability\n"
                        "This platform undergoes routine system tests across chat, AI, auth, payments, profile, healthcare, and notification modules.\n",
                      ),
                      Text(
                        "11. Termination\n"
                        "Violation of terms may lead to suspension or deletion of your account without prior notice.\n",
                      ),
                      Text(
                        "12. Changes to Terms\n"
                        "These terms may be updated periodically. Continued use implies acceptance of any modifications.\n",
                      ),
                      Divider(),
                      Text(
                        "Privacy Policy",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "1. Data Collection\n"
                        "We collect information you provide directly, such as name, email, and medical records.\n",
                      ),
                      Text(
                        "2. Use of Data\n"
                        "Data is used to provide services including AI consultations, appointment booking, and payment processing.\n",
                      ),
                      Text(
                        "3. Data Storage\n"
                        "All user data is stored securely using Firebase. Access is controlled and encrypted.\n",
                      ),
                      Text(
                        "4. Sharing of Information\n"
                        "We do not sell personal data. Information is only shared with your consent or when required by law.\n",
                      ),
                      Text(
                        "5. Third-party Services\n"
                        "We integrate services like Firebase and PayMongo. Each has its own data handling policies.\n",
                      ),
                      Text(
                        "6. Your Rights\n"
                        "You have the right to access, update, or delete your personal data. Contact support to request changes.\n",
                      ),
                      Text(
                        "7. Privacy Policy Updates\n"
                        "We may modify this policy over time. Users will be notified of material changes.\n",
                      ),
                      Divider(),
                      Text(
                        "Disclaimer\n",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 12),
                      Text(
                        "This app is a supplemental healthcare support tool. For medical emergencies, contact licensed professionals.\n",
                      ),
                      Divider(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CheckboxListTile(
                value: _isChecked,
                onChanged: _hasScrolledToEnd
                    ? (value) => setState(() => _isChecked = value ?? false)
                    : null,
                title: const Text(
                  "I agree to the Terms and Privacy Policy.",
                  style: TextStyle(fontSize: 13.5), // Smaller font
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                visualDensity: VisualDensity(horizontal: -4, vertical: -4), // Reduced height
              ),
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isChecked ? () => Navigator.of(context).pop(true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58f0d7),
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text("Agree"),
                ),
                const SizedBox(width: 16),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
