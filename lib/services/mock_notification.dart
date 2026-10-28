// lib/services/mock_notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';

class MockNotificationService {
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pdf_channel',
          'PDF Uploads',
          channelDescription: 'Notifications for new PDF uploads',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF0D47A1),
          ledColor: Color(0xFF0D47A1),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableVibration: true,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notification'),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  // Simulate admin notification for new upload
  Future<void> simulateNewOrderNotification() async {
    await showNotification(
      title: '📄 New PDF Uploaded',
      body: 'A customer has uploaded a new document',
      payload: 'new_order',
    );
  }
}
