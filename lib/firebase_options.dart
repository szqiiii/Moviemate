// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      // ⚠️ GO TO FIREBASE CONSOLE AND GET YOUR REAL VALUES
      // https://console.firebase.google.com/
      // Project Settings > Your apps > Web app config
      return const FirebaseOptions(
        apiKey: "AIzaSyDwkw75FFjGgq6iYUOI2ZQWnOovcnhJoBQ", 
        authDomain: "moviemate-c09fe.firebaseapp.com",  
        projectId: "moviemate-c09fe",  
        storageBucket: "moviemate-c09fe.firebasestorage.app",  
        messagingSenderId: "850556177232",  
        appId: "1:850556177232:web:2d552bba5f316e812f7a55", 
      );
    }
    
    // For mobile (Android/iOS) - can use same config
    return const FirebaseOptions(
      apiKey: "YOUR_API_KEY_HERE",
      authDomain: "your-project.firebaseapp.com",
      projectId: "your-project-id",
      storageBucket: "your-project.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:android:abcdef",
    );
  }
}