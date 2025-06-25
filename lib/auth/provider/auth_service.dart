import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nursejoyapp/shared/utils/utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_sign_in/google_sign_in.dart';

final logger = Logger();

class AuthService extends ChangeNotifier with WidgetsBindingObserver {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final fcm = FirebaseMessaging.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? user;
  BuildContext? context;
  User? get currentUser => user;

  AuthService() {
    WidgetsBinding.instance.addObserver(this);
    auth.authStateChanges().listen((User? user) async {
      this.user = user;
      if (user == null) {
        logger.i("User is signed out!");
      } else {
        // check if the user is setup
        logger.i("User is signed in!");
        // get fcm token
        final fcmToken = await fcm.getToken();

        // save the fcm token in firestore
        if (fcmToken != null) {
          await db
              .collection('fcm_tokens')
              .doc(user.uid)
              .set({'fcm_token': fcmToken}, SetOptions(merge: true));
          logger.i('FCM token saved in firestore: $fcmToken');
        }
        setUpMessagingListeners();
      }
      notifyListeners();
    });
  }

  Future<Map<String, dynamic>> isUserSetup() async {
    final userData = await db.collection('users').doc(user!.uid).get();
    if (userData['role'] == 'user') {
      return {
        'is_setup': userData['is_setup'],
        'is_doctor': false,
      };
    } else {
      return {
        'is_setup': userData['is_setup'],
        'is_doctor': true,
        'is_verified': userData['is_verified'] ?? false,
        'doc_info_is_setup': userData['doc_info_is_setup'] ?? false,
      };
    }
  }

  // Add Google Sign-In method
  Future<String?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return 'Sign-in cancelled';
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return 'Failed to sign in with Google';
      }

      // Check if this is a new user
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create user document for new Google sign-in users
        await _createUserDocument(firebaseUser);
      }

      // Update user status to online
      await updateUserStatus(firebaseUser, true);

      return 'Success';
    } on FirebaseAuthException catch (e) {
      logger.e('Firebase Auth Error: ${e.message}');
      return e.message ?? 'Authentication failed';
    } catch (e) {
      logger.e('Google Sign-In Error: $e');
      return 'An error occurred during sign-in';
    }
  }

// Helper method to create user document for Google sign-in users
  Future<void> _createUserDocument(User user) async {
    try {
      final userID = user.uid;
      final displayName = user.displayName ?? '';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      final fullNameLowercase = displayName.toLowerCase();

      // Get FCM token
      final fcmToken = await fcm.getToken();

      // Create user document
      await db.collection('users').doc(userID).set({
        'email': user.email ?? '',
        'profile_pic': user.photoURL ?? '',
        'full_name': displayName,
        'first_name': firstName,
        'last_name': lastName,
        'full_name_lowercase': fullNameLowercase,
        'civil_status': '',
        'age': 0,
        'birthdate': null,
        'address': '',
        'phone_number': '',
        'gender': '',
        'role': 'user',
        'status_online': true,
        'is_setup': false, // User will need to complete profile setup
        'created_at': FieldValue.serverTimestamp(),
        'search_index': createSearchIndex(fullNameLowercase),
        'fcm_token': fcmToken,
      });

      // Create health information document
      await db
          .collection('users')
          .doc(userID)
          .collection('health_information')
          .doc('health_info')
          .set({
        'height': 0,
        'weight': 0,
        'blood_type': '',
        'allergies': [],
        'medications': [],
        'other_information': '',
      });

      logger.i('User document created for Google sign-in user: $userID');
    } catch (e) {
      logger.e('Error creating user document: $e');
      throw e;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      // update the status of the user to online if the user signs in
      updateUserStatus(user, true);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return ('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        return ('Wrong password provided for that user.');
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp(String email, String password) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      // get the user id generated by firebase auth
      final userID = credential.user!.uid;

      // create the doc for the new user
      await db.collection('users').doc(userID).set({
        'email': email,
        'profile_pic': '',
        'full_name': '',
        'first_name': '',
        'last_name': '',
        'civil_status': '',
        'age': 0,
        'birthdate': null,
        'address': '',
        'phone_number': '',
        'role': 'user',
        'status_online': true,
        'is_setup': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      await db
          .collection('users')
          .doc(userID)
          .collection('health_information')
          .doc('health_info')
          .set({
        'height': 0,
        'weight': 0,
        'blood_type': '',
        'allergies': [],
        'medications': [],
        'other_information': '',
      });

      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return ('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        return ('The account already exists for that email.');
      } else {
        return e.message;
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> registerDoctor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required Map<String, dynamic> doctorDetails,
  }) async {
    try {
      // First register the user account
      final result = await auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (result.user == null) {
        return 'Failed to create user';
      }

      // Get the current user ID
      final userID = result.user!.uid;
      final fullName = '$firstName $lastName';
      final fullNameLowercase = fullName.toLowerCase();

      // Update the user role to doctor
      await db.collection('users').doc(userID).set({
        'role': 'doctor',
        'email': email,
        'profile_pic': '',
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'full_name_lowercase': fullNameLowercase,
        'is_setup': false,
        'search_index': createSearchIndex(fullNameLowercase),
        'created_at': FieldValue.serverTimestamp(),
        'status_online': true,
        'specialization': doctorDetails['specialization'] ?? '',
        'license_number': doctorDetails['license_number'] ?? '',
        'years_of_experience': doctorDetails['years_of_experience'] ?? 0,
        'education': doctorDetails['education'] != null
            ? [doctorDetails['education']]
            : [],
        'hospital_affiliation': doctorDetails['hospital_affiliation'] != null
            ? [doctorDetails['hospital_affiliation']]
            : [],
        'consultation_fee': doctorDetails['consultation_fee'] ?? 0,
        'consultation_currency':
            doctorDetails['consultation_currency'] ?? 'USD',
        'is_verified': false,
        'doc_info_is_setup': false,
        'verification_status': 'pending',
        'verification_date': null,
        'rating': 0,
        'num_of_ratings': 0,
        'working_history': [],
        'availability_schedule': [],
        'bio': doctorDetails['bio'] ?? '',
        'languages': doctorDetails['languages'] ?? [],
        'services_offered': doctorDetails['services_offered'] ?? [],
        'certificates': [],
        'profile_visibility': true,
        'last_active': FieldValue.serverTimestamp(),
        'license_file_path': doctorDetails['license_file'] ?? '',
        'education_file_path': doctorDetails['education_file'] ?? '',
      });

      await db
          .collection('users')
          .doc(userID)
          .collection('doctor_information')
          .doc('profile')
          .set({
        'specialization': doctorDetails['specialization'] ?? '',
        'license_number': doctorDetails['license_number'] ?? '',
        'years_of_experience': doctorDetails['years_of_experience'] ?? 0,
        'education': doctorDetails['education'] != null
            ? [doctorDetails['education']]
            : [],
        'hospital_affiliation': doctorDetails['hospital_affiliation'] != null
            ? [doctorDetails['hospital_affiliation']]
            : [],
        'consultation_fee': doctorDetails['consultation_fee'] ?? 0,
        'consultation_currency':
            doctorDetails['consultation_currency'] ?? 'USD',
        'is_verified': false,
        'doc_info_is_setup': false,
        'verification_status': 'pending',
        'verification_date': null,
        'rating': 0,
        'num_of_ratings': 0,
        'working_history': [],
        'availability_schedule': [],
        'bio': doctorDetails['bio'] ?? '',
        'languages': doctorDetails['languages'] ?? [],
        'services_offered': doctorDetails['services_offered'] ?? [],
        'certificates': [],
        'profile_visibility': true,
        'last_active': FieldValue.serverTimestamp(),
        'license_file_path': doctorDetails['license_file'] ?? '',
        'education_file_path': doctorDetails['education_file'] ?? '',
      });

      logger.i('Doctor registration completed for user: $userID');
      return 'Success';
    } catch (e) {
      logger.e('Error registering doctor: $e');
      return e.toString();
    }
  }

  Future<void> signOut() async {
    // update the status to offline if the user signs out
    updateUserStatus(user, false);
    await _googleSignIn.signOut();
    await auth.signOut();
  }

  Future<void> updateUserStatus(User? user, bool status) async {
    if (user == null) return;
    await db
        .collection('users')
        .doc(user.uid)
        .update({'status_online': status});
    logger.i('Updated user ${user.uid} status to $status');
  }

  void appCycleChanged(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      updateUserStatus(user, false);
      logger.i('App is in detached state and user status is set to offline');
    }
  }

  void setUpMessagingListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('Message received in foreground: ${message.notification}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('Message received in background: ${message.notification}');
    });

    fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        logger
            .i('Message received in initial message: ${message.notification}');
      }
    });
  }
}
