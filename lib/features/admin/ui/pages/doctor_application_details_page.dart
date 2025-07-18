import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/features/admin/data/admin_service.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DoctorApplicationDetailsPage extends StatefulWidget {
  final String doctorId;
  const DoctorApplicationDetailsPage({super.key, required this.doctorId});

  @override
  State<DoctorApplicationDetailsPage> createState() =>
      _DoctorApplicationDetailsPageState();
}

class _DoctorApplicationDetailsPageState
    extends State<DoctorApplicationDetailsPage> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile');
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _adminService.updateDoctorVerificationStatus(widget.doctorId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application ${status}d successfully')),
      );
      context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $fileName to ${directory.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download $fileName: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Application Details',
       selectedIndex: 0,
      onItemTapped: (index) {
        // Handle navigation
        _onItemTapped(index);
      },
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.doctorId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Application not found."));
          }

          Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: (data['profile_pic'] != null && data['profile_pic'].isNotEmpty)
                        ? NetworkImage(data['profile_pic']) as ImageProvider<Object>?
                        : null,
                    child: (data['profile_pic'] == null || data['profile_pic'].isEmpty)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    data['full_name'] ?? 'No Name',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    data['email'] ?? 'No Email',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDetailItem('Specialization', data['specialization'] ?? 'N/A'),
                _buildDetailItem('License Number', data['license_number'] ?? 'N/A'),
                _buildDetailItem('Years of Experience', data['years_of_experience']?.toString() ?? 'N/A'),
                _buildDetailItem('Education', data['education']?.join(', ') ?? 'N/A'),
                _buildDetailItem('Hospital Affiliation', data['hospital_affiliation']?.join(', ') ?? 'N/A'),
                _buildDetailItem('Consultation Fee', data['consultation_fee']?.toString() ?? 'N/A'),
                const SizedBox(height: 24),
                _buildDocumentLink('License Document', data['license_file'] ?? ''),
                _buildDocumentLink('Education Document', data['education_file'] ?? ''),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('approved'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => _updateStatus('rejected'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildDocumentLink(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          InkWell(
            onTap: () async {
              if (url.isNotEmpty) {
                final fileName = url.split('/').last;
                await _downloadFile(url, fileName);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document not provided.')),
                );
              }
            },
            child: Text(
              url.isNotEmpty ? 'Download Document' : 'Not Provided',
              style: TextStyle(
                color: url.isNotEmpty ? Colors.blue : Colors.grey,
                decoration: url.isNotEmpty ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
