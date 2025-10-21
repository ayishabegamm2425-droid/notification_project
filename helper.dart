import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

// Helper function to download image and convert to bytes
Future<Uint8List?> _downloadImage(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
  } catch (e) {
    print('Error downloading image: $e');
  }
  return null;
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.high,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  if (message.notification != null) {
    String? imageUrl = message.data['imageUrl'];

    AndroidNotificationDetails androidDetails;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      Uint8List? imageBytes = await _downloadImage(imageUrl);

      if (imageBytes != null) {
        androidDetails = AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(imageBytes),
            largeIcon: ByteArrayAndroidBitmap(imageBytes),
            contentTitle: message.notification!.title,
            summaryText: message.notification!.body,
          ),
        );
      } else {
        androidDetails = AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: 'ic_notification',
          importance: Importance.high,
          priority: Priority.high,
        );
      }
    } else {
      androidDetails = AndroidNotificationDetails(
        channel.id,
        channel.name,
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
      );
    }

    flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      NotificationDetails(android: androidDetails),
    );
  }
}

Future<void> initializeNotifications() async {
  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: initializationSettingsAndroid,
    ),
  );

  await notificationSettings();
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
}

Future<void> notificationSettings() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission');
  } else {
    print('User declined or has not accepted permission');
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      String? imageUrl = message.data['imageUrl'];

      AndroidNotificationDetails androidDetails;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        Uint8List? imageBytes = await _downloadImage(imageUrl);

        if (imageBytes != null) {
          androidDetails = AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              largeIcon: ByteArrayAndroidBitmap(imageBytes),
              contentTitle: notification.title,
              summaryText: notification.body,
            ),
          );
        } else {
          androidDetails = AndroidNotificationDetails(
            channel.id,
            channel.name,
            icon: '@mipmap/ic_launcher',
          );
        }
      } else {
        androidDetails = AndroidNotificationDetails(
          channel.id,
          channel.name,
          icon: '@mipmap/ic_launcher',
        );
      }

      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(android: androidDetails),
      );
    }
  });

  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.high,
      enableVibration: true,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }
}

/// Loads Firebase Service Account credentials from JSON file.
/// Make sure `assets/serviceAccount.json` exists and is in `.gitignore`.
Future<ServiceAccountCredentials> loadServiceAccount() async {
  final file = File('assets/serviceAccount.json');
  final json = jsonDecode(await file.readAsString());
  return ServiceAccountCredentials.fromJson(json);
}

/// Sends a push notification via FCM HTTP v1 API.
Future<void> sendPushMessage(
  String token,
  String body,
  String title, {
  String? imageUrl,
}) async {
  try {
    // 1. Load the Service Account credentials (from JSON file)
    final serviceAccount = await loadServiceAccount();

    // 2. Define OAuth2 scopes
    final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

    // 3. Obtain an authenticated HTTP client
    final authClient = await clientViaServiceAccount(serviceAccount, scopes);

    // 4. Build the message payload
    Map<String, dynamic> messagePayload = {
      "message": {
        "token": token,
        "notification": {
          "title": title,
          "body": body,
          if (imageUrl != null && imageUrl.isNotEmpty) "image": imageUrl,
        },
        "android": {
          "priority": "HIGH",
          "notification": {
            "channel_id": "high_importance_channel",
            "sound": "default",
            "default_sound": true,
            if (imageUrl != null && imageUrl.isNotEmpty) "image": imageUrl,
          },
        },
        "apns": {
          "payload": {
            "aps": {
              "mutable-content": 1,
              "alert": {
                "title": title,
                "body": body,
              },
              "sound": "default",
            },
          },
          "fcm_options": {
            if (imageUrl != null && imageUrl.isNotEmpty) "image": imageUrl,
          },
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done",
          if (imageUrl != null && imageUrl.isNotEmpty) "imageUrl": imageUrl,
        },
      },
    };

    // 5. Send the message
    final response = await authClient.post(
      Uri.parse('https://fcm.googleapis.com/v1/projects/eventsapp-ec193/messages:send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(messagePayload),
    );

    print('FCM Response: ${response.body}');
    authClient.close();
  } catch (e) {
    print("Error sending push notification: $e");
  }
}
