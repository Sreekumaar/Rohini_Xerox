import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../main.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🚀 Point this to your Cloudflare Worker
  final String _apiUrl = 'https://rohini-api.rohinixerox.workers.dev';

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Notification permissions: ${settings.authorizationStatus}');

    String? token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Save token to Cloudflare D1 instead of Firestore
    await _saveTokenToCloudflare(token);

    // Subscribe admin to admin topic
    await subscribeToTopic('admin');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification opened app: ${message.messageId}');
      _handleMessage(message);
    });

    await setupInteractedMessage();
  }

  Future<void> _saveTokenToCloudflare(String? token) async {
    if (token == null) return;

    // TODO: Send token to your Cloudflare Worker so it knows where to send push notifications
    // final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    // await http.post(Uri.parse('$_apiUrl/users/token'), body: jsonEncode({'email': userEmail, 'token': token}));
    debugPrint('Token ready to save to Cloudflare: $token');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'pdf_channel',
          'PDF Uploads',
          channelDescription: 'Notifications for new PDF uploads',
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFFE91E8C),
          ledColor: const Color(0xFFE91E8C),
          ledOnMs: 1000,
          ledOffMs: 500,
          enableVibration: true,
          playSound: true,
        );

    final DarwinNotificationDetails iosDetails =
        const DarwinNotificationDetails();

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1000000),
      title: message.notification?.title ?? 'Rohini Xerox',
      body: message.notification?.body ?? 'New update',
      payload: message.data['orderId'] ?? '',
      notificationDetails: notificationDetails,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND NOTIFICATION TO ADMIN
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> sendNotificationToAdmin(Map<String, dynamic> data) async {
    const String serverKey =
        'YOUR_SERVER_KEY_HERE'; // Replace with actual Firebase FCM key
    const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    try {
      // TODO: Save notification history to Cloudflare D1 (if you want a history tab)
      // await http.post(Uri.parse('$_apiUrl/notifications/admin'), body: jsonEncode(data));

      // Send FCM push notification (FREE)
      final response = await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body:
            '''
        {
          "to": "/topics/admin",
          "notification": {
            "title": "${data['title']}",
            "body": "${data['body']}",
            "sound": "default",
            "color": "#E91E8C",
            "icon": "ic_notification"
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "screen": "admin",
            "fileName": "${data['fileName']}",
            "downloadURL": "${data['downloadURL']}",
            "orderId": "${data['orderId']}"
          },
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "pdf_channel",
              "color": "#E91E8C"
            }
          }
        }
        ''',
      );

      debugPrint('FCM Response Status: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SEND FCM TO SPECIFIC DEVICE (Customer Updates)
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> sendStatusUpdateNotification({
    required String orderId,
    required String status,
    required String
    customerEmail, // Changed from customerId to easily look up in Cloudflare
  }) async {
    try {
      final message = _getStatusMessage(status);
      final title = _getStatusTitle(status);

      // 1. Fetch the user's FCM token from your Cloudflare Worker database
      // final res = await http.get(Uri.parse('$_apiUrl/users/token?email=$customerEmail'));
      // final fcmToken = jsonDecode(res.body)['token'];
      String? fcmToken;
    } catch (e) {
      debugPrint('Error sending status update: $e');
    }
  }

  Future<void> _sendFCMToDevice(
    String token,
    String title,
    String body,
    Map<String, String> data,
  ) async {
    const String serverKey = 'YOUR_SERVER_KEY_HERE';
    const String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

    try {
      await http.post(
        Uri.parse(fcmEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body:
            '''
        {
          "to": "$token",
          "notification": {
            "title": "$title",
            "body": "$body",
            "sound": "default"
          },
          "data": ${_encodeData(data)}
        }
        ''',
      );
    } catch (e) {
      debugPrint('Error sending FCM to device: $e');
    }
  }

  String _encodeData(Map<String, String> data) {
    final Map<String, dynamic> jsonData = {};
    data.forEach((key, value) {
      jsonData[key] = value;
    });
    return jsonEncode(jsonData);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TOPIC SUBSCRIPTION
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI DATA FETCHING (Now pulling from Cloudflare instead of Firestore Streams)
  // ─────────────────────────────────────────────────────────────────────────

  // NOTE: In your UI screens, you will need to change StreamBuilder to FutureBuilder
  // to use these new Cloudflare endpoints.

  Future<List<dynamic>> getCustomerNotifications(String customerEmail) async {
    // try {
    //   final res = await http.get(Uri.parse('$_apiUrl/notifications/customer?email=$customerEmail'));
    //   return jsonDecode(res.body);
    // } catch (e) { return []; }
    return []; // Placeholder until Cloudflare is ready
  }

  Future<List<dynamic>> getAdminNotifications() async {
    // try {
    //   final res = await http.get(Uri.parse('$_apiUrl/notifications/admin'));
    //   return jsonDecode(res.body);
    // } catch (e) { return []; }
    return []; // Placeholder until Cloudflare is ready
  }

  Future<void> markAsRead(
    String notificationId, {
    required bool isAdmin,
  }) async {
    // await http.put(Uri.parse('$_apiUrl/notifications/$notificationId/read'));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MESSAGE HANDLERS & HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleMessage(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['orderId'] != null) {
      // Navigate to order details
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Your order is being processed.';
      case 'completed':
        return 'Your order is ready for pickup!';
      case 'delivered':
        return 'Your order has been delivered.';
      default:
        return 'Your order status: $status';
    }
  }

  String _getStatusTitle(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return 'Order Processing ⏳';
      case 'completed':
        return 'Order Ready! 🎉';
      case 'delivered':
        return 'Order Delivered ✅';
      default:
        return 'Order Update';
    }
  }
}
