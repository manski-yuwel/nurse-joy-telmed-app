import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/chat/data/chat_list_db.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:nursejoyapp/features/doctor/data/doctor_list_data.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentList extends StatefulWidget {
  const AppointmentList({super.key});

  @override
  State<AppointmentList> createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList>
    with TickerProviderStateMixin {
  late AuthService auth;
  late TabController _tabController;
  late TabController _viewTabController;
  late AnimationController _fadeController;
  late AnimationController _refreshController;
  late Animation<double> _fadeAnimation;

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<QueryDocumentSnapshot>> _appointmentsByDate = {};
  List<QueryDocumentSnapshot> _allAppointments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedDay = DateTime.now();
    // Start fade animation
    _fadeController.forward();
  }

  void _initializeControllers() {
    _tabController = TabController(length: 4, vsync: this);
    _viewTabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context, listen: false);
    if (auth.user != null) {
      _loadAppointments();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewTabController.dispose();
    _fadeController.dispose();
    _refreshController.dispose();
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadAppointments() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Loading appointments for user: ${auth.user?.uid}');
      final appointmentSnapshot = await getAppointmentList(auth.user!.uid);
      final appointments = appointmentSnapshot.docs;

      debugPrint('Found ${appointments.length} appointments');
      
      if (appointments.isEmpty) {
        debugPrint('No appointments found');
        setState(() {
          _appointmentsByDate = {};
          _allAppointments = [];
          _isLoading = false;
        });
        return;
      }

      Map<DateTime, List<QueryDocumentSnapshot>> appointmentMap = {};

      for (var appointment in appointments) {
        try {
          final appointmentData = appointment.data() as Map<String, dynamic>;
          
          if (appointmentData['appointmentDateTime'] == null) {
            debugPrint('Appointment ${appointment.id} is missing appointmentDateTime');
            continue;
          }
          
          final appointmentDate = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
          final dateKey = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);

          appointmentMap.putIfAbsent(dateKey, () => []).add(appointment);
          
          debugPrint('Added appointment for ${dateKey.toString()}: ${appointment.id}');
        } catch (e) {
          debugPrint('Error processing appointment ${appointment.id}: $e');
        }
      }

      if (mounted) {
        setState(() {
          _appointmentsByDate = appointmentMap;
          _allAppointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message to user
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to load appointments. Please try again.'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _loadAppointments,
              ),
            ),
          );
        }
      }
    }
  }

  void _handleNavigation(int index) {
    HapticFeedback.lightImpact();
    switch (index) {
      case 0:
        context.go('/chat');
        break;
      case 1:
        context.go('/home');
        break;
      case 2:
        context.go('/profile/${auth.user!.uid}');
        break;
      default:
        break;
    }
  }

  void _refreshAppointments() {
    HapticFeedback.mediumImpact();
    _refreshController.forward().then((_) {
      _refreshController.reset();
      _loadAppointments();
    });
  }

  List<QueryDocumentSnapshot> _getAppointmentsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _appointmentsByDate[dateKey] ?? [];
  }

  List<QueryDocumentSnapshot> _getFilteredAppointments(int filterIndex) {
    if (_allAppointments.isEmpty) return [];

    final now = DateTime.now();
    List<QueryDocumentSnapshot> filtered;

    switch (filterIndex) {
      case 0: // All
        filtered = List.from(_allAppointments);
        break;
      case 1: // Today
        filtered = _allAppointments.where((appointment) {
          try {
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final appointmentDate = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
            return isSameDay(appointmentDate, now);
          } catch (e) {
            debugPrint('Error processing appointment: $e');
            return false;
          }
        }).toList();
        break;
      case 2: // Upcoming
        filtered = _allAppointments.where((appointment) {
          try {
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final appointmentDate = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
            return appointmentDate.isAfter(now) && appointmentData['status'] == 'scheduled';
          } catch (e) {
            debugPrint('Error processing appointment: $e');
            return false;
          }
        }).toList();
        break;
      case 3: // Completed
        filtered = _allAppointments.where((appointment) {
          try {
            final appointmentData = appointment.data() as Map<String, dynamic>;
            return appointmentData['status'] == 'completed';
          } catch (e) {
            debugPrint('Error processing appointment: $e');
            return false;
          }
        }).toList();
        break;
      default:
        filtered = List.from(_allAppointments);
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((appointment) {
        try {
          final appointmentData = appointment.data() as Map<String, dynamic>;
          final patientName = '${appointmentData['patientFirstName'] ?? ''} ${appointmentData['patientLastName'] ?? ''}'.toLowerCase();
          final reason = (appointmentData['reason'] ?? '').toString().toLowerCase();
          final status = (appointmentData['status'] ?? '').toString().toLowerCase();

          return patientName.contains(_searchQuery) ||
                 reason.contains(_searchQuery) ||
                 status.contains(_searchQuery) ||
                 appointment.id.toLowerCase().contains(_searchQuery);
        } catch (e) {
          debugPrint('Error searching appointment: $e');
          return false;
        }
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Patient Appointments',
      selectedIndex: 1,
      onItemTapped: _handleNavigation,
      actions: [
        AnimatedBuilder(
          animation: _refreshController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _refreshController.value * 2 * 3.14159,
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _refreshAppointments,
                tooltip: 'Refresh Appointments',
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: _showSearchDialog,
          tooltip: 'Search Appointments',
        ),
      ],
      body: _isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildViewTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _viewTabController,
                      children: [
                        _buildListView(),
                        _buildCalendarView(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58f0d7)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabs() {
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
        controller: _viewTabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.list_rounded),
            text: 'List View',
          ),
          Tab(
            icon: Icon(Icons.calendar_month_rounded),
            text: 'Calendar',
          ),
        ],
        labelColor: const Color(0xFF58f0d7),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF58f0d7),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildFilterTabs(),
        _buildStatsCard(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAppointmentList(0),
              _buildAppointmentList(1),
              _buildAppointmentList(2),
              _buildAppointmentList(3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Today'),
          Tab(text: 'Scheduled'),
          Tab(text: 'Completed'),
        ],
        labelColor: const Color(0xFF58f0d7),
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: const Color(0xFF58f0d7),
        indicatorWeight: 2,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
    );
  }

  Widget _buildStatsCard() {
    final todayAppointments = _getFilteredAppointments(1).length;
    final upcomingAppointments = _getFilteredAppointments(2).length;
    final completedAppointments = _getFilteredAppointments(3).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58f0d7), Color(0xFF4dd0e1)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58f0d7).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Today',
              todayAppointments.toString(),
              Icons.today_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Scheduled',
              upcomingAppointments.toString(),
              Icons.schedule_rounded,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildStatItem(
              'Completed',
              completedAppointments.toString(),
              Icons.check_circle_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentList(int filterIndex) {
    final filteredAppointments = _getFilteredAppointments(filterIndex);

    if (filteredAppointments.isEmpty) {
      return _buildEmptyState(filterIndex);
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAppointments.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildAppointmentCard(filteredAppointments[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(int filterIndex) {
    String title;
    String subtitle;
    IconData icon;

    switch (filterIndex) {
      case 1:
        title = 'No Appointments Today';
        subtitle = 'You don\'t have any appointments scheduled for today';
        icon = Icons.today_rounded;
        break;
      case 2:
        title = 'No Scheduled Appointments';
        subtitle = 'All caught up! No scheduled appointments scheduled';
        icon = Icons.schedule_rounded;
        break;
      case 3:
        title = 'No Completed Appointments';
        subtitle = 'Completed appointments will appear here';
        icon = Icons.check_circle_rounded;
        break;
      default:
        title = 'No Appointments';
        subtitle = 'Patient appointments will appear here';
        icon = Icons.event_note_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot appointment) {
    return FutureBuilder<DocumentSnapshot>(
      future: getUserDetails(appointment['userID']),
      builder: (context, patientDetails) {
        if (patientDetails.connectionState == ConnectionState.waiting) {
          return _buildSkeletonCard();
        } else if (patientDetails.hasError) {
          return _buildErrorCard();
        } else if (patientDetails.hasData && patientDetails.data != null) {
          final patientData = patientDetails.data!.data() as Map<String, dynamic>;
          final appointmentData = appointment.data() as Map<String, dynamic>;
          return _buildAppointmentCardContent(appointment, patientData, appointmentData);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildAppointmentCardContent(
    QueryDocumentSnapshot appointment,
    Map<String, dynamic> patientData,
    Map<String, dynamic> appointmentData,
  ) {
    final patientName = '${patientData['first_name']} ${patientData['last_name']}';
    final appointmentDateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
    final status = appointmentData['status'] ?? 'scheduled';
    final imageUrl = patientData['profile_pic'] ?? '';
    final isToday = isSameDay(appointmentDateTime, DateTime.now());
    final isUpcoming = appointmentDateTime.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: const Color(0xFF58f0d7), width: 2)
            : null,
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
            context.go('/appointment-detail/${appointment.id}', extra: {
              'patientData': patientData,
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildPatientAvatar(imageUrl),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  patientName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF58f0d7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'TODAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (patientData['email'] != null)
                            Text(
                              patientData['email'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF58f0d7).withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: isToday
                            ? const Color(0xFF58f0d7)
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, y').format(appointmentDateTime),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isToday
                                    ? const Color(0xFF58f0d7)
                                    : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('h:mm a').format(appointmentDateTime),
                              style: TextStyle(
                                fontSize: 14,
                                color: isToday
                                    ? const Color(0xFF58f0d7)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isUpcoming && status == 'scheduled')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getTimeUntilAppointment(appointmentDateTime),
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final chatRoomID = Chat().generateChatRoomID(
                            auth.user!.uid,
                            appointment['userID'],
                          );
                          context.go('/chat/$chatRoomID', extra: {
                            'recipientID': appointment['userID'],
                            'recipientFullName': patientName,
                          });
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Chat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF58f0d7),
                          side: const BorderSide(color: Color(0xFF58f0d7)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/profile/${appointment['userID']}');
                        },
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
  }

  Widget _buildPatientAvatar(String imageUrl) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade100,
                  child: Icon(Icons.person, color: Colors.grey.shade400),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade100,
                  child: Icon(Icons.person, color: Colors.grey.shade400),
                ),
              )
            : Container(
                color: Colors.grey.shade100,
                child: Icon(Icons.person, color: Colors.grey.shade400),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'scheduled':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade700;
        displayText = 'Scheduled';
        icon = Icons.schedule_rounded;
        break;
      case 'in-progress':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        displayText = 'In Progress';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'completed':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        displayText = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        displayText = 'Cancelled';
        icon = Icons.cancel_rounded;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        displayText = 'Pending';
        icon = Icons.pending_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeUntilAppointment(DateTime appointmentTime) {
    final now = DateTime.now();
    final difference = appointmentTime.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
              'Failed to load patient details',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        Container(
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
          child: TableCalendar<QueryDocumentSnapshot>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getAppointmentsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.black87),
              holidayTextStyle: const TextStyle(color: Colors.black87),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF58f0d7),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: const Color(0xFF58f0d7).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFF58f0d7),
                borderRadius: BorderRadius.all(Radius.circular(12.0)),
              ),
              formatButtonTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildSelectedDayAppointments(),
        ),
      ],
    );
  }

  Widget _buildSelectedDayAppointments() {
    final selectedDayAppointments = _getAppointmentsForDay(_selectedDay!);

    if (selectedDayAppointments.isEmpty) {
      return SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No appointments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'No appointments scheduled for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: selectedDayAppointments.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildAppointmentCard(selectedDayAppointments[index]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSearchDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Appointments'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by patient name...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
