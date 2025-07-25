// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQX9J3nfKQIjcBtQweH9CDs4NoTXC8i8g',
    appId: '1:1063839307725:android:b6f616606454333f771684',
    messagingSenderId: '1063839307725',
    projectId: 'nurse-joy-d34d3',
    storageBucket: 'nurse-joy-d34d3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBS2WWANvZPA4ZWAxdmD9pL9JEq5x7fNmc',
    appId: '1:1063839307725:ios:449a98bc055d2ce9771684',
    messagingSenderId: '1063839307725',
    projectId: 'nurse-joy-d34d3',
    storageBucket: 'nurse-joy-d34d3.firebasestorage.app',
    iosClientId: '1063839307725-6mbsh8v0dtavo6vs5gprc9upakhjc9nv.apps.googleusercontent.com',
    iosBundleId: 'com.example.nursejoyapp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyArWoDun424leGH6BjbKkPgHZdbUs477fE',
    appId: '1:1063839307725:web:8df8fcaff1c71938771684',
    messagingSenderId: '1063839307725',
    projectId: 'nurse-joy-d34d3',
    authDomain: 'nurse-joy-d34d3.firebaseapp.com',
    storageBucket: 'nurse-joy-d34d3.firebasestorage.app',
    measurementId: 'G-2FPNSML1ML',
  );

}