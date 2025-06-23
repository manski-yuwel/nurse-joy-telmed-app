import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:nursejoyapp/features/doctor/ui/widgets/date_time_picker.dart';
class DoctorPage extends StatefulWidget {
  const DoctorPage(
      {super.key,
      required this.doctorId,
      required this.doctorDetails});

  final String doctorId;
  final DocumentSnapshot doctorDetails;

  @override
  State<DoctorPage> createState() => _DoctorPageState();
}

class _DoctorPageState extends State<DoctorPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  bool _isLoading = false;
  late AuthService auth;
  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _bookAppointment() async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AppointmentBookingDialog(
      doctorId: widget.doctorId,
      onBookingComplete: (AppointmentBooking booking) async {
        context.pop();
        setState(() => _isLoading = true);
        
        try {
          await registerEnhancedAppointment(
            widget.doctorId,
            auth.user!.uid, // Your actual user ID
            booking,
          );
          
          if (!context.mounted) return;
          
          // Success dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Appointment Booked'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your appointment has been scheduled!'),
                  const SizedBox(height: 8),
                  Text('Date: ${booking.selectedDay.displayDate}'),
                  Text('Time: ${booking.selectedTimeSlot.displayTime}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } catch (e) {
          // Error handling
          if (!context.mounted) return;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to book appointment: $e'),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      },
    ),
  );
}

  List<Widget> _buildSection(String title, List<String> items) {
    return [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      ...items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(item)),
                  ],
                ),
              ))
          .toList(),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHours() {
    final workingHours = {
      'Monday - Friday': '8:00 AM - 5:00 PM',
      'Saturday': '9:00 AM - 2:00 PM',
      'Sunday': 'Closed',
    };

    return Column(
      children: workingHours.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                entry.key,
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                entry.value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doctorData =
        widget.doctorDetails.data() as Map<String, dynamic>? ?? {};
    final name = '${doctorData['first_name']} ${doctorData['last_name']}';
    final specialty = doctorData['specialization'] ?? 'General Practitioner';
    final rating = (doctorData['rating'] ?? 0.0).toDouble();
    final reviewCount = doctorData['num_of_ratings'] ?? 0;
    final consultationFee = doctorData['consultation_fee'] ?? 0;
    final currency = doctorData['consultation_currency'] ?? 'PHP';
    final bio = doctorData['bio'] ?? '';
    final experience = doctorData['years_of_experience'] ?? 0;
    final languages =
        (doctorData['languages'] as List<dynamic>?)?.cast<String>() ?? [];
    final education =
        (doctorData['education'] as List<dynamic>?)?.cast<String>() ?? [];
    final services =
        (doctorData['services_offered'] as List<dynamic>?)?.cast<String>() ??
            [];

    final isOnline = doctorData['status_online'] ?? false;
    final imageUrl = doctorData['profile_pic'] ?? '';

    return AppScaffold(
      title: 'Doctor Details',
      selectedIndex: 0,
      onItemTapped: _onItemTapped,
      body: Column(
        children: [
          // Doctor Header Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : null,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFavorite = !_isFavorite;
                              });
                            },
                          ),
                        ],
                      ),
                      Text(
                        specialty,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($reviewCount reviews)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? Colors.green[50]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                            child: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color:
                                    isOnline ? Colors.green : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$consultationFee $currency',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.calendar_today, size: 20),
                    label: Text(_isLoading ? 'Booking...' : 'Book Appointment'),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).primaryColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () {
                      final chat = Chat();
                      final chatRoomID = chat.generateChatRoomID(auth.user!.uid, widget.doctorId);
                      chat.generateChatRoom(chatRoomID, auth.user!.uid, widget.doctorId);
                      context.push('/chat/$chatRoomID', extra: {
                        'recipientID': widget.doctorId,
                        'recipientFullName': '${widget.doctorDetails['first_name']} ${widget.doctorDetails['last_name']}',
                      });
                    },
                    icon: const Icon(Icons.chat, color: Colors.blue),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                horizontal: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Reviews'),
                Tab(text: 'Contact'),
              ],
            ),
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // About Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (bio.isNotEmpty) ..._buildSection('Biography', [bio]),
                      if (experience > 0)
                        ..._buildSection(
                            'Experience', ['$experience years of experience']),
                      if (languages.isNotEmpty)
                        ..._buildSection('Languages', languages),
                      if (education.isNotEmpty)
                        ..._buildSection('Education', education),
                      if (services.isNotEmpty)
                        ..._buildSection('Services', services),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                // Reviews Tab
                const Center(child: Text('No reviews yet')),
                // Contact Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContactItem(
                          Icons.email, 'Email', '${doctorData['email']}'),
                      const SizedBox(height: 12),
                      _buildContactItem(Icons.phone, 'Phone',
                          doctorData['phone_number'] ?? 'Not provided'),
                      const SizedBox(height: 12),
                      _buildContactItem(Icons.location_on, 'Location',
                          'Hospital or Clinic Address'),
                      const SizedBox(height: 16),
                      const Text(
                        'Clinic Hours',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      _buildWorkingHours(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile');
    }
  }
}