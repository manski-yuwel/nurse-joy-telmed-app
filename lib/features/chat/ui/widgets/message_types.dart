import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class PrescriptionForm extends StatefulWidget {
  final String chatRoomId;
  final String senderId;
  final String recipientId;

  const PrescriptionForm({
    super.key,
    required this.chatRoomId,
    required this.senderId,
    required this.recipientId,
  });

  @override
  State<PrescriptionForm> createState() => _PrescriptionFormState();
}

class _PrescriptionFormState extends State<PrescriptionForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  List<Map<String, dynamic>> medicines = [];

  Widget _buildMedicineForm(int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medicine ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (index > 0)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        medicines.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FormBuilderTextField(
              name: 'medicine_name_$index',
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'dosage_$index',
              decoration: const InputDecoration(
                labelText: 'Dosage',
                hintText: 'e.g., 1 tablet twice daily',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'duration_$index',
              decoration: const InputDecoration(
                labelText: 'Duration',
                hintText: 'e.g., 7 days',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
              ]),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'instructions_$index',
              decoration: const InputDecoration(
                labelText: 'Instructions',
                hintText: 'e.g., Take after meals',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Write Prescription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: FormBuilder(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ...List.generate(
                                medicines.length,
                                (index) => _buildMedicineForm(index),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    medicines.add({});
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Medicine'),
                              ),
                              const SizedBox(height: 16),
                              FormBuilderTextField(
                                name: 'notes',
                                decoration: const InputDecoration(
                                  labelText: 'Additional Notes',
                                  hintText:
                                      'Any additional instructions or notes',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.saveAndValidate() ??
                                  false) {
                                final formData = _formKey.currentState!.value;
                                final List<Map<String, dynamic>>
                                    prescriptionMedicines = [];

                                for (var i = 0; i < medicines.length; i++) {
                                  prescriptionMedicines.add({
                                    'medicine_name':
                                        formData['medicine_name_$i'],
                                    'dosage': formData['dosage_$i'],
                                    'duration': formData['duration_$i'],
                                    'instructions':
                                        formData['instructions_$i'] ?? '',
                                  });
                                }

                                final prescriptionData = {
                                  'medicines': prescriptionMedicines,
                                  'notes': formData['notes'] ?? '',
                                  'timestamp': FieldValue.serverTimestamp(),
                                };

                                MessageTypes.sendPrescriptionMessage(
                                  chatRoomId: widget.chatRoomId,
                                  senderId: widget.senderId,
                                  recipientId: widget.recipientId,
                                  prescriptionData: prescriptionData,
                                );

                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Send Prescription'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageTypes {
  static String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inDays == 0) {
      return DateFormat('h:mm a').format(messageTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(messageTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('E, h:mm a').format(messageTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(messageTime);
    }
  }

  static Widget buildPrescriptionMessage({
    required BuildContext context,
    required DocumentSnapshot message,
    required bool isMe,
    required String recipientFullName,
    Map<String, dynamic>? recipientData,
  }) {
    final timestamp = message['timestamp'] as Timestamp?;
    final formattedTime = formatTime(timestamp);
    final prescriptionData =
        message['prescription_data'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  recipientData != null && recipientData['avatar_url'] != null
                      ? CachedNetworkImageProvider(recipientData['avatar_url'])
                      : null,
              child:
                  recipientData == null || recipientData['avatar_url'] == null
                      ? Text(
                          recipientFullName.isNotEmpty
                              ? recipientFullName
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .join()
                                  .substring(0, 1)
                              : '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF58f0d7).withOpacity(0.9)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isMe
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isMe
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            color: isMe ? Colors.black87 : Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Prescription',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.black87 : Colors.blue,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var medicine in prescriptionData['medicines']) ...[
                        Text(
                          'Medicine: ${medicine['medicine_name']}',
                          style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dosage: ${medicine['dosage']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Duration: ${medicine['duration']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (medicine['instructions'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Instructions: ${medicine['instructions']}',
                          style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${prescriptionData['notes']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void showPrescriptionDialog({
    required BuildContext context,
    required String chatRoomId,
    required String senderId,
    required String recipientId,
  }) {
    showDialog(
      context: context,
      builder: (context) => PrescriptionForm(
        chatRoomId: chatRoomId,
        senderId: senderId,
        recipientId: recipientId,
      ),
    );
  }

  static Future<void> sendPrescriptionMessage({
    required String chatRoomId,
    required String senderId,
    required String recipientId,
    required Map<String, dynamic> prescriptionData,
  }) async {
    final db = FirebaseFirestore.instance;

    await db.collection('chats').doc(chatRoomId).collection('messages').add({
      'senderID': senderId,
      'recipientID': recipientId,
      'message_type': 'prescription',
      'message_body': 'Prescription',
      'prescription_data': prescriptionData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await db.collection('chats').doc(chatRoomId).update({
      'last_message': 'Prescription sent',
      'timestamp': FieldValue.serverTimestamp(),
      'last_message_senderID': senderId,
    });
  }
}
