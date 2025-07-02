import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';

class DebugButtons extends StatelessWidget {
  final String? currentUserId;

  DebugButtons({super.key, required this.currentUserId});

  final PaymentsData _paymentsData = PaymentsData();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEND TO ANY USER
        ElevatedButton.icon(
          icon: const Icon(Icons.bug_report),
          label: const Text('Debug: Send to Any User'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () async {
            final _amountController = TextEditingController();
            String? targetUserId;

            final users = await FirebaseFirestore.instance.collection('users').get();
            final userList = users.docs.map((doc) {
              final data = doc.data();
              return {
                'uid': doc.id,
                'name': data['first_name'] ?? data['email'] ?? doc.id,
              };
            }).toList();

            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text('Debug: Send to Any User'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: targetUserId,
                        hint: const Text('Select User'),
                        items: userList.map<DropdownMenuItem<String>>((user) {
                          return DropdownMenuItem<String>(
                            value: user['uid'],
                            child: Text(user['name']),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => targetUserId = val),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₱',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final amount = int.tryParse(_amountController.text.trim());
                        if (amount == null || amount <= 0 || targetUserId == null || currentUserId == null) {
                          return;
                        }

                        final balance = await _paymentsData.getBalance(currentUserId!).first;
                        if (amount > balance) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Insufficient balance!')),
                          );
                          return;
                        }

                        await _paymentsData.addTransaction(
                          fromUserId: currentUserId!,
                          toUserId: targetUserId!,
                          amount: amount,
                        );

                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debug transaction sent!')),
                        );
                      },
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // RESET BALANCES
        ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Debug: Reset Database Balances'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 32, 143, 163)),
          onPressed: () async {
            final users = await FirebaseFirestore.instance.collection('users').get();
            final batch = FirebaseFirestore.instance.batch();

            for (final doc in users.docs) {
              batch.update(doc.reference, {'balance': 0});
            }

            await batch.commit();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All balances reset to ₱0')),
            );
          },
        ),
        const SizedBox(height: 8),

        // CLEAR TRANSACTIONS
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_forever),
          label: const Text('Debug: Clear All Database Transactions'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            final txs = await FirebaseFirestore.instance.collection('transactions').get();
            final batch = FirebaseFirestore.instance.batch();

            for (final doc in txs.docs) {
              batch.delete(doc.reference);
            }

            await batch.commit();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('All transactions deleted')),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
