import 'package:flutter/material.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  int _selectedIndex = -1;
  // Example data
  List<String> eWallets = ['GCash'];
  List<Map<String, String>> transactions = [
    {'date': '2025-06-24', 'amount': '₱500', 'status': 'Completed'},
    {'date': '2025-06-23', 'amount': '₱200', 'status': 'Pending'},
  ];

  void _addEWallet() {
    // For demo, just add another GCash wallet
    setState(() {
      eWallets.add('GCash');
    });
  }

  void _onItemTapped(int index) {

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
            const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text('${tx['amount']}'),
                    subtitle: Text('${tx['date']}'),
                    trailing: Text('${tx['status']}'),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('E-Wallets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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