import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:nursejoyapp/features/payments/ui/widgets/payments_debug.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int _selectedIndex = -1;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
  List<String> eWallets = ['GCash'];
  final PaymentsData _paymentsData = PaymentsData();

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
    }
  }

  void _showAddMoneyDialog() {
    final _amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Money'),
        content: TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₱',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(_amountController.text.trim());
              if (amount != null && amount > 0 && currentUserId != null) {
                try {
                  await _paymentsData.addMoney(userId: currentUserId!, amount: amount);
                } catch (e) {
                  if (e is Map && e.containsKey('redirectUrl')) {
                    final redirectUrl = e['redirectUrl'];
                    Navigator.of(context).pop();

                    final controller = WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(redirectUrl))
                      ..setNavigationDelegate(
                        NavigationDelegate(
                          onNavigationRequest: (nav) {
                            if (nav.url.contains('nursejoy/success')) {
                              Navigator.of(context).pop();
                              _paymentsData.addMoney(
                                userId: currentUserId!,
                                amount: amount,
                                skipRedirect: true,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Money added after successful payment!'),
                                ),
                              );
                              return NavigationDecision.prevent;
                            } else if (nav.url.contains('nursejoy/cancel')) {
                              Navigator.of(context).pop();
                              return NavigationDecision.prevent;
                            }
                            return NavigationDecision.navigate;
                          },
                        ),
                      );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GCashWebViewPage(controller: controller),
                      ),
                    );


                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to initiate payment: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "Payments",
      selectedIndex: _selectedIndex == -1 ? 0 : _selectedIndex,
      onItemTapped: _onItemTapped,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StreamBuilder<int>(
                  stream: currentUserId != null
                      ? _paymentsData.getBalance(currentUserId!)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Text('Balance: ₱--',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                    }
                    return Text(
                      'Balance: ₱${snapshot.data}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                ElevatedButton.icon(
                  onPressed: _showAddMoneyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Money'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (currentUserId != null) DebugButtons(currentUserId: currentUserId!),
            const Text('Transaction History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _paymentsData.getUserTransactions(currentUserId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final transactions = snapshot.data!;
                  if (transactions.isEmpty) {
                    return const Center(child: Text('No transactions yet.'));
                  }

                  final List<Map<String, dynamic>> allTxs = [];

                  for (final tx in transactions) {
                    final isSent = tx['fromUserId'] == currentUserId;
                    final isReceived = tx['toUserId'] == currentUserId;
                    final isSelf = tx['fromUserId'] == tx['toUserId'] && isSent;
                    final isCashIn = tx['status'] == 'Cash In';
                    final sortTime = (tx['timestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

                    if (isCashIn && isSelf) {
                      allTxs.add({
                        ...tx,
                        'amountPrefix': '+',
                        'directionText': 'Cash In',
                        'sortTime': sortTime,
                      });
                      continue;
                    }

                    if (isSelf && !isCashIn) {
                      allTxs.add({
                        ...tx,
                        'amountPrefix': '-',
                        'directionText': 'Sent to Myself',
                        'sortTime': sortTime,
                      });
                      allTxs.add({
                        ...tx,
                        'amountPrefix': '+',
                        'directionText': 'Received from Myself',
                        'sortTime': sortTime,
                      });
                      continue;
                    }

                    if (isSent) {
                      allTxs.add({
                        ...tx,
                        'amountPrefix': '-',
                        'directionText': 'Sent to ${tx['toUserName']}',
                        'sortTime': sortTime,
                      });
                    } else if (isReceived) {
                      allTxs.add({
                        ...tx,
                        'amountPrefix': '+',
                        'directionText': 'Received from ${tx['fromUserName']}',
                        'sortTime': sortTime,
                      });
                    }
                  }

                  return ListView.builder(
                    itemCount: allTxs.length,
                    itemBuilder: (context, index) {
                      final tx = allTxs[index];
                      return ListTile(
                        leading: Icon(
                          tx['amountPrefix'] == '-' ? Icons.arrow_upward : Icons.arrow_downward,
                          color: tx['amountPrefix'] == '-' ? Colors.red : Colors.green,
                        ),
                        title: Text('${tx['amountPrefix']}₱${tx['amount']}'),
                        subtitle: Text(tx['directionText']),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              tx['timestamp'] != null
                                  ? DateFormat('MMM d, y - h:mm a')
                                      .format((tx['timestamp'] as Timestamp).toDate())
                                  : '--',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (tx['transactionId'] != null)
                              Text(
                                'Ref: ${tx['transactionId']}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                          ],
                        ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          const Icon(Icons.account_balance_wallet, color: Colors.blue),
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

class GCashWebViewPage extends StatelessWidget {
  final WebViewController controller;

  const GCashWebViewPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GCash Payment"),
        leading: BackButton(
          onPressed: () async {
            if (await controller.canGoBack()) {
              controller.goBack();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}

