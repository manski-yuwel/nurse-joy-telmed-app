import 'package:nursejoyapp/migrations/profile/profile_migrate.dart';
import 'package:nursejoyapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final profileMigrate = ProfileMigrate();
  await profileMigrate.migrateProfileData();
  print('Profile migration completed');
}
