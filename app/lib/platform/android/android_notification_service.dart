import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// Android implementation of NotificationService
class AndroidNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize for Android
      final initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android 8.0+
      await _createNotificationChannel();

      _initialized = true;
    } catch (e) {
      throw const CacheException(
        message: 'Failed to initialize notifications',
        code: 4001,
      );
    }
  }

  Future<void> _createNotificationChannel() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      // Create default channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'clawtalk_default',
          'ClawTalk Notifications',
          description: 'Default notification channel for ClawTalk',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Create message channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'clawtalk_messages',
          'Messages',
          description: 'Notification channel for new messages',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      // Create call channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'clawtalk_calls',
          'Calls',
          description: 'Notification channel for incoming calls',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  @override
  Future<void> show(NotificationOptions options) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final id = _notificationId++;

      final androidDetails = AndroidNotificationDetails(
        'clawtalk_default',
        'ClawTalk Notifications',
        channelDescription: 'Default notification channel for ClawTalk',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        playSound: options.sound != null,
        enableVibration: true,
        subText: options.subtitle,
        styleInformation: BigTextStyleInformation(options.body),
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        id,
        options.title,
        options.body,
        notificationDetails,
        payload: options.data != null ? jsonEncode(options.data) : null,
      );
    } catch (e) {
      throw CacheException(
        message: 'Failed to show notification: $e',
        code: 4002,
      );
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      throw CacheException(
        message: 'Failed to cancel notification: $e',
        code: 4003,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      throw CacheException(
        message: 'Failed to cancel all notifications: $e',
        code: 4004,
      );
    }
  }

  @override
  Future<List<NotificationOptions>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      return pending
          .map(
            (request) => NotificationOptions(
              title: request.title ?? '',
              body: request.body ?? '',
              subtitle: request.subtitle,
              data: request.payload != null
                  ? jsonDecode(request.payload!) as Map<String, dynamic>
                  : null,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PermissionStatus> requestPermission() async {
    try {
      if (!_initialized) {
        await initialize();
      }

      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      return result == true
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  @override
  Future<PermissionStatus> checkPermission() async {
    try {
      final result = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();

      return result == true
          ? PermissionStatus.granted
          : PermissionStatus.denied;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  @override
  Future<void> dispose() async {
    await cancelAll();
  }
}
