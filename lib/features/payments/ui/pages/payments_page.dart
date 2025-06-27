import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int _selectedIndex = -1;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<String> eWallets = ['GCash']; // Example e-wallets

  void _addEWallet() {
    setState(() {
      eWallets.add('GCash');
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.push('/chat');
    } else if (index == 1) {
      context.push('/home');
    } else if (index == 2) {
      context.push('/profile');
    // Handle bottom nav taps if needed
    }
  }

  void _showSendMoneyDialog() async {
    final _amountController = TextEditingController();
    final doctors = await PaymentsData.getDoctors();
    String? selectedDoctorId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Send Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedDoctorId,
                hint: const Text('Select Doctor'),
                items: doctors.map<DropdownMenuItem<String>>((doc) {
                  return DropdownMenuItem<String>(
                    value: doc['uid'] as String,
                    child: Text(doc['name'] ?? doc['email'] ?? doc['uid']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedDoctorId = val),
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
                if (amount != null &&
                    amount > 0 &&
                    selectedDoctorId != null &&
                    currentUserId != null) {
                  await PaymentsData.addTransaction(
                    fromUserId: currentUserId!,
                    toUserId: selectedDoctorId!,
                    amount: amount,
                  );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transaction successful!')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Payments",
      selectedIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
      onItemTapped: _onItemTapped,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _showSendMoneyDialog,
              icon: const Icon(Icons.send),
              label: const Text('Send Money'),
            ),
            const SizedBox(height: 8),
            const Text('Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: PaymentsData.getUserTransactions(currentUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final transactions = snapshot.data!;
                  if (transactions.isEmpty) {
                    return const Center(child: Text('No transactions yet.'));
                  }
                  return ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return ListTile(
                        leading: const Icon(Icons.receipt_long),
                        title: Text('₱${tx['amount']}'),
                        subtitle: Text('${tx['timestamp']?.toDate() ?? ''}'),
                        trailing: Text('${tx['status']}'),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('E-Wallets',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: _addEWallet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add E-Wallet'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: eWallets.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(eWallets[index]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}