import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for macOS - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for Linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    // Your actual values from google-services.json
    apiKey: 'AIzaSyCaC-bFzrZGExw-fE591jiEspFmMmZPzc4',
    appId: '1:278413947208:android:066a8948a09a26774d037d',
    messagingSenderId: '278413947208',
    projectId: 'rohini-xerox',
    storageBucket: 'rohini-xerox.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    // These need to be filled from your GoogleService-Info.plist
    // The values from android won't work for iOS
    apiKey: 'YOUR_IOS_API_KEY_HERE', // Get from iOS config
    appId: 'YOUR_IOS_APP_ID_HERE', // Get from iOS config
    messagingSenderId: '278413947208', // Same sender ID
    projectId: 'rohini-xerox',
    storageBucket: 'rohini-xerox.firebasestorage.app',
    iosBundleId: 'com.example.rohiniXerox', // From your JSON's iOS client info
  );
}
