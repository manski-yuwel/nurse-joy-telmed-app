import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:nursejoyapp/features/profile/data/profile_page_db.dart';
import 'package:nursejoyapp/shared/widgets/app_drawer.dart';
import 'package:nursejoyapp/shared/widgets/app_bottom_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

// TODO:
// - build backend api for uploading profile pic

// Initialize logger
final logger = Logger();

class ProfilePage extends StatefulWidget {
  final String userID;
  const ProfilePage({super.key, required this.userID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormBuilderState>();
  int _selectedIndex = 2; // Set to 2 for Profile tab

  // Form field names
  static const String emailField = 'email';
  static const String firstNameField = 'first_name';
  static const String lastNameField = 'last_name';
  static const String ageField = 'age';
  static const String phoneField = 'phone';
  static const String addressField = 'address';
  static const String birthdateField = 'birthdate';
  static const String civilStatusField = 'civil_status';
  static const String genderField = 'gender';

  // State variables
  String? _currentProfileImageUrl;
  bool _isLoading = false;
  bool _isEditing = false;
  Map<String, dynamic> _formData = {};
  bool _isDataLoaded = false; // Add this flag

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
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final DocumentSnapshot userProfile =
          await getProfile(auth.currentUser!.uid);

      if (userProfile.exists) {
        final data = userProfile.data() as Map<String, dynamic>;

        // Debug log
        print('Fetched data: $data');
        print('Birthdate from Firestore: ${data['birthdate']}');

        DateTime? birthdate;
        if (data['birthdate'] != null) {
          if (data['birthdate'] is Timestamp) {
            birthdate = (data['birthdate'] as Timestamp).toDate();
          } else if (data['birthdate'] is DateTime) {
            birthdate = data['birthdate'] as DateTime;
          }
        }

        print('Converted birthdate: $birthdate');

        setState(() {
          _formData = {
            emailField: data['email'] ?? '',
            firstNameField: data['first_name'] ?? '',
            lastNameField: data['last_name'] ?? '',
            ageField: data['age']?.toString() ?? '',
            phoneField: data['phone_number'] ?? '',
            addressField: data['address'] ?? '',
            civilStatusField: data['civil_status'],
            genderField: data['gender'],
            birthdateField: birthdate,
          };
          _currentProfileImageUrl = data['avatarurl'];
          _isDataLoaded = true; // Set flag when data is ready
        });

        // Debug log
        print('Form data after setting: $_formData');

        // Don't patch - let the rebuild handle it naturally
      }
    } catch (e) {
      print('Error in _fetchUserProfile: $e');
      _showSnackBar('Error loading profile: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _saveProfile() async {
    // Add null checks for form state
    final formState = _formKey.currentState;
    if (formState == null) {
      print('Form state is null - cannot save');
      _showSnackBar('Form is not ready. Please try again.', Colors.red);
      return;
    }

    if (!formState.validate()) {
      return;
    }

    // Don't use formState.value - it's returning empty {}
    // Instead, get values directly from fields
    final formData = <String, dynamic>{};
    for (final entry in formState.fields.entries) {
      formData[entry.key] = entry.value.value;
    }

    // ENHANCED DEBUG LOGGING
    print('=== FORM SAVE DEBUG ===');
    print('Form data from currentState: $formData');
    print('FormBuilder fields: ${formState.fields.keys.toList()}');
    print('Birthdate field state: ${formState.fields[birthdateField]?.value}');
    print('All field values:');
    formState.fields.forEach((key, field) {
      print('  $key: ${field.value}');
    });
    print('=======================');

    final birthdate = formData[birthdateField];

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.user;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final userId = user.uid;

      final firstName = formData[firstNameField].toString().trim();
      final lastName = formData[lastNameField].toString().trim();
      final fullName = '$firstName $lastName';
      final fullNameLowercase = fullName.toLowerCase();

      if (birthdate == null) {
        throw Exception('Birthdate cannot be null');
      }

      // Update user profile data
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': formData[emailField].toString().trim(),
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'full_name_lowercase': fullNameLowercase,
        'phone_number': formData[phoneField].toString().trim(),
        'address': formData[addressField].toString().trim(),
        'birthdate':
            birthdate is DateTime ? Timestamp.fromDate(birthdate) : birthdate,
        'age': int.parse(formData[ageField].toString()),
        'civil_status': formData[civilStatusField],
        'gender': formData[genderField],
        'updated_at': Timestamp.now(),
        'search_index': _createSearchIndex(fullNameLowercase),
      });

      setState(() => _isEditing = false);
      _showSnackBar('Profile updated successfully!', Colors.green);
    } catch (error) {
      print('Error in _saveProfile: $error');
      _showSnackBar('Error updating profile: $error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _createSearchIndex(String fullName) {
    List<String> searchIndex = [];
    String currentSubstring = '';
    for (int i = 0; i < fullName.length; i++) {
      currentSubstring += fullName[i];
      searchIndex.add(currentSubstring);
    }
    return searchIndex;
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: const Color(0xFF58f0d7)),
      filled: true,
      fillColor: _isEditing ? Colors.grey.shade50 : Colors.grey.shade100,
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
        borderSide: const BorderSide(color: Color(0xFF58f0d7), width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug log
    print('Building form with data: $_formData');
    print('Current birthdate value: ${_formData[birthdateField]}');
    print('Is data loaded: $_isDataLoaded');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF58f0d7),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isLoading
                ? null
                : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading || !_isDataLoaded // Wait for data to be loaded
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FormBuilder(
                // CRITICAL: Use the _formKey directly, don't change the key
                key: _formKey,
                enabled: _isEditing,
                initialValue: _formData,
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _currentProfileImageUrl != null
                          ? NetworkImage(_currentProfileImageUrl!)
                          : null,
                      child: _currentProfileImageUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: emailField,
                      decoration: _getInputDecoration('Email', Icons.email),
                      enabled: _isEditing,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.email(),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FormBuilderTextField(
                            name: firstNameField,
                            decoration: _getInputDecoration(
                                'First Name', Icons.person_outline),
                            enabled: _isEditing,
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FormBuilderTextField(
                            name: lastNameField,
                            decoration: _getInputDecoration(
                                'Last Name', Icons.person_outline),
                            enabled: _isEditing,
                            validator: FormBuilderValidators.required(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: phoneField,
                      decoration: _getInputDecoration('Phone', Icons.phone),
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: addressField,
                      decoration:
                          _getInputDecoration('Address', Icons.location_on),
                      enabled: _isEditing,
                      maxLines: 2,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDateTimePicker(
                      name: birthdateField,
                      decoration: _getInputDecoration(
                          'Birthdate', Icons.calendar_today),
                      enabled: _isEditing,
                      inputType: InputType.date,
                      format: DateFormat('MMM dd, yyyy'),
                      initialDate: _formData[birthdateField] ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      validator: FormBuilderValidators.required(
                          errorText: 'Please select your birthdate'),
                      onChanged: (date) {
                        print('Date changed to: $date'); // Debug log
                        if (date != null) {
                          // Calculate age
                          final today = DateTime.now();
                          int age = today.year - date.year;
                          if (today.month < date.month ||
                              (today.month == date.month &&
                                  today.day < date.day)) {
                            age--;
                          }
                          final currentFormState = _formKey.currentState;
                          if (currentFormState != null) {
                            currentFormState.patchValue({
                              ageField: age.toString(),
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    FormBuilderTextField(
                      name: ageField,
                      decoration: _getInputDecoration('Age', Icons.cake),
                      enabled: false,
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: civilStatusField,
                      decoration: _getInputDecoration(
                          'Civil Status', Icons.family_restroom),
                      enabled: _isEditing,
                      items: _civilStatusOptions
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 16),
                    FormBuilderDropdown<String>(
                      name: genderField,
                      decoration:
                          _getInputDecoration('Gender', Icons.person_outline),
                      enabled: _isEditing,
                      items: _genderOptions
                          .map((gender) => DropdownMenuItem(
                                value: gender,
                                child: Text(gender),
                              ))
                          .toList(),
                      validator: FormBuilderValidators.required(),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
