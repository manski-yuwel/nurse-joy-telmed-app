import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:nursejoyapp/features/payments/data/payments_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';

class DigitalReceiptDialog extends StatefulWidget {
  final AppointmentBooking booking;
  final String doctorId;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int amount;

  const DigitalReceiptDialog({
    super.key,
    required this.booking,
    required this.doctorId,
    required this.onConfirm,
    required this.onCancel,
    required this.amount,
  });

  @override
  State<DigitalReceiptDialog> createState() => _DigitalReceiptDialogState();
}

class _DigitalReceiptDialogState extends State<DigitalReceiptDialog> {
  bool _isProcessing = false;
  bool _isLoading = true;

  int _balance = 0;
  String _userAccountName = '';
  String _doctorAccountName = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doctorDocRef = FirebaseFirestore.instance.collection('users').doc(widget.doctorId);

    try {
      final userSnap = await userDocRef.get();
      final doctorSnap = await doctorDocRef.get();

      final userData = userSnap.data();
      final doctorData = doctorSnap.data();

      final balance = await PaymentsData.getBalance(userId).first;

      setState(() {
        _balance = balance;
        _userAccountName = userData?['full_name'] ?? 'You';
        _doctorAccountName = doctorData?['full_name'] ?? 'Doctor';
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching names: $e');
      setState(() {
        _userAccountName = 'You';
        _doctorAccountName = 'Doctor';
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePayment() async {
    final total = widget.amount;

    if (_balance < total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient balance.'),
          backgroundColor: Colors.black87,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final fromUserId = FirebaseAuth.instance.currentUser!.uid;
      final toUserId = widget.doctorId;

      await PaymentsData.addTransaction(
        fromUserId: fromUserId,
        toUserId: toUserId,
        amount: widget.amount,
        status: 'Appointment Payment',
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;
      Navigator.of(context).pop(); // close receipt dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Appointment booked successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onConfirm();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointmentDate = DateFormat('MMM d, yyyy - h:mm a')
        .format(widget.booking.appointmentDateTime);
    final tax = 0.00;
    final total = widget.amount + tax;
    final remainingBalance = _balance - total;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Appointment Receipt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Divider(thickness: 1),
        ],
      ),
      content: _isProcessing || _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('From: $_userAccountName'),
                Text('To: $_doctorAccountName'),
                const SizedBox(height: 8),
                Text('Appointment: $appointmentDate'),
                const Divider(),
                Text('Amount: ₱${widget.amount.toStringAsFixed(2)}'),
                Text('Tax: ₱${tax.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Total: ₱${total.toStringAsFixed(2)}'),
                Text('Current Balance: ₱$_balance'),
                Text('Remaining Balance: ₱$remainingBalance'),
              ],
            ),
      actions: _isProcessing || _isLoading
          ? []
          : [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel Booking'),
              ),
              ElevatedButton(
                onPressed: _handlePayment,
                child: const Text('Pay & Confirm'),
              ),
            ],
    );
  }
}
