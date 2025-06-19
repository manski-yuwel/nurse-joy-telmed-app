// migrate the profile data from the old to the new format with the isSetUp field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class ProfileMigrate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final logger = Logger();

  // remove from the processing from the main thread
  Future<void> migrateProfileData() async {
    final usersCollection = _firestore.collection('users');
    final usersSnapshot = await usersCollection.get();
    final users = usersSnapshot.docs;

    for (var user in users) {
      final userData = user.data();
      if (!userData.containsKey('gender')) {
        final newUser = {
          'gender': '',
        };
        await usersCollection.doc(user.id).update(newUser);
      }
    }
  }

  List<String> createSearchIndex(String fullName) {
    final List<String> parts = fullName.split(' ');
    final List<String> nGrams = [];
    for (var part in parts) {
      nGrams.addAll(createNGrams(part));
    }
    return nGrams;
  }

  List<String> createNGrams(String part, {int minGram = 1, int maxGram = 10}) {
    final List<String> nGrams = [];
    for (var j = 1; j <= maxGram; j++) {
      if (j <= part.length) {
        nGrams.add(part.substring(0, j));
      }
    }
    return nGrams;
  }
}
