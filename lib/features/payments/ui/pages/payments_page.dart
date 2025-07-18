import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:nursejoyapp/features/payments/ui/widgets/payments_debug.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import 'package:rxdart/rxdart.dart'; // Add this import at the top

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

  String _shortenCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }


  String _selectedRange = '1W';

  List<Map<String, dynamic>> _filterTransactionsByRange(List<Map<String, dynamic>> txs) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedRange) {
      case '1D':
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case '1W':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case '1Y':
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        cutoff = now.subtract(const Duration(days: 7));
    }

    return txs.where((tx) {
      final ts = tx['timestamp'];
      final dt = ts is Timestamp ? ts.toDate() : ts is DateTime ? ts : null;
      return dt != null && dt.isAfter(cutoff);
    }).toList();
  }



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
        labelColor: Color(0xFF58f0d7),       // Cyan for selected
        unselectedLabelColor: Colors.grey,   // Grey for unselected
        indicatorColor: Color(0xFF58f0d7),
        indicatorWeight: 3,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
  
  Widget _buildWalletView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wallet Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 0, 56, 49), // Teal
                  Color.fromARGB(255, 12, 131, 115), // Teal
                  Color(0xFF64FFDA), // Light mint
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance
                StreamBuilder<int>(
                  stream: currentUserId != null
                      ? _paymentsData.getBalance(currentUserId!)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final balance = (snapshot.data ?? 0).toDouble();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Balance text
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱${balance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 1),
                        // Mini line graph
                        SizedBox(
                          height: 40,
                          width: 100,
                          child: StreamBuilder<List<Map<String, dynamic>>>(
                            stream: currentUserId != null
                                ? _paymentsData.getUserTransactions(currentUserId!)
                                : const Stream.empty(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();
                              final txs = snapshot.data!;
                              txs.sort((a, b) => (a['timestamp'] as Timestamp).compareTo(b['timestamp'] as Timestamp));
                              final spots = <FlSpot>[];
                              double runningTotal = 0;

                              for (int i = 0; i < txs.length; i++) {
                                final tx = txs[i];
                                final amount = (tx['amount'] ?? 0).toDouble();
                                final isCashIn = tx['status'] == 'Cash In';
                                final isSent = tx['fromUserId'] == currentUserId;
                                final delta = isCashIn || !isSent ? amount : -amount;
                                runningTotal += delta;
                                spots.add(FlSpot(i.toDouble(), runningTotal));
                              }

                              final yVals = spots.map((e) => e.y).toList();
                              final minY = yVals.reduce(min);
                              final maxY = yVals.reduce(max);
                              final midY = (minY + maxY) / 2;

                              return LineChart(
                                LineChartData(
                                  minY: minY,
                                  maxY: maxY,
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: (value - midY).abs() < 1
                                          ? Colors.grey.withOpacity(0.3)
                                          : Colors.transparent,
                                      strokeWidth: 1,
                                      dashArray: [4, 3],
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      barWidth: 3,
                                      color: const Color(0xFF58f0d7),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF58f0d7).withOpacity(0.3),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                      dotData: FlDotData(
                                        show: true,
                                        checkToShowDot: (spot, _) => spot == spots.last,
                                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                                          radius: 3,
                                          color: Colors.black,
                                          strokeWidth: 2,
                                          strokeColor: const Color(0xFF58f0d7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 1),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Add Money button
                ElevatedButton.icon(
                  onPressed: _showAddMoneyDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Cash In'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF58f0d7),
                    foregroundColor: Colors.black87,
                  ),
                ),
                    
                const SizedBox(height: 8),

                // Powered by PayMongo
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Powered by  ',
                        style: TextStyle(fontSize: 12, color: Color.fromARGB(255, 211, 211, 211)),
                      ),
                      Image.asset(
                        'assets/img/paymongo_logo.png',
                        height: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF58f0d7), size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _mainTabController.animateTo(1); // 1 is the index for Transactions tab
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.cyan,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('View All', style: TextStyle(color: Color(0xFF58f0d7))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Recent items
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: currentUserId != null
                      ? Rx.combineLatest2(
                          _paymentsData.getUserTransactions(currentUserId!),
                          _paymentsData.getAllRefunds(currentUserId!),
                          (List<Map<String, dynamic>> txs, List<Map<String, dynamic>> refunds) {
                            for (final r in refunds) {
                              r['isRefund'] = true;
                            }
                            return [...txs, ...refunds];
                          },
                        )
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text("No recent activity", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    final items = snapshot.data!;
                    items.sort((a, b) {
                      final aTime = a['timestamp'] as Timestamp?;
                      final bTime = b['timestamp'] as Timestamp?;
                      return (bTime?.millisecondsSinceEpoch ?? 0)
                          .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
                    });
                    final recent = items.take(3).toList();

                    return Column(
                      children: recent.map((tx) {
                        final isRefund = tx['isRefund'] == true;
                        final isCashIn = tx['status'] == 'Cash In';
                        final isSent = tx['fromUserId'] == currentUserId;
                        final isReceived = tx['toUserId'] == currentUserId;
                        final amount = tx['amount'];
                        final status = tx['status'] ?? '';
                        final refundId = tx['refundId'] ?? '';
                        final fromUserName = tx['fromUserName'] ?? '';
                        final toUserName = tx['toUserName'] ?? '';
                        final timestamp = tx['timestamp'];
                        final formattedDate = timestamp != null && timestamp is Timestamp
                            ? DateFormat('MMM d, y - h:mm a').format(timestamp.toDate())
                            : '--';

                        if (isRefund) {
                          final isIncoming = tx['toUserId'] == currentUserId;
                          final amountPrefix = isIncoming ? '+' : '-';
                          final otherUserName = isIncoming ? fromUserName : toUserName;
                          final refundLabel = (status == 'Approved'
                            ? (isIncoming ? 'Refunded from $otherUserName' : 'Refunded to $otherUserName')
                            : (isIncoming ? 'Refund from $otherUserName' : 'Refund to $otherUserName'));
                          Color statusColor;
                          IconData icon;
                          switch (status) {
                            case 'Approved':
                              statusColor = Colors.green;
                              icon = Icons.verified;
                              break;
                            case 'Rejected':
                              statusColor = Colors.red;
                              icon = Icons.block;
                              break;
                            default:
                              statusColor = Colors.orange;
                              icon = Icons.hourglass_top;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(icon, color: statusColor, size: 26),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          amountPrefix,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          '₱$amount',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status,
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        refundLabel,
                                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        textAlign: TextAlign.right,
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                      Text(
                                        'Ref: $refundId',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Regular transaction
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
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
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${isCashIn || !isSent ? '+' : '-'}₱$amount',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      isCashIn
                                          ? 'Cash In'
                                          : isSent
                                              ? 'Sent to $toUserName'
                                              : 'Received from $fromUserName',
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                      textAlign: TextAlign.right, // <-- add this
                                    ),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    if (tx['transactionId'] != null)
                                      Text(
                                        'Ref: ${tx['transactionId']}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          )
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
            ? Rx.combineLatest2(
                _paymentsData.getUserTransactions(userId),
                _paymentsData.getApprovedRefunds(userId),
                (List<Map<String, dynamic>> txs, List<Map<String, dynamic>> refunds) {
                  for (final r in refunds) {
                    r['isRefund'] = true;
                  }
                  return [...txs, ...refunds];
                },
              )
            : const Stream.empty(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return Center(child: _buildEmptyTransactionState());
          }

          // Sort by timestamp descending
          items.sort((a, b) {
            final aTime = a['timestamp'] as Timestamp?;
            final bTime = b['timestamp'] as Timestamp?;
            return (bTime?.millisecondsSinceEpoch ?? 0)
                .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
          });

          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final tx = items[index];
              final isRefund = tx['isRefund'] == true;
              final isCashIn = tx['status'] == 'Cash In';
              final isSent = tx['fromUserId'] == userId;
              final isReceived = tx['toUserId'] == userId;
              final amount = tx['amount'];
              final status = tx['status'] ?? '';
              final refundId = tx['refundId'] ?? '';
              final fromUserName = tx['fromUserName'] ?? '';
              final toUserName = tx['toUserName'] ?? '';
              final timestamp = tx['timestamp'];
              final formattedDate = timestamp != null && timestamp is Timestamp
                  ? DateFormat('MMM d, y - h:mm a').format(timestamp.toDate())
                  : '--';

              if (isRefund) {
                final isIncoming = tx['toUserId'] == userId;
                final amountPrefix = isIncoming ? '+' : '-';
                final otherUserName = isIncoming ? (tx['fromUserName'] ?? '--') : (tx['toUserName'] ?? '--');
                final refundLabel = isIncoming
                    ? 'Refunded from $otherUserName'
                    : 'Refunded to $otherUserName';
                final statusColor = Colors.green; // Approved

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vertically centered icon
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              color: isIncoming ? Colors.green : Colors.red,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Amount and status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  amountPrefix,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  '₱$amount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Approved',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Trailing info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                refundLabel,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formattedDate,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Ref: $refundId',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Regular transactions
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), // ensure fontSize is 16
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isCashIn
                            ? 'Cash In'
                            : isSent
                                ? 'Sent to $toUserName'
                                : 'Received from $fromUserName',
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                      Text(
                        timestamp != null && timestamp is Timestamp
                            ? DateFormat('MMM d, y - h:mm a').format(timestamp.toDate())
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
                ),
              );            },
          );
        },
      ),
    );
  }

  Widget _buildRefundSummaryCounter({
  required int pending,
  required int approved,
  required int rejected,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Pending', pending.toString(), Colors.orange),
        _buildStatItem('Approved', approved.toString(), Colors.green),
        _buildStatItem('Rejected', rejected.toString(), Colors.red),
      ],
    );
  }


  Widget _buildStatItem(String label, String count, Color boxColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: boxColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              label == 'Approved'
                  ? Icons.verified
                  : label == 'Rejected'
                      ? Icons.block
                      : Icons.hourglass_top,
              color: Colors.black,
              size: 26,
            ),
            const SizedBox(height: 6),
            Text(
              count,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.4),
    );
  }

  Widget _buildRefundsView() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Center(child: Text('User not logged in.'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('refunds')
          .where('toUserId', isEqualTo: currentUserId) // optional: filter
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No refund records.'));
        }

        final refunds = docs.map((d) => d.data() as Map<String, dynamic>).toList();

        final pending = refunds.where((r) => r['status'] == 'Pending').length;
        final approved = refunds.where((r) => r['status'] == 'Approved').length;
        final rejected = refunds.where((r) => r['status'] == 'Rejected').length;

        Color getStatusColor(String status) {
          switch (status) {
            case 'Approved':
              return Colors.green.shade600;
            case 'Rejected':
              return Colors.red.shade300;
            default:
              return Colors.orange.shade400;
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: refunds.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildRefundSummaryCounter(
                pending: pending,
                approved: approved,
                rejected: rejected,
              );
            }

            if (index == 1) return const SizedBox(height: 8);

            final refund = refunds[index - 2];
            final amount = refund['amount'] ?? 0;
            final status = refund['status'] ?? 'Pending';
            final txnId = refund['refundId'] ?? '--';
            final timestamp = (refund['timestamp'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null
                ? DateFormat('MMM d, y – h:mm a').format(timestamp)
                : '--';

            return ListTile(
              leading: Icon(
                status == 'Approved'
                    ? Icons.verified
                    : status == 'Rejected'
                        ? Icons.block
                        : Icons.hourglass_top,
                color: status == 'Approved'
                    ? Colors.green
                    : status == 'Rejected'
                        ? Colors.red
                        : Colors.orange,
              ),
              title: Text('₱$amount'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    status == 'Approved'
                        ? 'Refunded from ${refund['fromUserName'] ?? '--'}'
                        : 'Refund from ${refund['fromUserName'] ?? '--'}',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('Ref: $txnId', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          },
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
                Builder(
                  key: ValueKey<int>(_mainTabController.index),
                  builder: (_) => _buildWalletView(),
                ),
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
