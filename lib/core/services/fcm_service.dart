import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../../features/school/views/school_info_screen.dart';
import 'firebase_service.dart';

/// Handles background FCM messages (must be top-level function).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background mein local notification show karo
  await FcmService._showLocalNotification(message);
}

class FcmService extends GetxService {
  static const _channelId = 'school_notices';
  static const _channelName = 'School Notices';
  static const _channelDesc = 'Notices, homework, and school updates';

  final FirebaseService _firebaseService = FirebaseService();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final RxString fcmToken = ''.obs;
  bool _localNotificationsReady = false;

  @override
  Future<void> onInit() async {
    super.onInit();
    _firebaseService.initialize();
    if (!_firebaseService.isAvailable) return;
    await _initLocalNotifications();
    await _initFcm();
  }

  // ── Local Notifications Setup ─────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsReady) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 8+ ke liye notification channel banana zaroori hai
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _localNotificationsReady = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Notification tap hone par payload parse karo aur navigate karo
    final payload = response.payload;
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _handleNavigationFromData(data);
    } catch (_) {}
  }

  // ── FCM Setup ─────────────────────────────────────────────────────────────

  Future<void> _initFcm() async {
    // Background handler register karo
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Android 13+ pe permission maango
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // FCM token lo aur Firestore mein save karo
    final token = await messaging.getToken();
    if (token != null) {
      fcmToken.value = token;
      await _saveTokenToFirestore(token);
    }

    // Token refresh hone par update karo
    messaging.onTokenRefresh.listen(_saveTokenToFirestore);

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App background mein thi aur notification tap hua
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // App terminate thi aur notification se open hua
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigationFromData(initialMessage.data);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = _firebaseService.currentUser?.uid;
      if (uid == null) return;
      await _firebaseService.updateUser(uid, {
        'fcmToken': token,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── Message Handlers ──────────────────────────────────────────────────────

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    _handleNavigationFromData(message.data);
  }

  /// App ke andar hone par local notification show karo.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? '';
    final body = notification?.body ?? message.data['body'] as String? ?? '';

    if (title.isEmpty && body.isEmpty) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await plugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  Future<void> showLocalAlert({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await _initLocalNotifications();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: jsonEncode(data),
    );
  }

  /// Notification data ke basis par screen navigate karo.
  void _handleNavigationFromData(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? '';
    switch (type) {
      case 'notice':
        Get.toNamed(
          '/school-info',
          arguments: {
            'role': data['role'] ?? 'Student',
            'type': SchoolInfoType.notice,
          },
        );
        break;
      case 'homework':
        Get.toNamed('/student-homework');
        break;
      case 'result':
        Get.toNamed('/student-result');
        break;
      case 'attendance':
        Get.toNamed('/attendance-form');
        break;
      default:
        break;
    }
  }

  // ── Topic Subscription ────────────────────────────────────────────────────

  /// Role ke basis par FCM topic subscribe karo.
  /// Teacher → topic: "role_teacher"
  /// Student → topic: "role_student", "class_3_A" etc.
  Future<void> subscribeToRoleTopics({
    required String role,
    String? className,
    String? section,
  }) async {
    if (!_firebaseService.isAvailable) return;
    final messaging = FirebaseMessaging.instance;

    final roleTopic = 'role_${role.toLowerCase()}';
    await messaging.subscribeToTopic(roleTopic);

    if (className != null && section != null) {
      final classTopic =
          'class_${className.replaceAll(' ', '_')}_${section.toUpperCase()}';
      await messaging.subscribeToTopic(classTopic);
    }

    if (kDebugMode) {
      debugPrint('[FCM] Subscribed to: $roleTopic');
    }
  }

  Future<void> unsubscribeAll({
    required String role,
    String? className,
    String? section,
  }) async {
    if (!_firebaseService.isAvailable) return;
    final messaging = FirebaseMessaging.instance;

    await messaging.unsubscribeFromTopic('role_${role.toLowerCase()}');
    if (className != null && section != null) {
      await messaging.unsubscribeFromTopic(
        'class_${className.replaceAll(' ', '_')}_${section.toUpperCase()}',
      );
    }
  }
}
