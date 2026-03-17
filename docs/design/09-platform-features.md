# ClawTalk 平台特性设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md)

---

## 目录

1. [概述](#1-概述)
2. [后台录音设计](#2-后台录音设计)
3. [推送通知设计](#3-推送通知设计)
4. [键盘快捷键设计](#4-键盘快捷键设计)
5. [分屏适配设计](#5-分屏适配设计)
6. [平台服务层](#6-平台服务层)
7. [测试用例](#7-测试用例)
8. [附录](#8-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端的平台特性设计，包括：
- 后台录音功能
- 推送通知集成
- 键盘快捷键支持
- 分屏模式适配

### 1.2 平台能力矩阵

| 能力 | macOS | Windows | Android | iOS |
|------|:-----:|:-------:|:-------:|:---:|
| 后台录音 | ✓ | ✓ | ✓ | ✓ |
| 推送通知 | ◐ | ◐ | ✓ | ✓ |
| 键盘快捷键 | ✓ | ✓ | - | - |
| 分屏模式 | ✓ | ✓ | ✓ | ✓ |
| 图片拖放 | ✓ | ✓ | - | ◐ |
| 图片粘贴 | ✓ | ✓ | ◐ | ◐ |

**图例**: ✓ 完全支持 | ◐ 部分支持 | - 不支持

### 1.3 模块结构

```
lib/platform/
├── services/
│   ├── background_recording_service.dart
│   ├── push_notification_service.dart
│   └── keyboard_shortcut_service.dart
├── channels/
│   ├── audio_channel.dart
│   └── notification_channel.dart
└── providers/
    ├── platform_features_provider.dart
    └── background_state_provider.dart
```

---

## 2. 后台录音设计

### 2.1 平台实现方案

```
┌─────────────────────────────────────────────────────────────┐
│                    后台录音平台实现                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     Android                          │   │
│  │  • Foreground Service                               │   │
│  │  • 通知栏显示录音状态                                │   │
│  │  • WakeLock 保持 CPU 运行                            │   │
│  │  • 权限: FOREGROUND_SERVICE, RECORD_AUDIO           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     iOS                              │   │
│  │  • Background Audio Session                         │   │
│  │  • UIBackgroundModes: audio                         │   │
│  │  • AVAudioSession Category: playAndRecord           │   │
│  │  • 锁屏显示录音指示器                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   macOS / Windows                    │   │
│  │  • 后台任务不限制                                    │   │
│  │  • 系统托盘图标显示状态                              │   │
│  │  • Dock 栏指示器                                    │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Android Foreground Service

```dart
// lib/platform/services/android/background_recording_service.dart

class AndroidBackgroundRecordingService {
  static const MethodChannel _channel = MethodChannel(
    'com.clawtalk/background_recording',
  );
  
  /// 开始后台录音
  Future<void> startBackgroundRecording({
    required String notificationTitle,
    required String notificationContent,
  }) async {
    await _channel.invokeMethod('startRecording', {
      'notificationTitle': notificationTitle,
      'notificationContent': notificationContent,
    });
  }
  
  /// 停止后台录音
  Future<String?> stopBackgroundRecording() async {
    return await _channel.invokeMethod<String>('stopRecording');
  }
  
  /// 取消后台录音
  Future<void> cancelBackgroundRecording() async {
    await _channel.invokeMethod('cancelRecording');
  }
  
  /// 获取录音时长
  Future<int> getRecordingDuration() async {
    return await _channel.invokeMethod<int>('getDuration') ?? 0;
  }
}

// android/app/src/main/kotlin/.../BackgroundRecordingService.kt
```

```kotlin
// Android Native Implementation
class BackgroundRecordingService : Service() {
    private var audioRecorder: MediaRecorder? = null
    private var outputFile: String? = null
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // 创建通知渠道
        val notification = createNotification(
            title = "ClawTalk 录音中",
            content = "正在录制语音消息..."
        )
        
        // 启动前台服务
        startForeground(NOTIFICATION_ID, notification)
        
        // 开始录音
        startRecording()
        
        return START_STICKY
    }
    
    private fun createNotification(title: String, content: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(content)
            .setSmallIcon(R.drawable.ic_mic)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}
```

### 2.3 iOS Background Audio Session

```swift
// ios/Runner/BackgroundRecordingManager.swift

class BackgroundRecordingManager: NSObject {
    private var audioRecorder: AVAudioRecorder?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    
    func startBackgroundRecording() -> String? {
        // 配置后台音频会话
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        
        // 注册后台任务
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            self.stopRecording()
        }
        
        // 开始录音
        let outputURL = createOutputURL()
        audioRecorder = try? AVAudioRecorder(url: outputURL, settings: [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ])
        audioRecorder?.record()
        
        return outputURL.path
    }
    
    func stopRecording() -> String? {
        audioRecorder?.stop()
        
        if let taskId = backgroundTaskIdentifier {
            UIApplication.shared.endBackgroundTask(taskId)
            backgroundTaskIdentifier = nil
        }
        
        return audioRecorder?.url.path
    }
}
```

### 2.4 后台录音 Provider

```dart
// lib/platform/providers/background_state_provider.dart

@riverpod
class BackgroundRecordingState extends _$BackgroundRecordingState {
  Timer? _durationTimer;
  
  @override
  BackgroundState build() => BackgroundState.idle();
  
  /// 开始后台录音
  Future<void> startRecording() async {
    if (state.status != BackgroundRecordingStatus.idle) return;
    
    state = BackgroundState.recording(
      startTime: DateTime.now(),
      duration: Duration.zero,
    );
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final service = _getPlatformService();
        await service.startBackgroundRecording(
          notificationTitle: 'ClawTalk',
          notificationContent: '正在录制语音消息...',
        );
      }
      
      _startDurationTimer();
    } catch (e) {
      state = BackgroundState.error(e.toString());
    }
  }
  
  /// 停止后台录音
  Future<String?> stopRecording() async {
    if (state.status != BackgroundRecordingStatus.recording) return null;
    
    _durationTimer?.cancel();
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final service = _getPlatformService();
        final path = await service.stopBackgroundRecording();
        state = BackgroundState.completed(path: path);
        return path;
      }
      
      state = BackgroundState.idle();
      return null;
    } catch (e) {
      state = BackgroundState.error(e.toString());
      return null;
    }
  }
  
  /// 取消后台录音
  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    
    if (Platform.isAndroid || Platform.isIOS) {
      final service = _getPlatformService();
      await service.cancelBackgroundRecording();
    }
    
    state = BackgroundState.idle();
  }
  
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        if (state.status != BackgroundRecordingStatus.recording) {
          timer.cancel();
          return;
        }
        
        final elapsed = DateTime.now().difference(state.startTime!);
        
        // 60 秒自动停止
        if (elapsed.inSeconds >= 60) {
          timer.cancel();
          await stopRecording();
          return;
        }
        
        state = state.copyWith(duration: elapsed);
      },
    );
  }
  
  dynamic _getPlatformService() {
    if (Platform.isAndroid) {
      return AndroidBackgroundRecordingService();
    } else if (Platform.isIOS) {
      return IOSBackgroundRecordingService();
    }
    throw UnsupportedError('Platform not supported');
  }
}

enum BackgroundRecordingStatus {
  idle,
  recording,
  completed,
  error,
}

class BackgroundState {
  final BackgroundRecordingStatus status;
  final DateTime? startTime;
  final Duration? duration;
  final String? path;
  final String? error;
  
  const BackgroundState._({
    required this.status,
    this.startTime,
    this.duration,
    this.path,
    this.error,
  });
  
  static BackgroundState idle() => const BackgroundState._(
    status: BackgroundRecordingStatus.idle,
  );
  
  static BackgroundState recording({
    required DateTime startTime,
    required Duration duration,
  }) => BackgroundState._(
    status: BackgroundRecordingStatus.recording,
    startTime: startTime,
    duration: duration,
  );
  
  static BackgroundState completed({String? path}) => BackgroundState._(
    status: BackgroundRecordingStatus.completed,
    path: path,
  );
  
  static BackgroundState error(String error) => BackgroundState._(
    status: BackgroundRecordingStatus.error,
    error: error,
  );
  
  BackgroundState copyWith({Duration? duration}) => BackgroundState._(
    status: status,
    startTime: startTime,
    duration: duration ?? this.duration,
    path: path,
    error: error,
  );
}
```

---

## 3. 推送通知设计

### 3.1 推送通知架构

```
┌─────────────────────────────────────────────────────────────┐
│                    推送通知架构                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                        │
│  │  OpenClaw Gateway│                                       │
│  │  (消息来源)      │                                       │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ 消息事件                                        │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │  Push Service   │                                        │
│  │  (推送服务)      │                                       │
│  └────────┬────────┘                                        │
│           │                                                 │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│     ▼           ▼                                           │
│  ┌─────────┐ ┌─────────┐                                    │
│  │   FCM   │ │  APNs   │                                    │
│  │(Android)│ │  (iOS)  │                                    │
│  └────┬────┘ └────┬────┘                                    │
│       │           │                                         │
│       └─────┬─────┘                                         │
│             │                                               │
│             ▼                                               │
│  ┌─────────────────┐                                        │
│  │  ClawTalk App   │                                        │
│  │  (接收通知)      │                                       │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Firebase Cloud Messaging (Android)

```dart
// lib/platform/services/push_notification_service.dart

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  /// 初始化推送通知
  Future<void> initialize() async {
    // 请求权限
    await _requestPermission();
    
    // 获取 FCM Token
    final token = await _messaging.getToken();
    
    // 监听 Token 刷新
    _messaging.onTokenRefresh.listen((token) {
      _updateToken(token);
    });
    
    // 监听前台消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 监听后台消息点击
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }
  
  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    // 显示本地通知
    _showLocalNotification(
      title: message.notification?.title,
      body: message.notification?.body,
      data: message.data,
    );
  }
  
  void _handleMessageOpenedApp(RemoteMessage message) {
    // 导航到对应页面
    final sessionId = message.data['sessionId'];
    if (sessionId != null) {
      _navigateToChat(sessionId);
    }
  }
  
  void _showLocalNotification({
    String? title,
    String? body,
    Map<String, dynamic>? data,
  }) {
    // 使用 flutter_local_notifications 显示通知
  }
}
```

### 3.3 APNs (iOS)

```dart
// iOS 使用 FCM 的 APNs 支持
// 在 firebase_console 配置 APNs 证书

// ios/Runner/AppDelegate.swift
import Firebase

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 配置 Firebase
    FirebaseApp.configure()
    
    // 注册远程通知
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 前台显示通知
    completionHandler([.banner, .sound, .badge])
  }
}
```

### 3.4 通知类型定义

```dart
/// 通知类型
enum NotificationType {
  /// 新消息
  newMessage,
  
  /// 任务完成
  taskCompleted,
  
  /// Agent 回复
  agentReply,
  
  /// 连接状态
  connectionStatus,
}

/// 通知数据
class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  
  const NotificationData({
    required this.type,
    required this.title,
    required this.body,
    required this.payload,
    required this.createdAt,
  });
  
  factory NotificationData.fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    return NotificationData(
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.newMessage,
      ),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      payload: data,
      createdAt: DateTime.now(),
    );
  }
}
```

---

## 4. 键盘快捷键设计

### 4.1 快捷键定义

| 快捷键 | macOS | Windows | 功能 |
|--------|-------|---------|------|
| 发送消息 | ⌘ + Enter | Ctrl + Enter | 发送当前输入 |
| 换行 | Enter | Enter | 输入框内换行 |
| 新建会话 | ⌘ + N | Ctrl + N | 创建新会话 |
| 搜索 | ⌘ + F | Ctrl + F | 搜索消息 |
| 设置 | ⌘ + , | Ctrl + , | 打开设置 |
| 粘贴图片 | ⌘ + V | Ctrl + V | 从剪贴板粘贴图片 |
| 取消操作 | Esc | Esc | 取消当前操作 |
| 返回 | ⌘ + [ | Alt + ← | 返回上一页 |
| 前进 | ⌘ + ] | Alt + → | 前进下一页 |

### 4.2 键盘快捷键服务

```dart
// lib/platform/services/keyboard_shortcut_service.dart

class KeyboardShortcutService {
  final Map<Shortcut, VoidCallback> _shortcuts = {};
  
  /// 注册快捷键
  void register(Shortcut shortcut, VoidCallback callback) {
    _shortcuts[shortcut] = callback;
  }
  
  /// 注销快捷键
  void unregister(Shortcut shortcut) {
    _shortcuts.remove(shortcut);
  }
  
  /// 处理按键事件
  bool handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    
    final shortcut = _matchShortcut(event);
    if (shortcut != null) {
      _shortcuts[shortcut]?.call();
      return true;
    }
    
    return false;
  }
  
  Shortcut? _matchShortcut(KeyEvent event) {
    final isMac = Platform.isMacOS;
    final isWindows = Platform.isWindows;
    
    // ⌘ + Enter / Ctrl + Enter: 发送消息
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if ((isMac && HardwareKeyboard.instance.isMetaPressed) ||
          (isWindows && HardwareKeyboard.instance.isControlPressed)) {
        return Shortcut.sendMessage;
      }
    }
    
    // ⌘ + N / Ctrl + N: 新建会话
    if (event.logicalKey == LogicalKeyboardKey.keyN) {
      if ((isMac && HardwareKeyboard.instance.isMetaPressed) ||
          (isWindows && HardwareKeyboard.instance.isControlPressed)) {
        return Shortcut.newSession;
      }
    }
    
    // ⌘ + F / Ctrl + F: 搜索
    if (event.logicalKey == LogicalKeyboardKey.keyF) {
      if ((isMac && HardwareKeyboard.instance.isMetaPressed) ||
          (isWindows && HardwareKeyboard.instance.isControlPressed)) {
        return Shortcut.search;
      }
    }
    
    // Esc: 取消操作
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      return Shortcut.cancel;
    }
    
    return null;
  }
}

/// 快捷键枚举
enum Shortcut {
  sendMessage,
  newSession,
  search,
  settings,
  pasteImage,
  cancel,
  back,
  forward,
}
```

### 4.3 全局快捷键 Widget

```dart
// lib/platform/widgets/global_shortcuts.dart

class GlobalShortcuts extends StatelessWidget {
  final Widget child;
  
  const GlobalShortcuts({required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // 发送消息
        LogicalKeySet(
          Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.enter,
        ): const SendIntent(),
        
        // 新建会话
        LogicalKeySet(
          Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyN,
        ): const NewSessionIntent(),
        
        // 搜索
        LogicalKeySet(
          Platform.isMacOS ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control,
          LogicalKeyboardKey.keyF,
        ): const SearchIntent(),
        
        // 取消
        LogicalKeySet(LogicalKeyboardKey.escape): const CancelIntent(),
      },
      child: Actions(
        actions: {
          SendIntent: CallbackAction<SendIntent>(
            onInvoke: (intent) {
              // 触发发送
              return null;
            },
          ),
          NewSessionIntent: CallbackAction<NewSessionIntent>(
            onInvoke: (intent) {
              // 创建新会话
              return null;
            },
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              // 打开搜索
              return null;
            },
          ),
          CancelIntent: CallbackAction<CancelIntent>(
            onInvoke: (intent) {
              // 取消当前操作
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}

// Intent 定义
class SendIntent extends Intent {}
class NewSessionIntent extends Intent {}
class SearchIntent extends Intent {}
class CancelIntent extends Intent {}
```

---

## 5. 分屏适配设计

### 5.1 断点定义

```dart
// lib/core/constants/breakpoints.dart

class Breakpoints {
  /// 紧凑布局 (手机竖屏)
  static const double compact = 600;
  
  /// 中等布局 (大屏手机/小平板)
  static const double medium = 840;
  
  /// 扩展布局 (平板/桌面)
  static const double expanded = 1200;
  
  /// 分屏阈值
  static const double splitHalf = 400;   // 1/2 分屏
  static const double splitThird = 300;  // 1/3 分屏
}

extension BuildContextX on BuildContext {
  bool get isCompact => MediaQuery.sizeOf(this).width < Breakpoints.compact;
  bool get isMedium => 
      MediaQuery.sizeOf(this).width >= Breakpoints.compact && 
      MediaQuery.sizeOf(this).width < Breakpoints.medium;
  bool get isExpanded => MediaQuery.sizeOf(this).width >= Breakpoints.medium;
  
  bool get isSplitScreen => 
      MediaQuery.sizeOf(this).width < Breakpoints.splitHalf;
  bool get isSplitHalf => 
      MediaQuery.sizeOf(this).width >= Breakpoints.splitThird &&
      MediaQuery.sizeOf(this).width < Breakpoints.splitHalf;
}
```

### 5.2 分屏布局组件

```dart
// lib/platform/widgets/split_screen_layout.dart

class SplitScreenLayout extends StatelessWidget {
  final Widget primary;
  final Widget? secondary;
  
  const SplitScreenLayout({
    required this.primary,
    this.secondary,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // 分屏模式: 显示双列
        if (width < Breakpoints.splitHalf && secondary != null) {
          return Row(
            children: [
              // 主内容区 (窄)
              SizedBox(
                width: width * 0.4,
                child: primary,
              ),
              
              const VerticalDivider(width: 1),
              
              // 辅助内容区 (宽)
              Expanded(
                child: secondary!,
              ),
            ],
          );
        }
        
        // 正常模式: 单列
        return primary;
      },
    );
  }
}
```

### 5.3 响应式聊天界面

```
分屏模式 (< 400px):

┌─────────────────────────────────────┐
│ ◀  Main Agent                [Agent]│
├─────────────────────────────────────┤
│                                     │
│  Agent: Hello!                     │
│                                     │
│           User: Hi                  │
│                                     │
├─────────────────────────────────────┤
│ [输入框...]              📷 | 🎤 | ➤│
└─────────────────────────────────────┘

正常模式 (> 600px):

┌─────────────────────────────────────────────────────────┐
│ ◀  Main Agent                                    [Agent]│
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Agent: Hello! How can I help you?                     │
│                                                         │
│                              10:30                      │
│                                                         │
│           User: I need help with...                     │
│                                                         │
│                              10:31                      │
│                                                         │
│  Agent: Sure! Let me help you...                        │
│  ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░                                  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 输入消息...                          📷 │ 🎤 │ ➤ │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## 6. 平台服务层

### 6.1 Platform Channel 定义

```dart
// lib/platform/channels/audio_channel.dart

class AudioChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.clawtalk/audio',
  );
  
  /// 开始后台录音
  static Future<void> startBackgroundRecording({
    required String title,
    required String content,
  }) async {
    await _channel.invokeMethod('startRecording', {
      'title': title,
      'content': content,
    });
  }
  
  /// 停止后台录音
  static Future<String?> stopBackgroundRecording() async {
    return await _channel.invokeMethod<String>('stopRecording');
  }
  
  /// 取消后台录音
  static Future<void> cancelBackgroundRecording() async {
    await _channel.invokeMethod('cancelRecording');
  }
}
```

```dart
// lib/platform/channels/notification_channel.dart

class NotificationChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.clawtalk/notification',
  );
  
  /// 显示本地通知
  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _channel.invokeMethod('showNotification', {
      'title': title,
      'body': body,
      'data': data,
    });
  }
  
  /// 清除通知
  static Future<void> clearNotifications() async {
    await _channel.invokeMethod('clearNotifications');
  }
  
  /// 设置通知监听
  static void setNotificationListener(
    void Function(Map<String, dynamic>) onNotification,
  ) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onNotificationTapped') {
        onNotification(call.arguments as Map<String, dynamic>);
      }
    });
  }
}
```

### 6.2 平台特性检测

```dart
// lib/platform/providers/platform_features_provider.dart

@riverpod
PlatformFeatures platformFeatures(PlatformFeaturesRef ref) {
  return PlatformFeatures(
    isDesktop: Platform.isMacOS || Platform.isWindows || Platform.isLinux,
    isMobile: Platform.isAndroid || Platform.isIOS,
    supportsBackgroundRecording: true,
    supportsPushNotifications: Platform.isAndroid || Platform.isIOS,
    supportsKeyboardShortcuts: Platform.isMacOS || Platform.isWindows,
    supportsDragAndDrop: Platform.isMacOS || Platform.isWindows,
    supportsClipboardImage: Platform.isMacOS || Platform.isWindows,
  );
}

class PlatformFeatures {
  final bool isDesktop;
  final bool isMobile;
  final bool supportsBackgroundRecording;
  final bool supportsPushNotifications;
  final bool supportsKeyboardShortcuts;
  final bool supportsDragAndDrop;
  final bool supportsClipboardImage;
  
  const PlatformFeatures({
    required this.isDesktop,
    required this.isMobile,
    required this.supportsBackgroundRecording,
    required this.supportsPushNotifications,
    required this.supportsKeyboardShortcuts,
    required this.supportsDragAndDrop,
    required this.supportsClipboardImage,
  });
}
```

---

## 7. 测试用例

### 7.1 平台服务测试

```dart
void main() {
  group('BackgroundRecordingState', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为 idle', () {
      // act
      final state = container.read(backgroundRecordingStateProvider);
      
      // assert
      expect(state.status, equals(BackgroundRecordingStatus.idle));
    });
    
    test('startRecording 应更新状态为 recording', () async {
      // act
      await container.read(backgroundRecordingStateProvider.notifier).startRecording();
      
      // assert
      final state = container.read(backgroundRecordingStateProvider);
      expect(state.status, equals(BackgroundRecordingStatus.recording));
      expect(state.startTime, isNotNull);
    });
    
    test('cancelRecording 应恢复状态为 idle', () async {
      // arrange
      await container.read(backgroundRecordingStateProvider.notifier).startRecording();
      
      // act
      await container.read(backgroundRecordingStateProvider.notifier).cancelRecording();
      
      // assert
      final state = container.read(backgroundRecordingStateProvider);
      expect(state.status, equals(BackgroundRecordingStatus.idle));
    });
  });
  
  group('KeyboardShortcutService', () {
    late KeyboardShortcutService service;
    
    setUp(() {
      service = KeyboardShortcutService();
    });
    
    test('register 应添加快捷键回调', () {
      // arrange
      var called = false;
      
      // act
      service.register(Shortcut.sendMessage, () => called = true);
      service.handleShortcut(Shortcut.sendMessage);
      
      // assert
      expect(called, isTrue);
    });
    
    test('unregister 应移除快捷键回调', () {
      // arrange
      var called = false;
      service.register(Shortcut.sendMessage, () => called = true);
      
      // act
      service.unregister(Shortcut.sendMessage);
      
      // assert (不应抛出异常)
      expect(() => service.handleShortcut(Shortcut.sendMessage), returnsNormally);
    });
  });
}
```

---

## 8. 附录

### 8.1 平台权限配置

**Android (AndroidManifest.xml)**:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

**iOS (Info.plist)**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>ClawTalk 需要访问麦克风来录制语音消息</string>
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>remote-notification</string>
</array>
```

**macOS (Entitlements)**:
```xml
<key>com.apple.security.device.audio-input</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

### 8.2 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**