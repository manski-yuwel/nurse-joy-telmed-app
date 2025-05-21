// migrate the profile data from the old to the new format with the isSetUp field

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileMigrate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateProfileData() async {
    final usersCollection = _firestore.collection('users');
    final usersSnapshot = await usersCollection.get();
    final users = usersSnapshot.docs;

    for (var user in users) {
      if (!user.data().containsKey('is_setup')) {
        final newUser = {
          'is_setup': false,
        };
        await usersCollection.doc(user.id).update(newUser);
      }
      if (!user.data().containsKey("full_name_lowercase") &&
          !user.data().containsKey("email_lowercase ")) {
        final newUser = {
          'full_name_lowercase': user.data()['full_name'].toLowerCase(),
          'email_lowercase': user.data()['email'].toLowerCase(),
        };
        await usersCollection.doc(user.id).update(newUser);
      }
      if (!user.data().containsKey("search_index")) {
        // use n-grams to create a search index
        final List<String> searchIndex = createSearchIndex(user.data()['full_name']);
        final newUser = {
          'search_index': searchIndex,
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

  List<String> createNGrams(String fullName, {int minGram = 1, int maxGram = 10}) {
    final List<String> nGrams = [];
    for (var i = 0; i < fullName.length; i++) {
      for (var j = minGram; j <= maxGram; j++) {
        if (i + j <= fullName.length) {
          nGrams.add(fullName.substring(i, i + j));
        }
      }
    }
    return nGrams;
  }
}
