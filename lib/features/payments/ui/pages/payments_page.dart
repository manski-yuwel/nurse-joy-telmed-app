import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:nursejoyapp/features/payments/ui/widgets/payments_debug.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage>
    with TickerProviderStateMixin {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final PaymentsData _paymentsData = PaymentsData();
  late final TabController _mainTabController;
  late final Stream<List<Map<String, dynamic>>> _transactionStream;


  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
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
                                const SnackBar(content: Text('Money added successfully!')),
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
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text("GCash")),
                          body: WebViewWidget(controller: controller),
                        ),
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

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _mainTabController,
        isScrollable: true,
        tabs: const [
          Tab(icon: Icon(Icons.account_balance_wallet), text: 'Wallet'),
          Tab(icon: Icon(Icons.list_alt), text: 'Transactions'),
          Tab(icon: Icon(Icons.replay_circle_filled), text: 'Refunds'),
          Tab(icon: Icon(Icons.bug_report), text: 'Debug'),
        ],
        labelColor: const Color(0xFF58f0d7),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF58f0d7),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildWalletView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<int>(
            stream: currentUserId != null
                ? _paymentsData.getBalance(currentUserId!)
                : const Stream.empty(),
            builder: (context, snapshot) {
              return Text(
                'Balance: ₱${snapshot.data ?? '--'}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddMoneyDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Money'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58f0d7),
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey),
        SizedBox(height: 12),
        Text(
          'No Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Your transaction history will show up here once you start using the app.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildTransactionsView() {
    final userId = currentUserId;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: userId != null
            ? _paymentsData.getUserTransactions(userId)
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data!;
          if (transactions.isEmpty) {
            return Center(child: _buildEmptyTransactionState());
          }

          return ListView.separated(
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final isCashIn = tx['status'] == 'Cash In';
              final isSent = tx['fromUserId'] == userId;
              final amount = tx['amount'];

              return ListTile(
                leading: Icon(
                  isCashIn
                      ? Icons.account_balance_wallet
                      : isSent
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                  color: isCashIn
                      ? Colors.green
                      : isSent
                          ? Colors.red
                          : Colors.green,
                ),
                title: Text(
                  '${isCashIn || !isSent ? '+' : '-'}₱$amount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  isCashIn
                      ? 'Cash In'
                      : isSent
                          ? 'Sent to ${tx['toUserName']}'
                          : 'Received from ${tx['fromUserName']}',
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  Widget _buildRefundsView() {
    // Placeholder: Replace with your actual refund stream/list
    final mockRefunds = [
      {'amount': 300, 'status': 'Pending'},
      {'amount': 200, 'status': 'Approved'},
      {'amount': 150, 'status': 'Rejected'},
    ];

    Color getStatusColor(String status) {
      switch (status) {
        case 'Approved':
          return Colors.green;
        case 'Rejected':
          return Colors.red;
        default:
          return Colors.orange;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: mockRefunds.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final refund = mockRefunds[index];
        return ListTile(
          leading: const Icon(Icons.money_off, color: Colors.blueGrey),
          title: Text('₱${refund['amount']}'),
          subtitle: Text(refund['status'] as String),
          trailing: Chip(
            label: Text(refund['status'] as String),
            backgroundColor: getStatusColor(refund['status'] as String),
            labelStyle: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Payments',
      selectedIndex: 0,
      onItemTapped: (i) => context.go(i == 0 ? '/chat' : i == 1 ? '/home' : '/profile'),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                _buildWalletView(),
                Builder(
                  key: ValueKey<int>(_mainTabController.index),
                  builder: (_) => _buildTransactionsView(),
                ),
                _buildRefundsView(),
                if (currentUserId != null) DebugButtons(currentUserId: currentUserId!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
