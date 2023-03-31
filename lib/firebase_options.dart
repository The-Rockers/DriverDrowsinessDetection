// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        return macos;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBVpfpTm1yTeLycAfUA1uem4PKEQVgUK7o',
    appId: '1:914520215482:web:71545a278a0a09acdc5783',
    messagingSenderId: '914520215482',
    projectId: 'antisomnus-381222',
    authDomain: 'antisomnus-381222.firebaseapp.com',
    storageBucket: 'antisomnus-381222.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDgFEFPp63uOrSGwVNvA83s6n7Q8qOoKiU',
    appId: '1:914520215482:android:fd7255340645e903dc5783',
    messagingSenderId: '914520215482',
    projectId: 'antisomnus-381222',
    storageBucket: 'antisomnus-381222.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDJy02isFS7_qB-44aduTC-bNI9GGxOsUE',
    appId: '1:914520215482:ios:39d9b14869a4c2b1dc5783',
    messagingSenderId: '914520215482',
    projectId: 'antisomnus-381222',
    storageBucket: 'antisomnus-381222.appspot.com',
    iosClientId: '914520215482-hts3gv6e6ql15gdgihp0f87fulv5871s.apps.googleusercontent.com',
    iosBundleId: 'com.example.adddFrontend',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDJy02isFS7_qB-44aduTC-bNI9GGxOsUE',
    appId: '1:914520215482:ios:39d9b14869a4c2b1dc5783',
    messagingSenderId: '914520215482',
    projectId: 'antisomnus-381222',
    storageBucket: 'antisomnus-381222.appspot.com',
    iosClientId: '914520215482-hts3gv6e6ql15gdgihp0f87fulv5871s.apps.googleusercontent.com',
    iosBundleId: 'com.example.adddFrontend',
  );
}
