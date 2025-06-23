import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nursejoyapp/shared/utils/utils.dart';

/// Doctor list interface for Nurse Joy application
/// Implements modern UI patterns with performance optimizations
class DoctorList extends StatefulWidget {
  const DoctorList({super.key});

  @override
  State<DoctorList> createState() => _DoctorListState();
}

class _DoctorListState extends State<DoctorList> with AutomaticKeepAliveClientMixin {
  // Cache for doctor details to improve performance
  final Map<String, DocumentSnapshot> _doctorDetailsCache = {};
  final ScrollController _scrollController = ScrollController();
  
  // Filter state
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minFeeController = TextEditingController();
  final TextEditingController _maxFeeController = TextEditingController();
  String? _selectedSpecialization;
  List<String> _specializations = [];
  bool _isLoading = false;
  List<DocumentSnapshot> _filteredDoctors = [];
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await getVerifiedFilteredDoctorList();
      _filteredDoctors = doctors;

      setState(() {
        _specializations = getSpecializations();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading doctors: $e')),
        );
      }
    }
  }
  
  Future<void> _applyFilters() async {
    setState(() => _isLoading = true);
    try {
      final minFee = _minFeeController.text.isNotEmpty 
          ? int.tryParse(_minFeeController.text) 
          : null;
      final maxFee = _maxFeeController.text.isNotEmpty 
          ? int.tryParse(_maxFeeController.text) 
          : null;

      if (minFee != null && maxFee != null && minFee > maxFee) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Minimum fee cannot be greater than maximum fee')),
        );
        return;
      }

      if (minFee != null && minFee < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Minimum fee cannot be negative')),
        );
        return;
      }

      if (maxFee != null && maxFee < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum fee cannot be negative')),
        );
        return;
      }
      
      final doctors = await getVerifiedFilteredDoctorList(
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        specialization: _selectedSpecialization,
        minFee: minFee,
        maxFee: maxFee,
      );
      
      setState(() {
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying filters: $e')),
        );
      }
    }
  }


  
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minFeeController.clear();
      _maxFeeController.clear();
      _selectedSpecialization = null;
    });
    _loadInitialData();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _minFeeController.dispose();
    _maxFeeController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> _getDoctorDetails(String doctorId) async {
    if (_doctorDetailsCache.containsKey(doctorId)) {
      return _doctorDetailsCache[doctorId]!;
    }
    
    try {
      final details = await getDoctorDetails(doctorId);
      _doctorDetailsCache[doctorId] = details;
      return details;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AppScaffold(
      title: 'Find a Doctor',
      selectedIndex: 0,
      onItemTapped: (index) {},
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(),
          // Doctor List
          Expanded(child: _buildDoctorList()),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndFilters() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search doctors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onSubmitted: (_) => _applyFilters(),
            ),
            const SizedBox(height: 12),
            
            // Specialization Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: InputDecoration(
                labelText: 'Specialization',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              hint: const Text('Select specialization'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Specializations'),
                ),
                ..._specializations.map((spec) => DropdownMenuItem(
                      value: spec,
                      child: Text(spec),
                    )),
              ],
              onChanged: (value) {
                _selectedSpecialization = value;
                
              },
            ),
            const SizedBox(height: 12),
            
            // Price Range
            const Text('Consultation Fee Range', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minFeeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min (₱)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxFeeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max (₱)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Apply Filters'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    if (_isLoading && _filteredDoctors.isEmpty) {
      return _buildLoadingState();
    }
    
    if (_filteredDoctors.isEmpty) {
      return _buildEmptyState();
    }
    
    final doctors = _filteredDoctors;

    return AnimationLimiter(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (BuildContext context, int index) {
          final doctor = doctors[index];
          
          return FutureBuilder<DocumentSnapshot>(
            future: getDoctorDetails(doctor.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // use shimmer
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Loading...'),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.error),
                      title: Text('Error loading doctor details'),
                    ),
                  ),
                );
              }
              
              final doctorDetails = snapshot.data!;
              
              Widget animatedCard = SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: _buildDoctorCard(doctorDetails, index, doctor),
                ),
              );
              
              return AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: animatedCard,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(DocumentSnapshot? doctor, int index, DocumentSnapshot? userDetails) {
    if (doctor == null) {
      return _buildErrorState('Doctor details not found');
    }

    if (userDetails == null) {
      return _buildErrorState('User details not found');
    }
    
    final name = '${userDetails['first_name']} ${userDetails['last_name']}';
    final isOnline = userDetails['status_online'] ?? false;
    final imageUrl = userDetails['profile_pic'] ?? '';
    
    return Builder(
      builder: (BuildContext context) {
    
        
        final doctorInfo = doctor.data() as Map<String, dynamic>? ?? {};
        final specialty = doctorInfo['specialization'] ?? 'General Practitioner';
        final rating = (doctorInfo['rating'] ?? 0.0).toDouble();
        final reviewCount = doctorInfo['num_of_ratings'] ?? 0;
        final bio = doctorInfo['bio'] ?? '';
        final consultationFee = doctorInfo['consultation_fee'] ?? 0;
        final currency = doctorInfo['consultation_currency'] ?? 'PHP';
        final experience = doctorInfo['years_of_experience'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.lightImpact();
                // navigate to doctor page with doctorDetails and userDetails
                context.go('/doctor/${userDetails.id}', extra: {
                  'userDetails': userDetails,
                  'doctorDetails': doctor,
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Doctor Avatar with online indicator
                        Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => 
                                            const Icon(Icons.person, size: 40),
                                      )
                                    : const Icon(Icons.person, size: 40),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
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
                                      'Dr. $name',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isOnline 
                                          ? Colors.green.shade50 
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isOnline 
                                            ? Colors.green.shade300 
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      isOnline ? 'Available' : 'Offline',
                                      style: TextStyle(
                                        color: isOnline 
                                            ? Colors.green.shade700 
                                            : Colors.grey.shade600,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 6),
                              
                              Text(
                                specialty,
                                style: const TextStyle(
                                  color: Color(0xFF58f0d7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              
                              if (experience > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '$experience years experience',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                              
                              if (bio.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  bio,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rating and fee row
                    Row(
                      children: [
                        // Rating
                        Row(
                          children: [
                            RatingBarIndicator(
                              rating: rating,
                              itemBuilder: (context, _) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                              ),
                              itemCount: 5,
                              itemSize: 16,
                              unratedColor: Colors.amber.shade100,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${rating.toStringAsFixed(1)} (${reviewCount.toString()})',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const Spacer(),
                        
                        // Consultation fee
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$consultationFee $currency',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDoctorCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCardError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Unable to load doctor details',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildDoctorCardSkeleton(),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58f0d7),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services_rounded,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'No doctors available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
