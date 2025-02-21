import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

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

  final _formKey = GlobalKey<FormState>();
  final user = FirebaseAuth.instance.currentUser;

  // Controllers for form fields
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();

  String _civilStatus = 'Single';

  @override
  void initState() {
    super.initState();
    _emailController.text = user?.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
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
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
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
                user?.displayName?.isNotEmpty == true
                    ? user!.displayName!
                    : 'No username',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: user?.displayName?.isNotEmpty == true
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
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.black),
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Username',
                          labelStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                          prefixIcon: Icon(Icons.person,
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // White icon
                        ),
                      ),
                      // Apply the same pattern to other TextFormFields in Login Information
                      const SizedBox(height: 16), // Added spacing
                      TextFormField(
                        controller: _emailController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ), // Added email icon
                        ),
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      TextFormField(
                        controller: _passwordController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Current Password',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0)),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ), // Added lock icon
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16), // Increased spacing
                      TextFormField(
                        controller: _newPasswordController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'New Password',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(255, 0, 0, 0)),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                          prefixIcon: Icon(
                            Icons.lock_reset,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ), // Added lock reset icon
                        ),
                        obscureText: true,
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
                      TextFormField(
                        controller: _firstNameController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'First Name',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Last Name',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _civilStatus,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Civil Status',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
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
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Age',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _birthdateController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Birthdate',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                          suffixIcon: Icon(
                            Icons.calendar_today,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            _birthdateController.text =
                                "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contactController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Contact Number',
                          labelStyle: TextStyle(
                              color: Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: _textFieldDecoration.copyWith(
                          labelText: 'Home Address',
                          labelStyle: TextStyle(
                              color: const Color.fromARGB(
                                  255, 0, 0, 0)), // Made label white
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(
                                    255, 0, 0, 0)), // White border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: const Color.fromARGB(255, 0, 0,
                                    0)), // White border when not focused
                          ),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: Implement save profile logic
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _birthdateController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
