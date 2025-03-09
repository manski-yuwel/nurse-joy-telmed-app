import 'package:cloud_firestore/cloud_firestore.dart';

final db = FirebaseFirestore.instance;

/// The base user of the application
class AppUser {
  final String? userID;
  final String? email;
  final String? profilePicURL;
  final String? firstName;
  final String? lastName;
  final String? civilStatus;
  final int? age;
  final DateTime? birthdate;
  final String? address;
  final String? phoneNumber;
  final String? role;
  final bool? statusOnline;

  AppUser({
    required this.userID,
    this.email,
    this.profilePicURL,
    this.firstName,
    this.lastName,
    this.civilStatus,
    this.age,
    this.birthdate,
    this.address,
    this.phoneNumber,
    this.role,
    this.statusOnline,
  });

  /// sets the details of the user and returns an AppUser instance
  factory AppUser.setDetails(String? userID, Map<String, dynamic> userData) {
    return AppUser(
      userID: userID,
      email: userData['email'],
      profilePicURL: userData['profile_pic'],
      firstName: userData['first_name'],
      lastName: userData['last_name'],
      civilStatus: userData['civil_status'],
      age: userData['age'],
      birthdate: userData['birthdate'] != null
          ? DateTime.parse(userData['birthdate'])
          : null,
      address: userData['address'],
      phoneNumber: userData['phone_number'],
      role: userData['role'],
      statusOnline: userData['status_online'],
    );
  }

  Map<String, dynamic> getDetails() {
    return {
      'email': email,
      'profile_pic': profilePicURL,
      'first_name': firstName,
      'last_name': lastName,
      'civil_status': civilStatus,
      'age': age,
      'birthdate': birthdate?.toIso8601String(),
      'address': address,
      'phone_number': phoneNumber,
      'role': role,
      'status_online': statusOnline,
    };
  }

  Future<void> updateDetailsDB() async {
    await db.collection('users').doc(userID).update(getDetails());
  }
}

class Patient extends AppUser {
  final int? height;
  final int? weight;
  final String? bloodType;
  final List<String>? allergies;
  final List<String>? medications;
  final String? otherInformation;

  Patient({
    required super.userID,
    super.email,
    super.profilePicURL,
    super.firstName,
    super.lastName,
    super.civilStatus,
    super.age,
    super.birthdate,
    super.address,
    super.phoneNumber,
    super.role,
    super.statusOnline,
    this.height,
    this.weight,
    this.bloodType,
    this.allergies,
    this.medications,
    this.otherInformation,
  });

  factory Patient.setDetails(String? userID, Map<String, dynamic> userData) {
    return Patient(
      userID: userID,
      email: userData['email'],
      profilePicURL: userData['profile_pic'],
      firstName: userData['first_name'],
      lastName: userData['last_name'],
      civilStatus: userData['civil_status'],
      age: userData['age'],
      birthdate: userData['birthdate']?.toDate(),
      address: userData['address'],
      phoneNumber: userData['phone_number'],
      role: userData['role'],
      statusOnline: userData['status_online'],
      height: userData['height'],
      weight: userData['weight'],
      bloodType: userData['blood_type'],
      allergies: List<String>.from(userData['allergies'] ?? []),
      medications: List<String>.from(userData['medications'] ?? []),
      otherInformation: userData['other_information'] ?? '',
    );
  }

  @override
  Map<String, dynamic> getDetails() {
    return {
      ...super.getDetails(),
      'height': height,
      'weight': weight,
      'blood_type': bloodType,
      'allergies': allergies,
      'medications': medications,
      'other_information': otherInformation,
    };
  }

  @override
  Future<void> updateDetailsDB() async {
    await db.collection('users').doc(userID).update(getDetails());
  }
}

class Doctor extends AppUser {
  final String? specialization;
  final List<String>? experience;
  final String? education;
  final List<String>? certifications;

  Doctor({
    required super.userID,
    super.email,
    super.profilePicURL,
    super.firstName,
    super.lastName,
    super.civilStatus,
    super.age,
    super.birthdate,
    super.address,
    super.phoneNumber,
    super.role,
    super.statusOnline,
    this.specialization,
    this.experience,
    this.education,
    this.certifications,
  });

  factory Doctor.setDetails(String? userID, Map<String, dynamic> userData) {
    return Doctor(
      userID: userID,
      email: userData['email'],
      profilePicURL: userData['profile_pic'],
      firstName: userData['first_name'],
      lastName: userData['last_name'],
      civilStatus: userData['civil_status'],
      age: userData['age'],
      birthdate: userData['birthdate']?.toDate(),
      address: userData['address'],
      phoneNumber: userData['phone_number'],
      role: userData['role'],
      statusOnline: userData['status_online'],
      specialization: userData['specialization'],
      experience: List<String>.from(userData['experience'] ?? []),
      education: userData['education'],
      certifications: List<String>.from(userData['certifications'] ?? []),
    );
  }

  @override
  Map<String, dynamic> getDetails() {
    return {
      ...super.getDetails(),
      'specialization': specialization,
      'experience': experience,
      'education': education,
      'certifications': certifications,
    };
  }

  @override
  Future<void> updateDetailsDB() async {
    await db.collection('users').doc(userID).update(getDetails());
  }
}

class Admin extends AppUser {
  Admin({
    required super.userID,
    super.email,
    super.profilePicURL,
    super.firstName,
    super.lastName,
    super.civilStatus,
    super.age,
    super.birthdate,
    super.address,
    super.phoneNumber,
    super.role,
    super.statusOnline,
  });

  factory Admin.setDetails(String? userID, Map<String, dynamic> userData) {
    return Admin(
      userID: userID,
      email: userData['email'],
      profilePicURL: userData['profile_pic'],
      firstName: userData['first_name'],
      lastName: userData['last_name'],
      civilStatus: userData['civil_status'],
      age: userData['age'],
      birthdate: userData['birthdate']?.toDate(),
      address: userData['address'],
      phoneNumber: userData['phone_number'],
      role: userData['role'],
      statusOnline: userData['status_online'],
    );
  }

  @override
  Map<String, dynamic> getDetails() {
    return {
      ...super.getDetails(),
    };
  }

  @override
  Future<void> updateDetailsDB() async {
    await db.collection('users').doc(userID).update(getDetails());
  }
}
