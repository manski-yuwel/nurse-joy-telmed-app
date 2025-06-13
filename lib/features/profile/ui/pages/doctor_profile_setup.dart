import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';

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
  static const String phoneNumberField = 'phone_number';
  static const String addressField = 'address';
  static const String genderField = 'gender';
  static const String birthdateField = 'birthdate';
  static const String civilStatusField = 'civil_status';

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
  Map<String, Map<String, bool>> _availability = {};

  @override
  void initState() {
    super.initState();

    // Initialize availability schedule
    for (var day in _daysOfWeek) {
      _availability[day] = {
        'morning': false,
        'afternoon': false,
        'evening': false,
      };
    }

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
    final gender = formData[genderField] as String?;
    final civilStatus = formData[civilStatusField] as String?;
    final birthdate = formData[birthdateField] as DateTime?;

    if (languages == null || languages.isEmpty) {
      _showSnackBar('Please select at least one language', Colors.red);
      return;
    }

    if (services == null || services.isEmpty) {
      _showSnackBar('Please select at least one service', Colors.red);
      return;
    }

    if (gender == null) {
      _showSnackBar('Please select your gender', Colors.red);
      return;
    }

    if (civilStatus == null) {
      _showSnackBar('Please select your civil status', Colors.red);
      return;
    }

    if (birthdate == null) {
      _showSnackBar('Please select your birthdate', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user!.uid;

      // Calculate age from birthdate
      final today = DateTime.now();
      int age = today.year - birthdate.year;
      if (today.month < birthdate.month ||
          (today.month == birthdate.month && today.day < birthdate.day)) {
        age--;
      }

      // Get existing doctor data
      final doctorSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('doctor_information')
          .doc('profile')
          .get();

      final doctorData = doctorSnapshot.data() ?? {};

      // Convert availability to a format suitable for Firestore
      List<Map<String, dynamic>> availabilitySchedule = [];
      _availability.forEach((day, slots) {
        slots.forEach((slot, isAvailable) {
          if (isAvailable) {
            availabilitySchedule.add({
              'day': day,
              'slot': slot,
            });
          }
        });
      });

      // Parse working history into a list
      List<String> workingHistory = [];
      if (formData[workingHistoryField] != null &&
          formData[workingHistoryField].toString().isNotEmpty) {
        workingHistory = formData[workingHistoryField]
            .toString()
            .split('\n')
            .where((item) => item.trim().isNotEmpty)
            .toList();
      }

      // Update doctor profile data
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('doctor_information')
          .doc('profile')
          .update({
        'bio': formData[bioField]?.toString() ?? '',
        'working_history': workingHistory,
        'availability_schedule': availabilitySchedule,
        'languages': languages,
        'services_offered': services,
      });

      // Update user basic information
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'phone_number': formData[phoneNumberField]?.toString() ?? '',
        'address': formData[addressField]?.toString() ?? '',
        'gender': gender,
        'civil_status': civilStatus,
        'birthdate': Timestamp.fromDate(birthdate),
        'age': age,
        'is_setup': true,
      });

      if (mounted) {
        _showSnackBar('Profile saved successfully!', Colors.green);
        // Add a small delay to show the success message
        await Future.delayed(const Duration(seconds: 1));
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
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 100),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Morning",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Afternoon",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          "Evening",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ..._daysOfWeek.map((day) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            day,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Checkbox(
                              value: _availability[day]!['morning'],
                              onChanged: (value) {
                                setState(() {
                                  _availability[day]!['morning'] = value!;
                                });
                              },
                              activeColor: const Color(0xFF58f0d7),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Checkbox(
                              value: _availability[day]!['afternoon'],
                              onChanged: (value) {
                                setState(() {
                                  _availability[day]!['afternoon'] = value!;
                                });
                              },
                              activeColor: const Color(0xFF58f0d7),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Checkbox(
                              value: _availability[day]!['evening'],
                              onChanged: (value) {
                                setState(() {
                                  _availability[day]!['evening'] = value!;
                                });
                              },
                              activeColor: const Color(0xFF58f0d7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
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
                                // Personal Information Section
                                const Text(
                                  "Personal Information",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  name: phoneNumberField,
                                  label: "Phone Number",
                                  hint: "Enter your phone number",
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                _buildFormField(
                                  name: addressField,
                                  label: "Address",
                                  hint: "Enter your address",
                                  icon: Icons.location_on_outlined,
                                  maxLines: 2,
                                ),
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Birthdate",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormBuilderDateTimePicker(
                                        name: birthdateField,
                                        inputType: InputType.date,
                                        format: DateFormat('MMM dd, yyyy'),
                                        initialDate: DateTime(1980),
                                        firstDate: DateTime(1900),
                                        lastDate: DateTime.now(),
                                        decoration: InputDecoration(
                                          hintText: "Select your birthdate",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          prefixIcon: const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Color(0xFF58f0d7)),
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
                                        "Gender",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormBuilderDropdown<String>(
                                        name: genderField,
                                        items: _genderOptions
                                            .map((gender) => DropdownMenuItem(
                                                  value: gender,
                                                  child: Text(gender),
                                                ))
                                            .toList(),
                                        decoration: InputDecoration(
                                          hintText: "Select your gender",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          prefixIcon: const Icon(
                                              Icons.person_outline,
                                              color: Color(0xFF58f0d7)),
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
                                        "Civil Status",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      FormBuilderDropdown<String>(
                                        name: civilStatusField,
                                        items: _civilStatusOptions
                                            .map((status) => DropdownMenuItem(
                                                  value: status,
                                                  child: Text(status),
                                                ))
                                            .toList(),
                                        decoration: InputDecoration(
                                          hintText: "Select your civil status",
                                          hintStyle: TextStyle(
                                              color: Colors.grey.shade500),
                                          prefixIcon: const Icon(
                                              Icons.family_restroom_outlined,
                                              color: Color(0xFF58f0d7)),
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
