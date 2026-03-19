import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../platform_interface.dart';
import '../../core/errors/exceptions.dart';

/// Windows implementation of NotificationService
class WindowsNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _notificationId = 0;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize for Windows
      const initializationSettings = InitializationSettings(
        windows: WindowsInitializationSettings(
          appName: 'ClawTalk',
          appUserModelId: 'com.clawtalk.app',
          guid: 'clawtalk-windows-notifications',
        ),
      );

      await _notifications.initialize(settings: initializationSettings);

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

      final windowsDetails = WindowsNotificationDetails(
        subtitle: options.subtitle,
      );

      final notificationDetails = NotificationDetails(windows: windowsDetails);

      await _notifications.show(
        id: id,
        title: options.title,
        body: options.body,
        notificationDetails: notificationDetails,
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
      await _notifications.cancel(id: id);
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
              subtitle: null, // subtitle not available in newer API
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
    // Windows doesn't require explicit notification permission
    return PermissionStatus.granted;
  }

  @override
  Future<PermissionStatus> checkPermission() async {
    // Windows doesn't require explicit notification permission
    return PermissionStatus.granted;
  }

  @override
  Future<void> dispose() async {
    await cancelAll();
  }
}
