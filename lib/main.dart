import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'vroom_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'YOUR_WEB_API_KEY', // <-- Replace with your Firebase Web API Key
        appId: 'YOUR_WEB_APP_ID',   // <-- Replace with your Firebase Web App ID
        messagingSenderId: '457656371812',
        projectId: 'vroom-app-6a2df',
        authDomain: 'vroom-app-6a2df.firebaseapp.com',
        storageBucket: 'vroom-app-6a2df.firebasestorage.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const VroomApp());
}