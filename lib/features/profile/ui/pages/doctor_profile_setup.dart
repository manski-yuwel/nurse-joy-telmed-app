import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/profile/ui/widgets/schedule_picker.dart';

class DoctorProfileSetup extends StatefulWidget {
  const DoctorProfileSetup({super.key});

  @override
  State<DoctorProfileSetup> createState() => _DoctorProfileSetupState();
}

class _DoctorProfileSetupState extends State<DoctorProfileSetup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form field names
  static const String bioField = 'bio';
  static const String workingHistoryField = 'working_history';
  static const String availabilityScheduleField = 'availability_schedule';
  static const String languagesField = 'languages';
  static const String servicesOfferedField = 'services_offered';

  final List<String> _languageOptions = [
    'English',
    'Filipino',
    'Spanish',
    'Chinese',
    'Japanese',
    'Korean',
    'French',
    'German',
    'Arabic',
    'Other'
  ];

  final List<String> _servicesOptions = [
    'General Consultation',
    'Specialist Consultation',
    'Follow-up Consultation',
    'Medical Certificate',
    'Prescription Renewal',
    'Lab Result Interpretation',
    'Second Opinion',
    'Mental Health Consultation',
    'Nutritional Counseling',
    'Other'
  ];

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  final List<String> _civilStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say'
  ];

  // Days of the week for availability
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  // Selected availability
  List<ScheduleDay> _availabilitySchedule = [];

  @override
  void initState() {
    super.initState();

    // Initialize availability schedule with all days of the week
    _availabilitySchedule = _daysOfWeek
        .asMap()
        .map((index, day) => MapEntry(
              index,
              ScheduleDay(
                id: '${day.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}',
                day: day,
                timeSlots: [],
              ),
            ))
        .values
        .toList();

    // Load existing schedule if available
    _loadExistingSchedule();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

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
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final formData = <String, dynamic>{};
    for (final entry in _formKey.currentState!.fields.entries) {
      formData[entry.key] = entry.value.value;
    }

    final languages = formData[languagesField] as List<String>?;
    final services = formData[servicesOfferedField] as List<String>?;

    if (languages == null || languages.isEmpty) {
      _showSnackBar('Please select at least one language', Colors.red);
      return;
    }

    if (services == null || services.isEmpty) {
      _showSnackBar('Please select at least one service', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Get existing user data
      final userSnapshot = await userRef.get();
      final userData = userSnapshot.data() ?? {};

      List<Map<String, dynamic>> availabilitySchedule = [];
      
      final now = DateTime.now();
      
      for (var day in _availabilitySchedule) {
        for (var slot in day.timeSlots) {
          final startDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            slot.startTime.hour,
            slot.startTime.minute,
          );
          
          final endDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            slot.endTime.hour,
            slot.endTime.minute,
          );
          
          availabilitySchedule.add({
            'day': day.day,
            'startTime': startDateTime,
            'endTime': endDateTime,
          });
        }
      }

          // Working history is now handled directly in the form data

      // Update user document with doctor information
      await userRef.set({
        ...userData,
        'bio': formData[bioField] ?? '',
        'languages': languages,
        'services_offered': services,
        'availability_schedule': availabilitySchedule,
        'doc_info_is_setup': true,
        'is_setup': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        _showSnackBar('Profile saved successfully!', Colors.green);
        // Add a small delay to show the success message
        await Future.delayed(const Duration(seconds: 1));
        logger.i('Navigating to /home');
        context.go('/home');
      }
    } catch (error) {
      if (mounted) {
        _showSnackBar('Error saving profile: $error', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<String? Function(String?)>? validators,
    int? maxLines,
    TextInputFormatter? inputFormatter,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          FormBuilderTextField(
            name: name,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            inputFormatters: inputFormatter != null ? [inputFormatter] : null,
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: "$label is required"),
              ...?validators,
            ]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(icon, color: const Color(0xFF58f0d7)),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF58f0d7), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Load existing schedule from Firestore
  Future<void> _loadExistingSchedule() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user!.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['availability_schedule'] != null) {
          final List<dynamic> scheduleData = data['availability_schedule'];
          
          // Convert Firestore data to ScheduleDay objects
          final Map<String, List<ScheduleTimeSlot>> scheduleMap = {};
          
          for (var day in _daysOfWeek) {
            scheduleMap[day] = [];
          }
          
          for (var slot in scheduleData) {
            final day = slot['day'] as String;
            Timestamp? startTimestamp = slot['startTime'] as Timestamp?;
            Timestamp? endTimestamp = slot['endTime'] as Timestamp?;
            
            if (startTimestamp != null && endTimestamp != null) {
              final startDateTime = startTimestamp.toDate();
              final endDateTime = endTimestamp.toDate();
              
              final start = TimeOfDay.fromDateTime(startDateTime);
              final end = TimeOfDay.fromDateTime(endDateTime);
              
              scheduleMap[day]!.add(ScheduleTimeSlot(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                startTime: start,
                endTime: end,
              ));
            }
          }
          
          // Update the schedule
          setState(() {
            _availabilitySchedule = _daysOfWeek.asMap().map((index, day) => MapEntry(
              index,
              ScheduleDay(
                id: '${day.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}_$index',
                day: day,
                timeSlots: scheduleMap[day] ?? [],
              ),
            )).values.toList();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error loading schedule: $e', Colors.red);
      }
    }
  }

  // Build the availability schedule section
  Widget _buildAvailabilitySchedule() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Availability Schedule",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            padding: const EdgeInsets.all(16),
            child: SchedulePicker(
              initialSchedule: _availabilitySchedule,
              onScheduleChanged: (updatedSchedule) {
                setState(() {
                  _availabilitySchedule = updatedSchedule;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF58f0d7),
              Color(0xFF4dd0e1),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Complete Your Doctor Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tell us more about your practice",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Container
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: FormBuilder(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: const Duration(milliseconds: 375),
                              childAnimationBuilder: (widget) => SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(child: widget),
                              ),
                              children: [
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),

                                // Professional Information Section
                                const Text(
                                  "Professional Information",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  name: bioField,
                                  label: "Professional Bio",
                                  hint:
                                      "Tell us about your professional background and expertise",
                                  icon: Icons.description_outlined,
                                  maxLines: 4,
                                ),
                                _buildFormField(
                                  name: workingHistoryField,
                                  label: "Working History",
                                  hint:
                                      "Enter your previous work experience (one per line)",
                                  icon: Icons.work_outline,
                                  maxLines: 4,
                                ),
                                _buildAvailabilitySchedule(),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Languages Spoken",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormBuilderCheckboxGroup<String>(
                                        name: languagesField,
                                        options: _languageOptions
                                            .map((language) =>
                                                FormBuilderFieldOption(
                                                  value: language,
                                                  child: Text(language),
                                                ))
                                            .toList(),
                                        decoration: InputDecoration(
                                          hintText:
                                              "Select languages you speak",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF58f0d7),
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Services Offered",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormBuilderCheckboxGroup<String>(
                                        name: servicesOfferedField,
                                        options: _servicesOptions
                                            .map((service) =>
                                                FormBuilderFieldOption(
                                                  value: service,
                                                  child: Text(service),
                                                ))
                                            .toList(),
                                        decoration: InputDecoration(
                                          hintText: "Select services you offer",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                                color: Colors.grey.shade300),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                                color: Color(0xFF58f0d7),
                                                width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF58f0d7),
                                      foregroundColor: Colors.black87,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.black87),
                                            ),
                                          )
                                        : const Text(
                                            "Complete Setup",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
