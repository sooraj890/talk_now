import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidInit =
    AndroidInitializationSettings('@drawable/splash');

    const settings = InitializationSettings(android: androidInit);

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Incoming chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void show(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }
}
