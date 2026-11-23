import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCLKdH6smRzP9PXCNZVtQXTeqXv66ssBOg',
          appId: '1:890055156351:android:3ed6c2418194a4c669154a',
          messagingSenderId: '890055156351',
          projectId: 'hrmss-b8f8e',
          storageBucket: 'hrmss-b8f8e.firebasestorage.app',
        ),
      );
    }
  } catch (e) {
    debugPrint('Background Firebase init error: $e');
  }
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _fcmToken;

  /// Callback when a notification is tapped (deep linking)
  void Function(String? notificationId, String? type, Map<String, dynamic> data)? onNotificationTapped;

  /// Callback when a foreground notification arrives (to update in-app badge/list live)
  VoidCallback? onForegroundNotificationReceived;

  String? get fcmToken => _fcmToken;

  static const AndroidNotificationChannel _announcementsChannel = AndroidNotificationChannel(
    'announcements_channel',
    'Announcements',
    description: 'Company announcements, holidays, and team events',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  static const AndroidNotificationChannel _urgentChannel = AndroidNotificationChannel(
    'urgent_alerts_channel',
    'Urgent Alerts',
    description: 'Urgent compliance, safety, and policy announcements',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _attendanceChannel = AndroidNotificationChannel(
    'attendance_channel',
    'Attendance & Pay',
    description: 'Clock-in/out confirmations, leave decisions, and payslip alerts',
    importance: Importance.defaultImportance,
    playSound: true,
  );

  Future<void> initialize({
    Future<void> Function(String token)? onTokenReady,
  }) async {
    if (_initialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyCLKdH6smRzP9PXCNZVtQXTeqXv66ssBOg',
            appId: '1:890055156351:android:3ed6c2418194a4c669154a',
            messagingSenderId: '890055156351',
            projectId: 'hrmss-b8f8e',
            storageBucket: 'hrmss-b8f8e.firebasestorage.app',
          ),
        );
      }

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Setup Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(android: androidInit, iOS: darwinInit);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              final notifId = data['notificationId'] ?? data['id'];
              final type = data['type'] ?? data['kind'];
              onNotificationTapped?.call(notifId?.toString(), type?.toString(), data);
            } catch (_) {
              onNotificationTapped?.call(response.payload, null, {});
            }
          } else {
            onNotificationTapped?.call(null, null, {});
          }
        },
      );

      // Create Android Notification Channels
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_announcementsChannel);
        await androidPlugin.createNotificationChannel(_urgentChannel);
        await androidPlugin.createNotificationChannel(_attendanceChannel);
      }

      // Request Permission (Android 13+ and iOS)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');

      // Handle Foreground Notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM message: ${message.messageId} | ${message.notification?.title}');
        _showForegroundNotification(message);
        onForegroundNotificationReceived?.call();
      });

      // Handle App Opened from Background via Notification Tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('App opened from background via notification: ${message.data}');
        final notifId = message.data['notificationId'] ?? message.data['id'];
        final type = message.data['type'] ?? message.data['kind'];
        onNotificationTapped?.call(notifId?.toString(), type?.toString(), message.data);
      });

      // Handle Initial Message if App was Terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from terminated state via notification: ${initialMessage.data}');
        final notifId = initialMessage.data['notificationId'] ?? initialMessage.data['id'];
        final type = initialMessage.data['type'] ?? initialMessage.data['kind'];
        // Delay slightly to allow the router/UI to mount
        Future.delayed(const Duration(milliseconds: 600), () {
          onNotificationTapped?.call(notifId?.toString(), type?.toString(), initialMessage.data);
        });
      }

      // Fetch FCM device token
      try {
        // ignore: deprecated_member_use
        _fcmToken = await messaging.getToken();
        debugPrint('FCM Device Token: $_fcmToken');
        if (_fcmToken != null && onTokenReady != null) {
          await onTokenReady(_fcmToken!);
        }
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
      }

      // Listen for token refreshes
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('FCM Token Refreshed: $newToken');
        if (onTokenReady != null) {
          onTokenReady(newToken);
        }
      });

      _initialized = true;
    } catch (e, stack) {
      debugPrint('PushNotificationService initialization failed: $e\n$stack');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Keystone Alert';
    final body = notification?.body ?? message.data['body'] ?? '';
    final priorityStr = (message.data['priority'] ?? '').toString().toUpperCase();
    final typeStr = (message.data['type'] ?? message.data['kind'] ?? '').toString().toUpperCase();

    final isUrgent = priorityStr == 'CRITICAL' || priorityStr == 'HIGH' || typeStr == 'URGENT';
    final isAttendance = typeStr == 'SYSTEM' || typeStr == 'ATTENDANCE' || typeStr == 'LEAVE' || typeStr == 'PAYROLL';

    final channel = isUrgent
        ? _urgentChannel
        : isAttendance
            ? _attendanceChannel
            : _announcementsChannel;

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: isUrgent ? Importance.max : Importance.defaultImportance,
      priority: isUrgent ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF0F3E2E),
      playSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final payload = jsonEncode({
      'notificationId': message.data['notificationId'] ?? message.data['id'] ?? '',
      'type': typeStr,
      ...message.data,
    });

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> deleteToken() async {
    try {
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
      _fcmToken = null;
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
