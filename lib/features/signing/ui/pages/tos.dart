// tos.dart
import 'package:flutter/material.dart';

class TermsOfServiceDialog extends StatefulWidget {
  final void Function(bool agreed) onResult;

  const TermsOfServiceDialog({super.key, required this.onResult});

  @override
  State<TermsOfServiceDialog> createState() => _TermsOfServiceDialogState();
}

class _TermsOfServiceDialogState extends State<TermsOfServiceDialog> {
  bool _scrolledToEnd = false;
  bool _checked = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrolledToEnd &&
          _scrollController.offset >= _scrollController.position.maxScrollExtent) {
        setState(() {
          _scrolledToEnd = true;
        });
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
    return AlertDialog(
      title: const Text("Terms of Service"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: const Text(
                    // Replace with your TOS text
                    "Section 1: Overview\n\n"
                    "You agree to the use of Nurse Joy AI Assistant.\n\n"
                    "Section 2: System Testing\n\n"
                    "Includes test cases across modules: Chat, Auth, Payments, Profile, AI, etc.\n\n"
                    "Section 3: Disclaimer\n\n"
                    "**AI Nurse Joy is not a licensed medical professional.**\n\n"
                    "Consult a real healthcare provider if needed.\n\n"
                    "Section 4: Your Responsibilities\n\n"
                    "Only use the system for lawful and honest medical queries.",
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _checked,
                  onChanged: _scrolledToEnd
                      ? (val) => setState(() => _checked = val ?? false)
                      : null,
                ),
                const Expanded(
                  child: Text("I have read and agree to the Terms."),
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onResult(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: (_scrolledToEnd && _checked)
              ? () => widget.onResult(true)
              : null,
          child: const Text("Agree"),
        ),
      ],
    );
  }
}
