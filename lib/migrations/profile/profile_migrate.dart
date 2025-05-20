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
      if (!user.data().containsKey("search_keywords")) {
        
        final newUser = {
          'search_keywords': [
            user.data()['full_name'].toLowerCase(),
            user.data()['email'].toLowerCase(),
          ],
        };
    }
  }
}
