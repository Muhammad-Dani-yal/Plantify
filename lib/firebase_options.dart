import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Firebase is configured for Android and Web.');
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCeqtfZsEMuDfGm66vcHYOVRyd85aVvAKU',
    appId: '1:525947588461:web:a17f9b1620d1cb67f0d464',
    messagingSenderId: '525947588461',
    projectId: 'plantify-00',
    authDomain: 'plantify-00.firebaseapp.com',
    storageBucket: 'plantify-00.firebasestorage.app',
  );
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCm9AtE5RXZbYfINbCWkDzfu3vyfYINTRA',
    appId: '1:525947588461:android:124800fdc74ad38ef0d464',
    messagingSenderId: '525947588461',
    projectId: 'plantify-00',
    storageBucket: 'plantify-00.firebasestorage.app',
  );
}
