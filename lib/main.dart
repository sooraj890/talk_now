import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'talk_now/takeName.dart';

/// 🔔 Background notifications (Android)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase init (Web vs Mobile)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0frzXfnTwAktAn3ikTxNsvVzYYzrec6I",
        authDomain: "flutter-firebase-3af6f.firebaseapp.com",
        projectId: "flutter-firebase-3af6f",
        storageBucket: "flutter-firebase-3af6f.firebasestorage.app",
        messagingSenderId: "59935888472",
        appId: "1:59935888472:web:56f19656193343c4e1e62d",
        measurementId: "G-PN9VRN0BFC",
      ),
    );
  } else {
    await Firebase.initializeApp();

    // 🔔 Background handler (MOBILE ONLY)
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TakeName(),
    );
  }
}
