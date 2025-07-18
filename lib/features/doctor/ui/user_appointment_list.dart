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

class UserAppointmentList extends StatefulWidget {
  const UserAppointmentList({super.key});

  @override
  State<UserAppointmentList> createState() => _UserAppointmentListState();
}

class _UserAppointmentListState extends State<UserAppointmentList> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AuthService auth;
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _calendarController;
  late Animation<double> _fadeAnimation;

  double _responsiveSize(double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Base screen width for scaling (e.g., iPhone 8 width)
    const double baseWidth = 375.0;
    return size * (screenWidth / baseWidth);
  }
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<QueryDocumentSnapshot> _allAppointments = [];
  Map<DateTime, List<QueryDocumentSnapshot>> _appointmentsByDate = {};
  bool _isLoading = false;
  bool _isCalendarExpanded = true;
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0;
  final double _calendarHeight = 400; // Fixed height for the calendar

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _selectedDay = DateTime.now();
    _scrollController.addListener(_handleScroll);
  }

  void _initializeControllers() {
    _tabController = TabController(length: 2, vsync: this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _calendarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    _calendarController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > _lastScrollPosition + 20 && _isCalendarExpanded) {
      // Scrolling down and calendar is expanded
      setState(() {
        _isCalendarExpanded = false;
      });
      _calendarController.reverse();
    } else if (currentScroll < _lastScrollPosition - 20 && !_isCalendarExpanded) {
      // Scrolling up and calendar is collapsed
      if (currentScroll <= 0) {
        setState(() {
          _isCalendarExpanded = true;
        });
        _calendarController.forward();
      }
    }
    _lastScrollPosition = currentScroll;
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarExpanded = !_isCalendarExpanded;
    });
    if (_isCalendarExpanded) {
      _calendarController.forward();
      // Scroll to top when expanding calendar
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _calendarController.reverse();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    auth = Provider.of<AuthService>(context, listen: false);
  }

  void _handleNavigation(int index) {
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

  void _organizeAppointmentsByDate(List<QueryDocumentSnapshot> appointments) {
    _appointmentsByDate.clear();
    
    for (var appointment in appointments) {
      final appointmentData = appointment.data() as Map<String, dynamic>;
      final dateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
      final dateKey = DateTime(dateTime.year, dateTime.month, dateTime.day);
      
      if (_appointmentsByDate[dateKey] == null) {
        _appointmentsByDate[dateKey] = [];
      }
      _appointmentsByDate[dateKey]!.add(appointment);
    }
  }

  List<QueryDocumentSnapshot> _getAppointmentsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _appointmentsByDate[dateKey] ?? [];
  }

  List<QueryDocumentSnapshot> _getFilteredAppointments(String filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case 'upcoming':
        return _allAppointments.where((appointment) {
          final appointmentData = appointment.data() as Map<String, dynamic>;
          final dateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
          return dateTime.isAfter(now) && appointmentData['status'] == 'scheduled';
        }).toList();
      case 'past':
        return _allAppointments.where((appointment) {
          final appointmentData = appointment.data() as Map<String, dynamic>;
          final dateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
          return dateTime.isBefore(now) || appointmentData['status'] == 'completed';
        }).toList();
      case 'cancelled':
        return _allAppointments.where((appointment) {
          final appointmentData = appointment.data() as Map<String, dynamic>;
          return appointmentData['status'] == 'cancelled';
        }).toList();
      default:
        return _allAppointments;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AppScaffold(
      title: 'My Appointments',
      selectedIndex: 1,
      onItemTapped: _handleNavigation,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildListView(),
                    _buildCalendarView(),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const TabBar(
        labelColor: Color(0xFF58f0d7),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF58f0d7),
        indicatorWeight: 3,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: [
          Tab(
            icon: Icon(Icons.list_rounded),
            text: 'List View',
          ),
          Tab(
            icon: Icon(Icons.calendar_month_rounded),
            text: 'Calendar',
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return FutureBuilder<QuerySnapshot>(
      future: getUserAppointmentList(auth.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          _allAppointments = snapshot.data!.docs;
          return _buildAppointmentsList();
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildCalendarView() {
    return FutureBuilder<QuerySnapshot>(
      future: getUserAppointmentList(auth.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        } else if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        } else if (snapshot.hasData) {
          _allAppointments = snapshot.data!.docs;
          _organizeAppointmentsByDate(_allAppointments);
          return _buildCalendarContent();
        } else {
          return _buildEmptyState();
        }
      },
    );
  }

  Widget _buildCollapsibleCalendar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isCalendarExpanded ? _calendarHeight : 100,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildCalendarHeader(),
                _buildTableCalendar(),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _toggleCalendar,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isCalendarExpanded 
                        ? Icons.keyboard_arrow_up_rounded 
                        : Icons.keyboard_arrow_down_rounded,
                    size: 24,
                    color: const Color(0xFF58f0d7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFF58f0d7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF58f0d7),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF58f0d7).withOpacity(0.1),
            ),
            child: const Text('Today'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TableCalendar<QueryDocumentSnapshot>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getAppointmentsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF58f0d7),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: const Color(0xFF58f0d7).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          weekendTextStyle: TextStyle(color: Colors.red.shade400),
        ),
        headerVisible: false,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              isScrollable: true,
              labelColor: Color(0xFF58f0d7),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF58f0d7),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFilteredAppointmentsList('all'),
                _buildFilteredAppointmentsList('upcoming'),
                _buildFilteredAppointmentsList('past'),
                _buildFilteredAppointmentsList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredAppointmentsList(String filter) {
    final filteredAppointments = _getFilteredAppointments(filter);
    
    if (filteredAppointments.isEmpty) {
      return _buildEmptyFilterState(filter);
    }

    return Expanded(
      child: AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filteredAppointments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AnimationConfiguration.staggeredList(
                position: index,
                duration: const Duration(milliseconds: 375),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
                    child: _buildAppointmentCard(filteredAppointments[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Column(
      children: [
        _buildCollapsibleCalendar(),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (scrollNotification) {
              if (scrollNotification is ScrollEndNotification) {
                if (scrollNotification.metrics.pixels == 0 && !_isCalendarExpanded) {
                  _toggleCalendar();
                }
              }
              return true;
            },
            child: _buildSelectedDayAppointments(),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDayAppointments() {
    if (_selectedDay == null) return const SizedBox();
    
    final dayAppointments = _getAppointmentsForDay(_selectedDay!);
    
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: const Color(0xFF58f0d7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appointments for ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (dayAppointments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments scheduled',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildAppointmentCard(dayAppointments[index]),
                  );
                },
                childCount: dayAppointments.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot appointment) {
    return FutureBuilder<DocumentSnapshot>(
      future: getUserDetails(appointment['doctorID']),
      builder: (context, doctorProfile) {
        if (doctorProfile.connectionState == ConnectionState.waiting) {
          return _buildAppointmentCardSkeleton();
        } else if (doctorProfile.hasError) {
          return _buildAppointmentCardError();
        } else if (doctorProfile.hasData && doctorProfile.data != null) {
          final doctorData = doctorProfile.data!.data() as Map<String, dynamic>;
          final appointmentData = appointment.data() as Map<String, dynamic>;
          return _buildAppointmentCardContent(appointment, doctorData, appointmentData);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildAppointmentCardContent(
    QueryDocumentSnapshot appointment,
    Map<String, dynamic> doctorData,
    Map<String, dynamic> appointmentData,
  ) {
    final doctorName = '${doctorData['first_name']} ${doctorData['last_name']}';
    final appointmentDateTime = (appointmentData['appointmentDateTime'] as Timestamp).toDate();
    final status = appointmentData['status'] ?? 'scheduled';
    final imageUrl = doctorData['profile_pic'] ?? '';
    final specialization = doctorData['specialization'] ?? 'General Practitioner';

    return Container(
      margin: EdgeInsets.only(bottom: _responsiveSize(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_responsiveSize(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: _responsiveSize(10),
            offset: Offset(0, _responsiveSize(4)),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_responsiveSize(16)),
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '/user-appointment-detail/${appointment.id}',
              extra: {'doctorData': doctorData},
            );
          },
          child: Padding(
            padding: EdgeInsets.all(_responsiveSize(16)),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDoctorAvatar(imageUrl),
                    SizedBox(width: _responsiveSize(16)),
                    Expanded(
                      child: _buildAppointmentInfo(
                        doctorName,
                        specialization,
                        appointmentDateTime,
                        status,
                      ),
                    ),

                  ],
                ),
                SizedBox(height: _responsiveSize(16)),
                _buildActionButtons(appointment, doctorData, doctorName),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorAvatar(String imageUrl) {
    return Container(
      width: _responsiveSize(60),
      height: _responsiveSize(60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_responsiveSize(12)),
        color: Colors.grey.shade200,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_responsiveSize(12)),
        child: imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  child: Icon(Icons.person, size: _responsiveSize(30)),
                ),
                errorWidget: (context, url, error) => 
                    Icon(Icons.person, size: _responsiveSize(30)),
              )
            : Icon(Icons.person, size: _responsiveSize(30)),
      ),
    );
  }

  Widget _buildAppointmentInfo(
    String doctorName,
    String specialization,
    DateTime appointmentDateTime,
    String status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dr. $doctorName',
          style: TextStyle(
            fontSize: _responsiveSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: _responsiveSize(4)),
        Text(
          specialization,
          style: TextStyle(
            color: Color(0xFF58f0d7),
            fontSize: _responsiveSize(14),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: _responsiveSize(8)),
        Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: _responsiveSize(14),
              color: Colors.grey.shade600,
            ),
            SizedBox(width: _responsiveSize(4)),
            Text(
              DateFormat('MMM d, y').format(appointmentDateTime),
              style: TextStyle(
                fontSize: _responsiveSize(13),
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(width: _responsiveSize(12)),
            Icon(
              Icons.access_time_rounded,
              size: _responsiveSize(14),
              color: Colors.grey.shade600,
            ),
            SizedBox(width: _responsiveSize(4)),
            Text(
              DateFormat('h:mm a').format(appointmentDateTime),
              style: TextStyle(
                fontSize: _responsiveSize(13),
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'scheduled':
        statusColor = Colors.green;
        statusText = 'Scheduled';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: _responsiveSize(12), vertical: _responsiveSize(6)),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(_responsiveSize(20)),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: _responsiveSize(12),
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildActionButtons(
    QueryDocumentSnapshot appointment,
    Map<String, dynamic> doctorData,
    String doctorName,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              final chatInstance = Chat();
              final chatRoomID = chatInstance.generateChatRoomID(
                auth.user!.uid,
                appointment['doctorID'],
              );
              context.go('/chat/$chatRoomID', extra: {
                'recipientID': appointment['doctorID'],
                'recipientFullName': doctorName,
              });
            },
            icon: Icon(Icons.chat_rounded, size: _responsiveSize(18)),
            label: Text('Chat', style: TextStyle(fontSize: _responsiveSize(14))),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF58f0d7),
              side: const BorderSide(color: Color(0xFF58f0d7)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_responsiveSize(12)),
              ),
              padding: EdgeInsets.symmetric(vertical: _responsiveSize(8)),
            ),
          ),
        ),
        SizedBox(width: _responsiveSize(12)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final doctorDetails = await getDoctorDetails(appointment['doctorID']);
              if (!context.mounted) return;
              context.go('/doctor/${appointment['doctorID']}', extra: {
                'doctorDetails': doctorDetails,
                'userDetails': doctorData,
              });
            },
            icon: Icon(Icons.person_rounded, size: _responsiveSize(18)),
            label: Text('Profile', style: TextStyle(fontSize: _responsiveSize(14))),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58f0d7),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_responsiveSize(12)),
              ),
              padding: EdgeInsets.symmetric(vertical: _responsiveSize(8)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentCardSkeleton() {
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
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
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCardError() {
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
            child: Text('Unable to load appointment details'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58f0d7)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading appointments...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
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
              'Unable to load appointments',
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
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58f0d7),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF58f0d7).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 60,
                color: const Color(0xFF58f0d7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Appointments Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You haven\'t scheduled any appointments yet. Book your first appointment with a doctor.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/doctor-list', extra: {
                'searchQuery': '',
                'specialization': 'All Specializations',
                'minFee': null,
                'maxFee': null,
              }),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58f0d7),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildEmptyFilterState(String filter) {
    String title;
    String description;
    IconData icon;

    switch (filter) {
      case 'upcoming':
        title = 'No Upcoming Appointments';
        description = 'You don\'t have any scheduled appointments coming up.';
        icon = Icons.schedule_rounded;
        break;
      case 'past':
        title = 'No Past Appointments';
        description = 'You don\'t have any completed appointments yet.';
        icon = Icons.history_rounded;
        break;
      case 'cancelled':
        title = 'No Cancelled Appointments';
        description = 'You haven\'t cancelled any appointments.';
        icon = Icons.cancel_rounded;
        break;
      default:
        title = 'No Appointments';
        description = 'No appointments found in this category.';
        icon = Icons.event_busy_rounded;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
