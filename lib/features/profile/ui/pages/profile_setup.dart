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
import 'package:nursejoyapp/shared/utils/utils.dart';

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});

  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form field names
  static const String firstNameField = 'first_name';
  static const String lastNameField = 'last_name';
  static const String phoneField = 'phone';
  static const String addressField = 'address';
  static const String birthdateField = 'birthdate';
  static const String civilStatusField = 'civil_status';
  static const String genderField = 'gender';
  static const String minFeeField = 'min_fee';
  static const String maxFeeField = 'max_fee';
  static const String medicalHistoryField = 'medical_history';

  final List<String> _civilStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say'
  ];

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();

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

  bool _validateFeeRange() {
    final minFee = int.tryParse(_formKey.currentState!.fields[minFeeField]?.value.toString() ?? '0');
    final maxFee = int.tryParse(_formKey.currentState!.fields[maxFeeField]?.value.toString() ?? '0');

    if (minFee == null || maxFee == null) {
      _showSnackBar('Fees must be numbers', Colors.red);
      return false;
    }

    if (minFee < 0 || maxFee < 0) {
      _showSnackBar('Fee cannot be negative', Colors.red);
      return false;
    }

    
    if (minFee > maxFee) {
      _showSnackBar('Maximum fee must be greater than or equal to minimum fee', Colors.red);
      return false;
    }
    return true;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userStatus = await authService.isUserSetup();
    final isDoctor = userStatus['is_doctor'] == true;
    
    if (!isDoctor && !_validateFeeRange()) {
      return;
    }

    final formData = <String, dynamic>{};
    for (final entry in _formKey.currentState!.fields.entries) {
      formData[entry.key] = entry.value.value;
    }

    final birthdate = formData[birthdateField] as DateTime?;
    final civilStatus = formData[civilStatusField] as String?;
    final gender = formData[genderField] as String?;

    if (birthdate == null) {
      _showSnackBar('Please select your birthdate', Colors.red);
      return;
    }

    if (civilStatus == null) {
      _showSnackBar('Please select your civil status', Colors.red);
      return;
    }

    if (gender == null) {
      _showSnackBar('Please select your gender', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = authService.user!.uid;

      // Calculate age from birthdate
      final today = DateTime.now();
      int age = today.year - birthdate.year;
      if (today.month < birthdate.month ||
          (today.month == birthdate.month && today.day < birthdate.day)) {
        age--;
      }

      final firstName = formData[firstNameField].toString().trim();
      final lastName = formData[lastNameField].toString().trim();
      final fullName = '$firstName $lastName';
      final fullNameLowercase = fullName.toLowerCase();

      // Update user profile data
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'full_name_lowercase': fullNameLowercase,
        'phone_number': formData[phoneField].toString().trim(),
        'address': formData[addressField].toString().trim(),
        'birthdate': Timestamp.fromDate(birthdate),
        'age': age,
        'civil_status': civilStatus,
        'gender': gender,
        'min_consultation_fee': int.tryParse(formData[minFeeField]) ?? 0,
        'max_consultation_fee': int.tryParse(formData[maxFeeField]) ?? 0,
        'medical_history': formData[medicalHistoryField]?.toString().trim() ?? '',
        'search_index': createSearchIndex(fullNameLowercase),
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
    List<TextInputFormatter>? inputFormatters,
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
            inputFormatters: inputFormatters,
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
                          Icons.person_outline,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Complete Your Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tell us more about yourself",
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildFormField(
                                        name: firstNameField,
                                        label: "First Name",
                                        hint: "Enter your first name",
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildFormField(
                                        name: lastNameField,
                                        label: "Last Name",
                                        hint: "Enter your last name",
                                        icon: Icons.person_outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildFormField(
                                  name: phoneField,
                                  label: "Phone Number",
                                  hint: "Enter your phone number",
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<Map<String, dynamic>>(
                                  future: Provider.of<AuthService>(context, listen: false).isUserSetup(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const SizedBox.shrink();
                                    }
                                    
                                    final isDoctor = snapshot.data?['is_doctor'] == true;
                                    
                                    if (!isDoctor) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Consultation Fee Range',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildFormField(
                                                  name: minFeeField,
                                                  label: 'Minimum Fee (₱)',
                                                  hint: 'e.g. 500',
                                                  icon: Icons.attach_money,
                                                  keyboardType: TextInputType.number,
                                                  validators: [
                                                    FormBuilderValidators.numeric(errorText: 'Enter a valid number'),
                                                    (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter minimum fee';
                                                      }
                                                      final fee = num.tryParse(value);
                                                      if (fee == null || fee < 0) {
                                                        return 'Fee must be a positive number';
                                                      }
                                                      return null;
                                                    },
                                                  ],
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildFormField(
                                                  name: maxFeeField,
                                                  label: 'Maximum Fee (₱)',
                                                  hint: 'e.g. 2000',
                                                  icon: Icons.attach_money,
                                                  keyboardType: TextInputType.number,
                                                  validators: [
                                                    FormBuilderValidators.numeric(errorText: 'Enter a valid number'),
                                                    (value) {
                                                      if (value == null || value.isEmpty) {
                                                        return 'Please enter maximum fee';
                                                      }
                                                      final fee = num.tryParse(value);
                                                      if (fee == null || fee < 0) {
                                                        return 'Fee must be a positive number';
                                                      }

                                                      return null;
                                                    },
                                                  ],
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.digitsOnly,
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          _buildFormField(
                                            name: medicalHistoryField,
                                            label: "Medical History",
                                            hint: "Enter any existing medical conditions, allergies, or relevant health information",
                                            icon: Icons.medical_services_outlined,
                                            maxLines: 5,
                                          ),
                                        ],
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
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
                                        initialDate: DateTime(2000),
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
