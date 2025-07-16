import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:intl/intl.dart';

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
                          skipRedirect: true,
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

        ElevatedButton.icon(
          icon: const Icon(Icons.request_page),
          label: const Text('Debug: Request Refund from User'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
          onPressed: () async {
            final users = await FirebaseFirestore.instance.collection('users').get();
            final userList = users.docs
                .where((doc) => doc.id != currentUserId)
                .map((doc) {
                  final data = doc.data();
                  return {
                    'uid': doc.id,
                    'name': data['first_name'] ?? data['email'] ?? doc.id,
                    'balance': data['balance'] ?? 0,
                  };
                })
                .where((u) => u['balance'] > 0)
                .toList();

            if (userList.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No users with non-zero balance.')),
              );
              return;
            }

            String? selectedUserId;
            int? selectedUserBalance;
            final _amountController = TextEditingController();

            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setState) => AlertDialog(
                  title: const Text('Request Refund from User'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        hint: const Text('Select User'),
                        value: selectedUserId,
                        items: userList.map<DropdownMenuItem<String>>((user) {
                          return DropdownMenuItem<String>(
                            value: user['uid'],
                            child: Text('${user['name']} (₱${user['balance']})'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            selectedUserId = val;
                            selectedUserBalance = userList.firstWhere((u) => u['uid'] == val)['balance'];
                          });
                        },
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
                        if (selectedUserId == null || amount == null || amount <= 0 || selectedUserBalance == null) return;
                        if (amount > selectedUserBalance!) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Amount exceeds user balance')),
                          );
                          return;
                        }

                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(selectedUserId).get();
                        final fromUserName = userDoc.data()?['first_name'] ?? userDoc.data()?['email'] ?? selectedUserId;

                        final refundRef = FirebaseFirestore.instance.collection('refunds').doc();
                        final refundDoc = {
                          'refundId': refundRef.id,
                          'fromUserId': selectedUserId,
                          'fromUserName': fromUserName, // <-- Add this line
                          'toUserId': currentUserId,
                          'amount': amount,
                          'status': 'Pending',
                          'timestamp': FieldValue.serverTimestamp(),
                        };

                        await refundRef.set(refundDoc);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Refund request created')),
                        );
                      },
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Refund Requests (Admin Only)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Refund Admin List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('refunds')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No refund requests found.'));
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;

                  final refundId = data['refundId'] ?? '--';
                  final amount = data['amount'] ?? 0;
                  final status = data['status'] ?? 'Pending';
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final formattedDate = timestamp != null
                      ? DateFormat('MMM d, y – h:mm a').format(timestamp)
                      : '--';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.money_off_csred, color: Colors.teal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₱$amount • $status'),
                              Text('Ref: $refundId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                        if (status == 'Pending') ...[
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await _paymentsData.processRefund(docId, approve: true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Refund approved.')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () async {
                              await _paymentsData.processRefund(docId, approve: false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Refund rejected.')),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
