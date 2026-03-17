# ClawTalk 状态管理设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [数据模型](./02-data-model.md)

---

## 目录

1. [概述](#1-概述)
2. [Provider 架构](#2-provider-架构)
3. [核心 Provider 设计](#3-核心-provider-设计)
4. [状态流图](#4-状态流图)
5. [测试用例](#5-测试用例)
6. [附录](#6-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端的 Riverpod 状态管理架构，包括：
- Provider 层次结构
- 状态定义与转换
- 副作用处理
- 持久化策略

### 1.2 技术选型

| 技术 | 版本 | 说明 |
|------|------|------|
| `flutter_riverpod` | ^2.5.0 | 状态管理核心 |
| `riverpod_annotation` | ^2.3.0 | 代码生成支持 |
| `shared_preferences` | ^2.3.0 | 状态持久化 |

### 1.3 设计原则

| 原则 | 说明 |
|------|------|
| 单一职责 | 每个 Provider 只负责一个状态 |
| 依赖注入 | 通过 Provider 依赖注入服务 |
| 不可变状态 | 所有状态使用不可变对象 |
| 副作用隔离 | 异步操作封装在 AsyncNotifier |

---

## 2. Provider 架构

### 2.1 层次结构

```
┌─────────────────────────────────────────────────────────────┐
│                    Provider 层次结构                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   UI Layer                           │   │
│  │  ConsumerWidget / Consumer                          │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ ref.read/watch              │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Feature Providers                       │   │
│  │  ConnectionProviders, MessageProviders, etc.        │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ depends on                  │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Service Providers                       │   │
│  │  AcpClientProvider, StorageProvider, etc.           │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ uses                        │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Infrastructure Providers                │   │
│  │  SharedPreferencesProvider, SecureStorageProvider   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Provider 类型选择

| Provider 类型 | 用途 | 示例 |
|---------------|------|------|
| `Provider` | 只读值、依赖注入 | 配置、服务实例 |
| `StateProvider` | 简单可变状态 | 当前选中项 |
| `StateNotifierProvider` | 复杂状态逻辑 | 消息列表、连接管理 |
| `AsyncNotifierProvider` | 异步状态 | 数据加载 |
| `StreamProvider` | 实时数据流 | WebSocket 消息 |
| `NotifierProvider` | 同步状态逻辑 | 设置管理 |

### 2.3 目录结构

```
lib/
├── core/
│   └── providers/
│       ├── app_state.dart
│       ├── storage_providers.dart
│       └── settings_provider.dart
│
├── features/
│   ├── connection/
│   │   └── providers/
│   │       ├── connection_list_provider.dart
│   │       ├── connection_manager_provider.dart
│   │       └── active_connection_provider.dart
│   │
│   ├── messaging/
│   │   └── providers/
│   │       ├── message_list_provider.dart
│   │       ├── message_stream_provider.dart
│   │       └── draft_provider.dart
│   │
│   ├── input/
│   │   └── providers/
│   │       ├── text_input_provider.dart
│   │       ├── image_input_provider.dart
│   │       └── voice_input_provider.dart
│   │
│   └── agents/
│       └── providers/
│           ├── agent_list_provider.dart
│           └── selected_agent_provider.dart
```

---

## 3. 核心 Provider 设计

### 3.1 基础设施 Provider

```dart
// lib/core/providers/storage_providers.dart

/// SharedPreferences Provider
@riverpod
SharedPreferences sharedPreferences(SharedPreferencesRef ref) {
  throw UnimplementedError('Override in main.dart');
}

/// SecureStorage Provider
@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage();
}

/// Connection Config Repository Provider
@riverpod
ConnectionConfigRepository connectionConfigRepository(
  ConnectionConfigRepositoryRef ref,
) {
  return ConnectionConfigRepositoryImpl(
    prefs: ref.watch(sharedPreferencesProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
}

/// Message Repository Provider
@riverpod
MessageRepository messageRepository(MessageRepositoryRef ref) {
  return MessageRepositoryImpl(
    prefs: ref.watch(sharedPreferencesProvider),
  );
}
```

### 3.2 设置 Provider

```dart
// lib/core/providers/settings_provider.dart

@riverpod
class Settings extends _$Settings {
  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings.defaults;
  }
  
  Future<void> _loadSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final json = prefs.getString(StorageKeys.settings);
    if (json != null) {
      state = AppSettings.fromJson(jsonDecode(json));
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveSettings();
  }
  
  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _saveSettings();
  }
  
  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      StorageKeys.settings,
      jsonEncode(state.toJson()),
    );
  }
}
```

### 3.3 连接管理 Provider

```dart
// lib/features/connection/providers/connection_list_provider.dart

@riverpod
class ConnectionList extends _$ConnectionList {
  @override
  Future<List<ConnectionConfig>> build() async {
    final repo = ref.watch(connectionConfigRepositoryProvider);
    return repo.getAll();
  }
  
  Future<void> add(ConnectionConfig config) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    await repo.save(config);
    ref.invalidateSelf();
  }
  
  Future<void> update(ConnectionConfig config) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    await repo.save(config);
    ref.invalidateSelf();
  }
  
  Future<void> delete(String id) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    await repo.delete(id);
    
    // 如果删除的是当前活跃连接，清除活跃状态
    final activeId = ref.read(activeConnectionIdProvider);
    if (activeId == id) {
      ref.read(activeConnectionIdProvider.notifier).clear();
    }
    
    ref.invalidateSelf();
  }
}

/// 当前活跃连接 ID
@riverpod
class ActiveConnectionId extends _$ActiveConnectionId {
  @override
  String? build() => null;
  
  void set(String id) => state = id;
  void clear() => state = null;
}
```

### 3.4 连接状态 Provider

```dart
// lib/features/connection/providers/connection_manager_provider.dart

@riverpod
class ConnectionManagerNotifier extends _$ConnectionManagerNotifier {
  late ConnectionManager _manager;
  
  @override
  ConnectionState build() {
    _manager = ConnectionManager();
    
    // 监听状态变化
    _manager.statusStream.listen((status) {
      state = ConnectionState(
        status: status,
        error: null,
      );
    });
    
    ref.onDispose(() => _manager.dispose());
    
    return ConnectionState.disconnected;
  }
  
  Future<void> connect(String connectionId) async {
    state = ConnectionState.connecting(connectionId);
    
    try {
      final configs = await ref.read(connectionListProvider.future);
      final config = configs.firstWhere((c) => c.id == connectionId);
      
      await _manager.connect(config);
      state = ConnectionState.connected(connectionId);
      
      ref.read(activeConnectionIdProvider.notifier).set(connectionId);
    } catch (e) {
      state = ConnectionState.error(connectionId, e.toString());
    }
  }
  
  Future<void> disconnect() async {
    await _manager.disconnect();
    state = ConnectionState.disconnected;
    ref.read(activeConnectionIdProvider.notifier).clear();
  }
  
  Future<void> reconnect() async {
    final activeId = ref.read(activeConnectionIdProvider);
    if (activeId != null) {
      await connect(activeId);
    }
  }
}

/// 连接状态
class ConnectionState {
  final ConnectionStatus status;
  final String? connectionId;
  final String? error;
  
  const ConnectionState({
    required this.status,
    this.connectionId,
    this.error,
  });
  
  static ConnectionState disconnected = const ConnectionState(
    status: ConnectionStatus.disconnected,
  );
  
  static ConnectionState connecting(String id) => ConnectionState(
    status: ConnectionStatus.connecting,
    connectionId: id,
  );
  
  static ConnectionState connected(String id) => ConnectionState(
    status: ConnectionStatus.authenticated,
    connectionId: id,
  );
  
  static ConnectionState error(String id, String error) => ConnectionState(
    status: ConnectionStatus.error,
    connectionId: id,
    error: error,
  );
  
  bool get isConnected => status == ConnectionStatus.authenticated;
  bool get isConnecting => status == ConnectionStatus.connecting;
  bool get hasError => status == ConnectionStatus.error;
}
```

### 3.5 消息 Provider

```dart
// lib/features/messaging/providers/message_list_provider.dart

@riverpod
class MessageList extends _$MessageList {
  @override
  Future<List<Message>> build(String sessionId) async {
    final repo = ref.watch(messageRepositoryProvider);
    return repo.getMessages(sessionId);
  }
  
  Future<void> loadMore() async {
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;
    
    final repo = ref.read(messageRepositoryProvider);
    final more = await repo.getMessages(
      sessionId,
      beforeId: current.first.id,
    );
    
    state = AsyncData([...more, ...current]);
  }
  
  Future<void> sendMessage(Message message) async {
    // 乐观更新
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, message]);
    
    try {
      final repo = ref.read(messageRepositoryProvider);
      await repo.save(message);
      
      // 发送到服务器
      final manager = ref.read(connectionManagerNotifierProvider.notifier)._manager;
      await manager.send(createPromptRequest(
        sessionId: message.sessionId,
        text: message.textContent,
      ));
    } catch (e) {
      // 回滚乐观更新
      state = AsyncData(current);
      rethrow;
    }
  }
  
  void addReceivedMessage(Message message) {
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, message]);
  }
}

/// 消息流 Provider
@riverpod
Stream<Message> messageStream(MessageStreamRef ref, String connectionId) {
  final manager = ref.watch(connectionManagerNotifierProvider.notifier)._manager;
  return manager.messageStream;
}
```

### 3.6 输入 Provider

```dart
// lib/features/input/providers/text_input_provider.dart

@riverpod
class TextInput extends _$TextInput {
  @override
  TextInputState build() => TextInputState.empty();
  
  void updateText(String text) {
    state = state.copyWith(text: text);
  }
  
  void clear() {
    state = TextInputState.empty();
  }
  
  void insertAtCursor(String insert) {
    final current = state.text;
    final selection = state.selection;
    
    if (selection != null) {
      final newText = current.replaceRange(
        selection.start,
        selection.end,
        insert,
      );
      state = state.copyWith(text: newText);
    }
  }
}

class TextInputState {
  final String text;
  final TextSelection? selection;
  final int maxLength;
  
  const TextInputState({
    required this.text,
    this.selection,
    this.maxLength = 10000,
  });
  
  static TextInputState empty() => const TextInputState(text: '');
  
  int get length => text.length;
  bool get isOverLimit => length > maxLength;
  bool get isEmpty => text.isEmpty;
  
  TextInputState copyWith({
    String? text,
    TextSelection? selection,
  }) => TextInputState(
    text: text ?? this.text,
    selection: selection ?? this.selection,
  );
}
```

```dart
// lib/features/input/providers/image_input_provider.dart

@riverpod
class ImageInput extends _$ImageInput {
  @override
  List<ImageContent> build() => [];
  
  Future<void> pickFromGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    for (final image in images) {
      if (state.length >= 5) break; // 最多 5 张
      
      final bytes = await image.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) continue; // 跳过超过 10MB 的图片
      
      state = [...state, ImageContent(
        mimeType: image.mimeType ?? 'image/jpeg',
        data: base64Encode(bytes),
      )];
    }
  }
  
  Future<void> captureFromCamera() async {
    if (state.length >= 5) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (bytes.length <= 10 * 1024 * 1024) {
        state = [...state, ImageContent(
          mimeType: image.mimeType ?? 'image/jpeg',
          data: base64Encode(bytes),
        )];
      }
    }
  }
  
  void removeAt(int index) {
    state = [...state]..removeAt(index);
  }
  
  void clear() {
    state = [];
  }
}
```

```dart
// lib/features/input/providers/voice_input_provider.dart

@riverpod
class VoiceInput extends _$VoiceInput {
  AudioRecorder? _recorder;
  
  @override
  VoiceInputState build() => VoiceInputState.idle();
  
  Future<void> startRecording() async {
    if (state.status != RecordingStatus.idle) return;
    
    _recorder = AudioRecorder();
    
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      state = VoiceInputState.error('麦克风权限未授权');
      return;
    }
    
    state = VoiceInputState.recording(
      startTime: DateTime.now(),
      duration: Duration.zero,
    );
    
    await _recorder!.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
    );
    
    // 更新时长
    _startDurationTimer();
  }
  
  Future<void> stopRecording() async {
    if (state.status != RecordingStatus.recording) return;
    
    final path = await _recorder!.stop();
    await _recorder!.dispose();
    _recorder = null;
    
    if (path != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      if (bytes.length > 10 * 1024 * 1024) {
        state = VoiceInputState.error('录音文件超过 10MB');
        return;
      }
      
      state = VoiceInputState.preview(
        path: path,
        duration: state.duration,
        data: base64Encode(bytes),
      );
    } else {
      state = VoiceInputState.idle();
    }
  }
  
  void cancelRecording() {
    _recorder?.stop();
    _recorder?.dispose();
    _recorder = null;
    state = VoiceInputState.idle();
  }
  
  void confirmAndClear() {
    state = VoiceInputState.idle();
  }
  
  void _startDurationTimer() {
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (state.status != RecordingStatus.recording) {
        timer.cancel();
        return;
      }
      
      final elapsed = DateTime.now().difference(state.startTime!);
      
      // 录音时长限制和警告逻辑详见 07-input-module.md 语音输入设计
      // 此处仅做基本状态更新，具体限制由输入模块实现
      
      state = state.copyWith(duration: elapsed);
    });
  }
}

enum RecordingStatus {
  idle,
  recording,
  preview,
  error,
}

class VoiceInputState {
  final RecordingStatus status;
  final DateTime? startTime;
  final Duration? duration;
  final String? path;
  final String? data;
  final String? error;
  
  const VoiceInputState._({
    required this.status,
    this.startTime,
    this.duration,
    this.path,
    this.data,
    this.error,
  });
  
  static VoiceInputState idle() => const VoiceInputState._(status: RecordingStatus.idle);
  
  static VoiceInputState recording({
    required DateTime startTime,
    required Duration duration,
  }) => VoiceInputState._(
    status: RecordingStatus.recording,
    startTime: startTime,
    duration: duration,
  );
  
  static VoiceInputState preview({
    required String path,
    required Duration duration,
    required String data,
  }) => VoiceInputState._(
    status: RecordingStatus.preview,
    path: path,
    duration: duration,
    data: data,
  );
  
  static VoiceInputState error(String error) => VoiceInputState._(
    status: RecordingStatus.error,
    error: error,
  );
  
  VoiceInputState copyWith({Duration? duration}) => VoiceInputState._(
    status: status,
    startTime: startTime,
    duration: duration ?? this.duration,
    path: path,
    data: data,
    error: error,
  );
  
  bool get isRecording => status == RecordingStatus.recording;
  bool get isPreview => status == RecordingStatus.preview;
  bool get canSend => isPreview && data != null;
}
```

---

## 4. 状态流图

### 4.1 连接状态流

```
┌─────────────────────────────────────────────────────────────┐
│                   连接状态转换图                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User Action                State Change                    │
│  ───────────                ────────────                    │
│                                                             │
│  ┌─────────────┐                                           │
│  │   Disconnected                                          │
│  │   (initial)  │                                          │
│  └──────┬──────┘                                           │
│         │                                                   │
│         │ connect(id)                                       │
│         ▼                                                   │
│  ┌─────────────┐                                           │
│  │  Connecting │                                           │
│  │  (loading)  │                                           │
│  └──────┬──────┘                                           │
│         │                                                   │
│    ┌────┴────┐                                              │
│    │         │                                              │
│   success   error                                          │
│    │         │                                              │
│    ▼         ▼                                              │
│  ┌─────────┐ ┌─────────┐                                    │
│  │Connected│ │  Error  │                                    │
│  └────┬────┘ └────┬────┘                                    │
│       │           │                                         │
│       │      retry│                                         │
│       │      ─────┘                                         │
│       │                                                    │
│       │ disconnect()                                       │
│       │                                                    │
│       ▼                                                    │
│  ┌─────────────┐                                           │
│  │Disconnected │                                           │
│  └─────────────┘                                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 消息发送流

```
┌─────────────────────────────────────────────────────────────┐
│                   消息发送流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  User Input                                                 │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ Input Providers │                                        │
│  │ (Text/Image/Voice)                                      │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ sendMessage()                                   │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ MessageListProvider                                     │
│  │ 1. Optimistic update                                    │
│  │ 2. Save to local                                        │
│  │ 3. Send to server                                       │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ AcpClient.send()                                │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ ConnectionManager│                                       │
│  │ (WebSocket)     │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ WebSocket send                                  │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ OpenClaw Gateway│                                        │
│  └─────────────────┘                                        │
│                                                             │
│  Response Flow (reverse):                                   │
│      │                                                      │
│      │ WebSocket receive                                    │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ messageStreamProvider                                   │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ addReceivedMessage()                            │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ MessageListProvider                                     │
│  │ (append new message)                                    │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 测试用例

### 5.1 Settings Provider 测试

```dart
void main() {
  group('SettingsProvider', () {
    late ProviderContainer container;
    late MockSharedPreferences mockPrefs;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(mockPrefs),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('应初始化为默认设置', () {
      // act
      final settings = container.read(settingsProvider);
      
      // assert
      expect(settings.themeMode, equals(ThemeMode.system));
      expect(settings.locale, equals('zh_CN'));
    });
    
    test('setThemeMode 应更新状态并持久化', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await container.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark);
      
      // assert
      final settings = container.read(settingsProvider);
      expect(settings.themeMode, equals(ThemeMode.dark));
      verify(() => mockPrefs.setString(any(), any())).called(1);
    });
    
    test('setLocale 应更新语言设置', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await container.read(settingsProvider.notifier).setLocale('en_US');
      
      // assert
      final settings = container.read(settingsProvider);
      expect(settings.locale, equals('en_US'));
    });
  });
}
```

### 5.2 Connection Provider 测试

```dart
void main() {
  group('ConnectionListProvider', () {
    late ProviderContainer container;
    late MockConnectionConfigRepository mockRepo;
    
    setUp(() {
      mockRepo = MockConnectionConfigRepository();
      container = ProviderContainer(
        overrides: [
          connectionConfigRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      registerFallbackValue(
        ConnectionConfig(
          id: 'fallback',
          name: 'fallback',
          host: 'fallback',
          createdAt: DateTime.now(),
        ),
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('应加载所有连接配置', () async {
      // arrange
      final configs = [
        ConnectionConfig(id: '1', name: 'A', host: 'a.com', createdAt: DateTime.now()),
        ConnectionConfig(id: '2', name: 'B', host: 'b.com', createdAt: DateTime.now()),
      ];
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => configs);
      
      // act
      final result = await container.read(connectionListProvider.future);
      
      // assert
      expect(result.length, equals(2));
      expect(result[0].name, equals('A'));
    });
    
    test('add 应添加新配置', () async {
      // arrange
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => []);
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async {});
      
      final newConfig = ConnectionConfig.create(
        name: 'New',
        host: 'new.com',
        token: 'token',
      );
      
      // act
      await container.read(connectionListProvider.notifier).add(newConfig);
      
      // assert
      verify(() => mockRepo.save(any())).called(1);
    });
    
    test('delete 应删除配置', () async {
      // arrange
      when(() => mockRepo.delete(any()))
          .thenAnswer((_) async {});
      
      // act
      await container.read(connectionListProvider.notifier).delete('test-id');
      
      // assert
      verify(() => mockRepo.delete('test-id')).called(1);
    });
  });
}
```

### 5.3 Message Provider 测试

```dart
void main() {
  group('MessageListProvider', () {
    late ProviderContainer container;
    late MockMessageRepository mockRepo;
    late MockConnectionManager mockManager;
    
    setUp(() {
      mockRepo = MockMessageRepository();
      mockManager = MockConnectionManager();
      container = ProviderContainer(
        overrides: [
          messageRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      registerFallbackValue(
        Message(
          id: 'fallback',
          sessionId: 'fallback',
          connectionId: 'fallback',
          role: MessageRole.user,
          content: [],
          createdAt: DateTime.now(),
        ),
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('应加载消息列表', () async {
      // arrange
      final messages = [
        Message(
          id: 'm1',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'Hello')],
          createdAt: DateTime.now(),
        ),
      ];
      when(() => mockRepo.getMessages('s1', limit: anyNamed('limit')))
          .thenAnswer((_) async => messages);
      
      // act
      final result = await container.read(
        messageListProvider('s1').future,
      );
      
      // assert
      expect(result.length, equals(1));
      expect(result[0].textContent, equals('Hello'));
    });
    
    test('sendMessage 应乐观更新', () async {
      // arrange
      final message = Message(
        id: 'm1',
        sessionId: 's1',
        connectionId: 'c1',
        role: MessageRole.user,
        content: [TextContent(text: 'Test')],
        createdAt: DateTime.now(),
      );
      when(() => mockRepo.getMessages(any(), limit: anyNamed('limit')))
          .thenAnswer((_) async => []);
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async {});
      
      // 先初始化
      await container.read(messageListProvider('s1').future);
      
      // act
      await container.read(messageListProvider('s1').notifier).sendMessage(message);
      
      // assert
      final result = container.read(messageListProvider('s1')).valueOrNull;
      expect(result?.length, equals(1));
    });
    
    test('loadMore 应加载更早的消息', () async {
      // arrange
      final olderMessages = [
        Message(
          id: 'old1',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'Old message')],
          createdAt: DateTime.now().subtract(Duration(hours: 1)),
        ),
      ];
      final newerMessages = [
        Message(
          id: 'new1',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'New message')],
          createdAt: DateTime.now(),
        ),
      ];
      
      when(() => mockRepo.getMessages('s1', limit: anyNamed('limit')))
          .thenAnswer((_) async => newerMessages);
      when(() => mockRepo.getMessages(
        's1',
        limit: anyNamed('limit'),
        beforeId: anyNamed('beforeId'),
      )).thenAnswer((_) async => olderMessages);
      
      // 先初始化
      await container.read(messageListProvider('s1').future);
      
      // act
      await container.read(messageListProvider('s1').notifier).loadMore();
      
      // assert
      final result = container.read(messageListProvider('s1')).valueOrNull;
      expect(result?.length, equals(2));
      expect(result?[0].id, equals('old1'));
    });
  });
}
```

---

## 6. 附录

### 6.1 Provider 速查表

| Provider | 类型 | 用途 |
|----------|------|------|
| `settingsProvider` | Notifier | 应用设置 |
| `connectionListProvider` | AsyncNotifier | 连接列表 |
| `activeConnectionIdProvider` | StateNotifier | 当前连接 |
| `connectionManagerNotifierProvider` | StateNotifier | 连接状态 |
| `messageListProvider` | AsyncNotifier | 消息列表 |
| `messageStreamProvider` | Stream | 消息流 |
| `textInputProvider` | Notifier | 文字输入 |
| `imageInputProvider` | StateNotifier | 图片输入 |
| `voiceInputProvider` | StateNotifier | 语音输入 |

### 6.2 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**