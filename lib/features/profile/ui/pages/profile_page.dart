import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nursejoyapp/features/profile/data/profile_page_db.dart';
import 'package:provider/provider.dart';
import 'package:nursejoyapp/auth/provider/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

// TODO:
// - build backend api for uploading profile pic

class ProfilePage extends StatefulWidget {
  final String userID;
  const ProfilePage({super.key, required this.userID});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final InputDecoration _textFieldDecoration = const InputDecoration(
    filled: true,
    fillColor: Colors.white,
    labelStyle: TextStyle(color: Colors.black),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white),
    ),
  );
  late String _civilStatus;
  final _formKey = GlobalKey<FormBuilderState>();
  late final auth;

  // Form field names
  static const String usernameField = 'username';
  static const String emailField = 'email';
  static const String passwordField = 'password';
  static const String newPasswordField = 'new_password';
  static const String firstNameField = 'first_name';
  static const String lastNameField = 'last_name';
  static const String civilStatusField = 'civil_status';
  static const String ageField = 'age';
  static const String birthdateField = 'birthdate';
  static const String contactField = 'contact';
  static const String addressField = 'address';

  @override
  void initState() {
    super.initState();
    _civilStatus = 'Single';

    // delays the initialization of auth and fetching to allow building the widget first
    Future.delayed(Duration.zero, () {
      auth = Provider.of<AuthService>(context, listen: false);
      _fetchUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture Section
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200], // Light grey background
                    backgroundImage: auth.user?.photoURL != null
                        ? NetworkImage(auth.user!.photoURL!)
                        : null,
                    child: auth.user?.photoURL == null
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {
                      // TODO: Implement image picker
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                auth.user?.displayName?.isNotEmpty == true
                    ? auth.user!.displayName!
                    : 'No username',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: auth.user?.displayName?.isNotEmpty == true
                          ? null
                          : Colors.black,
                    ),
              ),
              const SizedBox(height: 24),

              // Login Information Section
              Card(
                color: const Color(0xFF00BFFF),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Login Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: usernameField,
                        style: const TextStyle(color: Colors.black),
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Username',
                          labelStyle: const TextStyle(color: Colors.black),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          prefixIcon: const Icon(Icons.person,
                              color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(4),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: emailField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Email',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.email(),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: passwordField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Current Password',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: newPasswordField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_reset,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        obscureText: true,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.minLength(6,
                              errorText:
                                  'Password must be at least 6 characters'),
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personal Details Section
              Card(
                color: const Color(0xFF00BFFF),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Personal Details',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: firstNameField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'First Name',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: lastNameField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Last Name',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDropdown<String>(
                        name: civilStatusField,
                        initialValue: _civilStatus,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Civil Status',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        items: ['Single', 'Married', 'Divorced', 'Widowed']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _civilStatus = value!;
                          });
                        },
                        validator: FormBuilderValidators.required(),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: ageField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Age',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                          FormBuilderValidators.min(1),
                          FormBuilderValidators.max(120),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderDateTimePicker(
                        name: birthdateField,
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Birthdate',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        validator: FormBuilderValidators.required(),
                        lastDate: DateTime.now(),
                        firstDate: DateTime(1900),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: contactField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Contact Number',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.numeric(),
                        ]),
                      ),
                      const SizedBox(height: 16),
                      FormBuilderTextField(
                        name: addressField,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Home Address',
                          labelStyle: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          border: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color.fromARGB(255, 0, 0, 0)),
                          ),
                        ),
                        maxLines: 3,
                        validator: FormBuilderValidators.required(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final formData = _formKey.currentState!.value;

                    // Extract values from the form
                    updateProfile(
                        auth.user!.uid,
                        '', // photoURL -- blank for now TO IMPLEMENT
                        formData[emailField],
                        formData[firstNameField],
                        formData[lastNameField],
                        '${formData[firstNameField]} ${formData[lastNameField]}',
                        '${formData[firstNameField].toLowerCase()} ${formData[lastNameField].toLowerCase()}',
                        formData[civilStatusField],
                        int.parse(formData[ageField].toString()),
                        formData[birthdateField],
                        formData[addressField],
                        formData[contactField]);

                    logger.i('Profile saved');
                    // reload the profile page after saving changes
                    _fetchUserProfile();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF58f0d7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                ),
                child: const Text('Save Changes',
                    style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to fetch user profile details
  Future<void> _fetchUserProfile() async {
    try {
      // get the associated user's profile with the logged in user's uid
      final DocumentSnapshot userProfile =
          await getProfile(auth.currentUser!.uid);

      // Convert the Timestamp to DateTime
      Timestamp birthTimestamp = userProfile['birthdate'];
      DateTime birthDate = birthTimestamp.toDate();

      // Update form values
      _formKey.currentState?.patchValue({
        emailField: userProfile['email'],
        firstNameField: userProfile['first_name'],
        lastNameField: userProfile['last_name'],
        civilStatusField: userProfile['civil_status'],
        ageField: userProfile['age'].toString(),
        birthdateField: birthDate,
        contactField: userProfile['phone_number'],
        addressField: userProfile['address'],
      });

      setState(() {
        _civilStatus = userProfile['civil_status'];
      });
    } catch (e) {
      // TODO: IMPLEMENT ERROR HANDLING AND PROPAGATE TO UI
      logger.e('Error fetching user profile: $e');
    }
  }

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    super.dispose();
  }
}
