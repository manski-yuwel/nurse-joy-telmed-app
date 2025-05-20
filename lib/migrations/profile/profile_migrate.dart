// migrate the profile data from the old to the new format with the isSetUp field

import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileMigrate {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> migrateProfileData() async {
    final usersCollection = _firestore.collection('users');
    final usersSnapshot = await usersCollection.get();
    final users = usersSnapshot.docs;

    for (var user in users) {
      final newUser = {
        'is_setup': false,
      };
      await usersCollection.doc(user.id).update(newUser);
    }
  }
}
