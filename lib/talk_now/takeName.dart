import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talk_now/talk_now/users.dart';

class TakeName extends StatefulWidget {
  const TakeName({super.key});

  @override
  State<TakeName> createState() => _TakeNameState();
}

class _TakeNameState extends State<TakeName> {
  final TextEditingController nameCont = TextEditingController();
  final TextEditingController passwordCont = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _initNotifications();
  }

  // 🔔 Initialize notifications
  Future<void> _initNotifications() async {
    // Android settings
    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(initSettings);

    // Request permission (Android 13+ & iOS)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground notification handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'TalkNOW',
          message.notification!.body ?? '',
        );
      }
    });
  }

  // 🔔 Show local notification
  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'talknow_channel',
      'TalkNOW Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  // 🔹 Check saved user
  Future<void> _checkCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('uid');
    final savedName = prefs.getString('username') ?? '';

    if (savedUid != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UsersScreen(currentUserId: savedUid, nameCont: savedName),
        ),
      );
    }
  }

  // 🔹 Password hashing
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // 🔹 Password validation
  String? validatePassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    final regex =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    if (!regex.hasMatch(password)) {
      return 'Password must contain letters, numbers & special characters';
    }
    return null;
  }

  // 🔹 Save / Login user
  Future<void> saveCurrentUser(
      String username,
      String password, {
        bool isLogin = false,
      }) async {
    final passwordError = validatePassword(password);
    if (!isLogin && passwordError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(passwordError)));
      return;
    }

    setState(() => isLoading = true);

    final usersRef = FirebaseFirestore.instance.collection('users');
    final hashedPassword = hashPassword(password);
    final query =
    await usersRef.where('username', isEqualTo: username).get();

    // 🔑 LOGIN
    if (isLogin) {
      if (query.docs.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Username not found')));
        return;
      }

      final doc = query.docs.first;
      if (doc['password'] != hashedPassword) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Incorrect password')));
        return;
      }

      await _saveSessionAndToken(doc.id, username);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              UsersScreen(nameCont: username, currentUserId: doc.id),
        ),
      );
      return;
    }

    // 🆕 REGISTER
    if (query.docs.isNotEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Username already taken')));
      return;
    }

    final newDoc = await usersRef.add({
      'username': username,
      'password': hashedPassword,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _saveSessionAndToken(newDoc.id, username);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            UsersScreen(nameCont: username, currentUserId: newDoc.id),
      ),
    );
  }

  // 🔔 Save session + FCM token
  Future<void> _saveSessionAndToken(String uid, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('username', username);

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'fcmToken': token});
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Talk Now Authentication',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: nameCont,
                decoration: const InputDecoration(
                  hintText: 'Enter username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: passwordCont,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        saveCurrentUser(
                          nameCont.text.trim().toLowerCase(),
                          passwordCont.text.trim(),
                          isLogin: false,
                        );
                      },
                      child: const Text('Register'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        saveCurrentUser(
                          nameCont.text.trim().toLowerCase(),
                          passwordCont.text.trim(),
                          isLogin: true,
                        );
                      },
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
