import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class RegisterDoctorPage extends StatefulWidget {
  const RegisterDoctorPage({Key? key}) : super(key: key);

  @override
  _RegisterDoctorPageState createState() => _RegisterDoctorPageState();
}

class _RegisterDoctorPageState extends State<RegisterDoctorPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  int _currentStep = 0;

  // File upload states
  File? _licenseFile;
  File? _educationFile;
  String? _licenseFileName;
  String? _educationFileName;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Form field names
  static const String emailField = 'email';
  static const String firstNameField = 'first_name';
  static const String lastNameField = 'last_name';
  static const String passwordField = 'password';
  static const String confirmPasswordField = 'confirm_password';

  // Doctor specific fields for page 2
  static const String specializationField = 'specialization';
  static const String licenseNumberField = 'license_number';
  static const String yearsOfExperienceField = 'years_of_experience';
  static const String educationField = 'education';
  static const String hospitalAffiliationField = 'hospital_affiliation';
  static const String consultationFeeField = 'consultation_fee';

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

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate first page
      if (_formKey.currentState?.saveAndValidate() ?? false) {
        setState(() {
          _currentStep = 1;
        });
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _pickLicenseFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _licenseFile = File(result.files.single.path!);
          _licenseFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar("Error picking file: $e", Colors.red);
    }
  }

  Future<void> _pickEducationFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _educationFile = File(result.files.single.path!);
          _educationFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showSnackBar("Error picking file: $e", Colors.red);
    }
  }

  Future<void> _registerDoctor() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) {
      return;
    }

    // Validate file uploads
    if (_licenseFile == null) {
      _showSnackBar("Please upload your medical license", Colors.red);
      return;
    }

    if (_educationFile == null) {
      _showSnackBar("Please upload your education credentials", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final formData = _formKey.currentState!.value;

      // Get form values
      final email = formData[emailField]?.toString() ?? '';
      final password = formData[passwordField]?.toString() ?? '';
      final firstName = formData[firstNameField]?.toString() ?? '';
      final lastName = formData[lastNameField]?.toString() ?? '';

      // Doctor specific details
      final doctorDetails = {
        'specialization': formData[specializationField],
        'license_number': formData[licenseNumberField],
        'years_of_experience':
            int.tryParse(formData[yearsOfExperienceField]?.toString() ?? '0') ??
                0,
        'education': formData[educationField],
        'hospital_affiliation': formData[hospitalAffiliationField],
        'consultation_fee': double.tryParse(
                formData[consultationFeeField]?.toString() ?? '0') ??
            0,
        'license_file': _licenseFile?.path,
        'education_file': _educationFile?.path,
      };

      if (email.isEmpty || password.isEmpty) {
        _showSnackBar("Email and password are required", Colors.red);
        return;
      }

      // Register the doctor
      final res = await auth.registerDoctor(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        doctorDetails: doctorDetails,
      );

      if (res == 'Success') {
        _showSnackBar("Registration submitted for approval!", Colors.green);
        if (context.mounted) {
          context.go('/signin');
        }
      } else {
        _showSnackBar(
            res ?? "Registration failed. Please try again.", Colors.red);
      }
    } catch (e) {
      _showSnackBar("An error occurred. Please try again. $e", Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFormField({
    required String name,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
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
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator ??
                FormBuilderValidators.compose([
                  FormBuilderValidators.required(
                      errorText: "$label is required"),
                ]),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(icon, color: const Color(0xFF58f0d7)),
              suffixIcon: onToggleVisibility != null
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
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

  Widget _buildFileUploadField({
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
    String? fileName,
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
          InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF58f0d7)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      fileName ?? hint,
                      style: TextStyle(
                        color: fileName != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.upload_file,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Account Credentials",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Create your doctor account",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        _buildFormField(
          name: emailField,
          label: "Email Address",
          hint: "Enter your professional email address",
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.email(),
          ]),
        ),
        _buildFormField(
          name: firstNameField,
          label: "First Name",
          hint: "Enter your first name",
          icon: Icons.person_outline,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
        ),
        _buildFormField(
          name: lastNameField,
          label: "Last Name",
          hint: "Enter your last name",
          icon: Icons.person_outline,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
          ]),
        ),
        _buildFormField(
          name: passwordField,
          label: "Password",
          hint: "Create a strong password",
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.minLength(8),
          ]),
        ),
        _buildFormField(
          name: confirmPasswordField,
          label: "Confirm Password",
          hint: "Re-enter your password",
          icon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
          validator: (value) {
            if (value != _formKey.currentState?.fields[passwordField]?.value) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58f0d7),
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                    ),
                  )
                : const Text(
                    "Next",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/signin'),
            child: RichText(
              text: TextSpan(
                text: "Already have an account? ",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: "Sign In",
                    style: TextStyle(
                      color: Color(0xFF58f0d7),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Professional Details",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tell us about your professional background",
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 32),
        _buildFormField(
          name: specializationField,
          label: "Specialization",
          hint: "E.g., Cardiology, Pediatrics",
          icon: Icons.medical_services_outlined,
          validator: FormBuilderValidators.required(),
        ),
        _buildFormField(
          name: licenseNumberField,
          label: "License Number",
          hint: "Enter your medical license number",
          icon: Icons.badge_outlined,
          validator: FormBuilderValidators.required(),
        ),
        _buildFileUploadField(
          label: "License Document",
          hint: "Upload your medical license (PDF, JPG, PNG)",
          icon: Icons.description_outlined,
          onTap: _pickLicenseFile,
          fileName: _licenseFileName,
        ),
        _buildFormField(
          name: yearsOfExperienceField,
          label: "Years of Experience",
          hint: "Enter number of years",
          icon: Icons.timeline_outlined,
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.numeric(),
          ]),
        ),
        _buildFormField(
          name: educationField,
          label: "Education",
          hint: "E.g., MD from University of...",
          icon: Icons.school_outlined,
          validator: FormBuilderValidators.required(),
        ),
        _buildFileUploadField(
          label: "Education Documents",
          hint: "Upload your education credentials (PDF, JPG, PNG)",
          icon: Icons.school_outlined,
          onTap: _pickEducationFile,
          fileName: _educationFileName,
        ),
        _buildFormField(
          name: hospitalAffiliationField,
          label: "Hospital Affiliation",
          hint: "Enter your current hospital affiliation",
          icon: Icons.local_hospital_outlined,
          validator: FormBuilderValidators.required(),
        ),
        _buildFormField(
          name: consultationFeeField,
          label: "Consultation Fee",
          hint: "Enter your fee in USD",
          icon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.numeric(),
          ]),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _previousStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Back",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerDoctor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58f0d7),
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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
                              AlwaysStoppedAnimation<Color>(Colors.black87),
                        ),
                      )
                    : const Text(
                        "Submit Application",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
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
                        "Doctor Registration",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStep == 0
                            ? "Step 1: Account Information"
                            : "Step 2: Professional Details",
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
                                if (_currentStep == 0)
                                  _buildCredentialsForm()
                                else
                                  _buildProfessionalDetailsForm(),
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
