import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';

// Doctor list interface for Nurse Joy application
// Implements modern UI patterns with performance optimizations

/// Doctor list interface for Nurse Joy application
/// Implements modern UI patterns with performance optimizations
class DoctorList extends StatefulWidget {
  const DoctorList({super.key});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Find a Doctor',
      selectedIndex: 0,
      onItemTapped: (index) {
        // Handle bottom navigation item tap if needed
      },
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: _buildDoctorList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorList() {
    return FutureBuilder<QuerySnapshot>(
      future: getDoctorList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final doctors = snapshot.data?.docs ?? [];
        
        // Filter doctors based on search query
        final filteredDoctors = doctors.where((doctor) {
          final name = '${doctor['first_name']} ${doctor['last_name']}'.toLowerCase();
          return name.contains(_searchQuery);
        }).toList();

        if (filteredDoctors.isEmpty) {
          return const Center(
            child: Text('No doctors found'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredDoctors.length,
          itemBuilder: (context, index) {
            final doctor = filteredDoctors[index];
            final name = '${doctor['first_name']} ${doctor['last_name']}';
            final isOnline = doctor['status_online'] ?? false;
            final imageUrl = doctor['profile_pic'] ?? '';
            
            return FutureBuilder<DocumentSnapshot>(
              future: getDoctorDetails(doctor.id),
              builder: (context, docSnapshot) {
                if (docSnapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    ),
                  );
                }
                
                if (!docSnapshot.hasData || !docSnapshot.data!.exists) {
                  return const Card(
                    child: ListTile(
                      leading: Icon(Icons.error),
                      title: Text('Doctor details not available'),
                    ),
                  );
                }
                
                final doctorInfo = docSnapshot.data!.data() as Map<String, dynamic>? ?? {};
                final specialty = doctorInfo['specialization'] ?? 'General Practitioner';
                final rating = (doctorInfo['rating'] ?? 0.0).toDouble();
                final reviewCount = doctorInfo['num_of_ratings'] ?? 0;
                final bio = doctorInfo['bio'] ?? '';
                final consultationFee = doctorInfo['consultation_fee'] ?? 0;
                final currency = doctorInfo['consultation_currency'] ?? 'PHP';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Navigate to doctor details
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (context) => DoctorDetailsScreen(doctorId: doctor.id),
                      // ));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Doctor Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isOnline ? Colors.green[50] : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isOnline ? Colors.green : Colors.grey,
                                        ),
                                      ),
                                      child: Text(
                                        isOnline ? 'Online' : 'Offline',
                                        style: TextStyle(
                                          color: isOnline ? Colors.green : Colors.grey[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  specialty,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (bio.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    bio,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: rating,
                                      itemBuilder: (context, _) => const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                      ),
                                      itemCount: 5,
                                      itemSize: 16,
                                      unratedColor: Colors.amber[100],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${rating.toStringAsFixed(1)} (${reviewCount.toStringAsFixed(0)})',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '$consultationFee $currency',
                                      style: const TextStyle(
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}