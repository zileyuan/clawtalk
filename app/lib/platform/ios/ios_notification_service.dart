import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// iOS implementation of NotificationService
class IOSNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize for iOS
      const initializationSettings = InitializationSettings(
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
    } catch (e) {
      throw const CacheException(
        message: 'Failed to initialize notifications',
        code: 4001,
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

      final iOSDetails = DarwinNotificationDetails(
        subtitle: options.subtitle,
        sound: options.sound,
        badgeNumber: options.badge,
        presentAlert: true,
        presentBadge: true,
        presentSound: options.sound != null,
      );

      final notificationDetails = NotificationDetails(iOS: iOSDetails);

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
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

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
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();

      return result?.isEnabled == true
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
