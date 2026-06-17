import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // 當在本地開發或本地部署運行（localhost 或 127.0.0.1）時，自動連接至本地 Firebase 模擬器
    if (kDebugMode || Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
      final String host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    }
  } else {
    await Firebase.initializeApp();
  }

  runApp(const VroomApp());
}