import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyB0YMj5PJsi4mFASjYjTXDowny5OrtHxYY",
      authDomain: "treel-app-123.firebaseapp.com",
      projectId: "treel-app-123",
      storageBucket: "treel-app-123.appspot.com",
      messagingSenderId: "181176335164",
      appId: "1:181176335164:android:f13aa685b393b8f6c57c39", // You need to add the specific App ID
    );
  }
}