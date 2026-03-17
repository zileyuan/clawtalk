# ClawTalk 消息模块设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [数据模型](./02-data-model.md)

---

## 目录

1. [概述](#1-概述)
2. [架构设计](#2-架构设计)
3. [Provider 设计](#3-provider-设计)
4. [Widget 设计](#4-widget-设计)
5. [测试用例](#5-测试用例)
6. [附录](#6-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端的消息模块设计，包括：
- 消息处理架构
- 本地缓存策略
- 流式消息渲染
- 草稿管理机制

### 1.2 功能范围

| 功能 | 描述 |
|------|------|
| 消息发送 | 支持文本、图片、语音消息 |
| 消息接收 | 实时接收 Agent 回复 |
| 流式渲染 | 逐字/逐块渲染 Agent 回复 |
| 本地缓存 | 离线消息缓存 |
| 消息搜索 | 全文搜索历史消息 |
| 草稿管理 | 保存未发送的消息草稿 |

### 1.3 模块结构

```
lib/
├── features/
│   └── messaging/
│       ├── data/
│       │   ├── repositories/
│       │   │   └── message_repository_impl.dart
│       │   └── datasources/
│       │       └── message_local_datasource.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── message.dart
│       │   │   ├── message_role.dart
│       │   │   └── content_block.dart
│       │   ├── repositories/
│       │   │   └── message_repository.dart
│       │   └── usecases/
│       │       ├── send_message.dart
│       │       ├── get_messages.dart
│       │       └── search_messages.dart
│       ├── presentation/
│       │   ├── providers/
│       │   │   ├── message_list_provider.dart
│       │   │   ├── message_stream_provider.dart
│       │   │   └── draft_provider.dart
│       │   ├── screens/
│       │   │   └── chat_screen.dart
│       │   └── widgets/
│       │       ├── message_bubble.dart
│       │       ├── message_input.dart
│       │       ├── streaming_text.dart
│       │       └── draft_indicator.dart
│       └── messaging_module.dart
```

---

## 2. 架构设计

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    消息模块分层架构                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Presentation Layer                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │  Providers  │  │  Screens    │  │  Widgets    │  │   │
│  │  │  (状态管理)  │  │  (页面)     │  │  (组件)     │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 Domain Layer                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │  Entities   │  │  Use Cases  │  │Repositories │  │   │
│  │  │  (消息实体)  │  │  (用例)     │  │  (接口)     │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Data Layer                         │   │
│  │  ┌─────────────┐  ┌─────────────────────────────┐   │   │
│  │  │Repository   │  │    Data Sources             │   │   │
│  │  │Impl         │  │  Local Cache │ Memory       │   │   │
│  │  └─────────────┘  └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 消息处理流程

```
┌─────────────────────────────────────────────────────────────┐
│                    消息处理流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  发送消息:                                                   │
│                                                             │
│  User Input                                                 │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ Input Providers │                                        │
│  │ (Text/Image/Voice)                                      │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ createMessage()                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │MessageListProvider                                       │
│  │ 1. 乐观更新 (显示发送中)                                  │
│  │ 2. 保存到本地缓存                                         │
│  │ 3. 发送 WebSocket 请求                                    │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ AcpClient.send()                                │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ ConnectionManager│                                       │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ OpenClaw Gateway│                                        │
│  └─────────────────┘                                        │
│                                                             │
│  接收消息 (流式):                                            │
│                                                             │
│  ┌─────────────────┐                                        │
│  │ OpenClaw Gateway│                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ WebSocket event stream                          │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ messageStreamProvider                                    │
│  │ 解析 AcpEvent                                            │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ updateMessage()                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │MessageListProvider                                       │
│  │ 1. 更新消息内容                                           │
│  │ 2. 触发 UI 重绘                                           │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 本地缓存策略

```
┌─────────────────────────────────────────────────────────────┐
│                    本地缓存策略                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  缓存层次:                                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              内存缓存 (Memory Cache)                  │   │
│  │  • 当前会话消息 (实时访问)                            │   │
│  │  • 最近 100 条消息                                    │   │
│  │  • 生命周期: 应用运行期间                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              持久化缓存 (Persistent Cache)            │   │
│  │  • SharedPreferences (JSON 序列化)                   │   │
│  │  • 每个会话最多 1000 条消息                           │   │
│  │  • 生命周期: 用户手动清除                             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  缓存规则:                                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  1. 写入: 先内存，异步持久化                          │   │
│  │  2. 读取: 先内存，再持久化                            │   │
│  │  3. 清理: LRU 策略，保留最近消息                      │   │
│  │  4. 同步: 连接成功后同步最新消息                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.4 流式消息渲染

```
┌─────────────────────────────────────────────────────────────┐
│                    流式消息渲染                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Agent 回复流:                                               │
│                                                             │
│  Server: "Hello" → "Hello, I" → "Hello, I can" → ...       │
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                │
│  │ Chunk 1 │───►│ Chunk 2 │───►│ Chunk 3 │                │
│  │ "Hello" │    │ ", I"   │    │ " can"  │                │
│  └─────────┘    └─────────┘    └─────────┘                │
│       │              │              │                      │
│       ▼              ▼              ▼                      │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              StreamingText Widget                    │   │
│  │  逐字渲染，带有打字机效果                             │   │
│  │                                                      │   │
│  │  Hello|  →  Hello, I|  →  Hello, I can|              │   │
│  │        │            │              │                 │   │
│  │        ▼            ▼              ▼                 │   │
│  │     (光标闪烁)    (光标移动)    (光标移动)             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  渲染优化:                                                   │
│  • 节流: 100ms 更新一次 UI                                   │
│  • 批量: 合并多个 chunk                                      │
│  • 虚拟化: 长消息使用 ListView                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.5 草稿管理

```
┌─────────────────────────────────────────────────────────────┐
│                    草稿管理流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  触发保存:                                                   │
│  • 用户输入停止 500ms 后自动保存                             │
│  • 切换会话时保存当前草稿                                    │
│  • 应用进入后台时保存                                        │
│                                                             │
│  草稿结构:                                                   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Draft {                                             │   │
│  │    sessionId: String,                                │   │
│  │    text: String,           // 文本内容               │   │
│  │    images: List<String>,   // 图片路径               │   │
│  │    voicePath: String?,     // 语音路径               │   │
│  │    updatedAt: DateTime,    // 更新时间               │   │
│  │  }                                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  存储位置:                                                   │
│  • SharedPreferences (key: draft_{sessionId})               │
│                                                             │
│  恢复时机:                                                   │
│  • 进入会话时恢复                                            │
│  • 用户可手动清除                                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.6 崩溃恢复机制

#### 恢复场景

| 场景 | 恢复策略 |
|------|----------|
| App 崩溃重启 | 恢复最后活跃会话，加载缓存消息 |
| 网络断开重连 | 自动重连，同步最新消息 |
| 发送中断 | 保留未发送消息，标记失败状态 |
| 接收中断 | 断点续传，补全缺失消息 |

#### 恢复流程

```
┌─────────────────────────────────────────────────────────────┐
│                    崩溃恢复流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  App 启动                                                    │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ 1. 检查恢复标记  │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│   有标记     无标记                                         │
│     │           │                                           │
│     ▼           ▼                                           │
│  ┌─────────┐ ┌─────────┐                                    │
│  │恢复会话  │ │正常启动 │                                    │
│  │状态     │ │         │                                    │
│  └────┬────┘ └─────────┘                                    │
│       │                                                     │
│       ▼                                                     │
│  ┌─────────────────┐                                        │
│  │ 2. 恢复活跃连接  │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ 3. 加载缓存消息  │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ 4. 同步最新状态  │                                        │
│  │ (重连后)        │                                        │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 实现设计

```dart
// 恢复状态管理
@riverpod
class RecoveryManager extends _$RecoveryManager {
  @override
  RecoveryState build() => RecoveryState.idle();
  
  /// 保存恢复点
  Future<void> saveRecoveryPoint({
    required String connectionId,
    required String sessionId,
    required List<String> pendingMessageIds,
  }) async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    await prefs.setString('recovery_active_connection', connectionId);
    await prefs.setString('recovery_active_session', sessionId);
    await prefs.setStringList('recovery_pending_messages', pendingMessageIds);
    await prefs.setBool('recovery_flag', true);
  }
  
  /// 清除恢复点
  Future<void> clearRecoveryPoint() async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    await prefs.remove('recovery_active_connection');
    await prefs.remove('recovery_active_session');
    await prefs.remove('recovery_pending_messages');
    await prefs.setBool('recovery_flag', false);
  }
  
  /// 尝试恢复
  Future<RecoveryResult?> attemptRecovery() async {
    final prefs = ref.read(sharedPreferencesProvider);
    
    final hasFlag = prefs.getBool('recovery_flag') ?? false;
    if (!hasFlag) return null;
    
    final connectionId = prefs.getString('recovery_active_connection');
    final sessionId = prefs.getString('recovery_active_session');
    final pendingIds = prefs.getStringList('recovery_pending_messages') ?? [];
    
    if (connectionId == null || sessionId == null) return null;
    
    state = RecoveryState.recovering();
    
    try {
      // 1. 恢复连接
      await ref.read(connectionManagerNotifierProvider.notifier)
          .connect(connectionId);
      
      // 2. 加载消息缓存
      await ref.read(messageListProvider(sessionId).future);
      
      // 3. 重试失败消息
      for (final id in pendingIds) {
        await ref.read(messageListProvider(sessionId).notifier)
            .retryMessage(id);
      }
      
      state = RecoveryState.recovered();
      
      return RecoveryResult(
        connectionId: connectionId,
        sessionId: sessionId,
        recoveredPendingCount: pendingIds.length,
      );
    } catch (e) {
      state = RecoveryState.error(e.toString());
      return null;
    }
  }
}

/// 恢复状态
enum RecoveryStatus { idle, recovering, recovered, error }

class RecoveryState {
  final RecoveryStatus status;
  final String? error;
  
  const RecoveryState._({required this.status, this.error});
  
  static idle() => const RecoveryState._(status: RecoveryStatus.idle);
  static recovering() => const RecoveryState._(status: RecoveryStatus.recovering);
  static recovered() => const RecoveryState._(status: RecoveryStatus.recovered);
  static error(String e) => RecoveryState._(status: RecoveryStatus.error, error: e);
}

/// 恢复结果
class RecoveryResult {
  final String connectionId;
  final String sessionId;
  final int recoveredPendingCount;
  
  const RecoveryResult({
    required this.connectionId,
    required this.sessionId,
    required this.recoveredPendingCount,
  });
}
```

#### 数据持久化保证

| 数据类型 | 持久化策略 |
|----------|------------|
| 连接配置 | SharedPreferences (加密存储凭证) |
| 会话状态 | 每次切换自动保存 |
| 草稿内容 | 防抖保存 (500ms) |
| 消息缓存 | 每条消息即时保存 |
| 发送中消息 | 标记 pending 状态 |

#### 崩溃检测

```dart
// main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 捕获 Flutter 错误
  FlutterError.onError = (details) {
    _reportError(details.exception, details.stack);
  };
  
  // 捕获异步错误
  runZonedGuarded(
    () => runApp(ProviderScope(child: ClawTalkApp())),
    (error, stack) => _reportError(error, stack),
  );
}

void _reportError(Object error, StackTrace? stack) {
  // 记录崩溃日志
  debugPrint('Error: $error');
  debugPrint('Stack: $stack');
  
  // 保存恢复标记
  SharedPreferences.getInstance().then((prefs) {
    prefs.setBool('crashed', true);
  });
}
```

---

## 3. Provider 设计

### 3.1 MessageListProvider

```dart
// lib/features/messaging/presentation/providers/message_list_provider.dart

@riverpod
class MessageList extends _$MessageList {
  StreamSubscription<AcpMessage>? _streamSubscription;
  
  @override
  Future<List<Message>> build(String sessionId) async {
    final repo = ref.watch(messageRepositoryProvider);
    final messages = await repo.getMessages(sessionId);
    
    // 订阅消息流
    _subscribeToMessageStream(sessionId);
    
    return messages;
  }
  
  /// 订阅消息流
  void _subscribeToMessageStream(String sessionId) {
    final connectionId = ref.read(activeConnectionIdProvider);
    if (connectionId == null) return;
    
    _streamSubscription = ref.read(
      messageStreamProvider(connectionId)
    ).listen((message) {
      if (message is AcpEvent && message.event == 'message') {
        _handleIncomingMessage(message);
      }
    });
    
    ref.onDispose(() {
      _streamSubscription?.cancel();
    });
  }
  
  /// 处理收到的消息
  void _handleIncomingMessage(AcpEvent event) {
    final payload = event.payload;
    final eventId = payload['id'] as String?;
    
    if (eventId == null) return;
    
    final current = state.valueOrNull ?? [];
    
    // 查找是否已有该消息 (流式更新)
    final existingIndex = current.indexWhere((m) => m.id == eventId);
    
    if (existingIndex >= 0) {
      // 更新现有消息
      final updated = [...current];
      updated[existingIndex] = _mergeMessageContent(
        updated[existingIndex],
        payload,
      );
      state = AsyncData(updated);
    } else {
      // 添加新消息
      final newMessage = Message.fromJson(payload);
      state = AsyncData([...current, newMessage]);
    }
  }
  
  /// 合并消息内容 (流式更新)
  Message _mergeMessageContent(Message existing, Map<String, dynamic> payload) {
    final newContent = payload['content'] as List<dynamic>?;
    
    if (newContent == null) return existing;
    
    // 合并文本内容
    final existingText = existing.textContent;
    final newText = newContent
        .whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String)
        .join();
    
    if (newText.startsWith(existingText)) {
      // 追加内容
      return existing.copyWith(
        content: [TextContent(text: newText)],
      );
    }
    
    // 替换内容
    return existing.copyWith(
      content: newContent
          .map((c) => ContentBlock.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
  
  /// 发送消息
  Future<void> sendMessage({
    required String text,
    List<ImageContent> images = const [],
    AudioContent? voice,
  }) async {
    final connectionId = ref.read(activeConnectionIdProvider);
    final activeId = ref.read(activeConnectionIdProvider);
    
    if (connectionId == null || activeId == null) {
      throw NoActiveConnectionException();
    }
    
    // 构建消息内容
    final content = <ContentBlock>[
      if (text.isNotEmpty) TextContent(text: text),
      ...images,
      if (voice != null) voice,
    ];
    
    final message = Message(
      id: const Uuid().v4(),
      sessionId: sessionId,
      connectionId: connectionId,
      role: MessageRole.user,
      content: content,
      status: MessageStatus.sending,
      createdAt: DateTime.now(),
    );
    
    // 乐观更新
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, message]);
    
    try {
      // 保存到本地
      final repo = ref.read(messageRepositoryProvider);
      await repo.save(message);
      
      // 发送到服务器
      final request = createPromptRequest(
        sessionId: sessionId,
        text: text,
        attachments: _buildAttachments(images, voice),
      );
      
      await ref.read(connectionManagerNotifierProvider.notifier).send(request);
      
      // 更新状态为已发送
      final updated = [...state.valueOrNull ?? []];
      final index = updated.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        updated[index] = message.copyWith(
          status: MessageStatus.sent,
          sentAt: DateTime.now(),
        );
        state = AsyncData(updated);
      }
    } catch (e) {
      // 回滚乐观更新
      final updated = [...state.valueOrNull ?? []];
      final index = updated.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        updated[index] = message.copyWith(
          status: MessageStatus.failed,
          error: e.toString(),
        );
        state = AsyncData(updated);
      }
      rethrow;
    }
  }
  
  /// 加载更多历史消息
  Future<void> loadMore() async {
    final current = state.valueOrNull ?? [];
    if (current.isEmpty) return;
    
    final repo = ref.read(messageRepositoryProvider);
    final more = await repo.getMessages(
      sessionId,
      beforeId: current.first.id,
    );
    
    if (more.isNotEmpty) {
      state = AsyncData([...more, ...current]);
    }
  }
  
  /// 重试发送失败的消息
  Future<void> retryMessage(String messageId) async {
    final current = state.valueOrNull ?? [];
    final index = current.indexWhere((m) => m.id == messageId);
    
    if (index < 0) return;
    
    final message = current[index];
    if (message.status != MessageStatus.failed) return;
    
    // 重置状态为发送中
    final updated = [...current];
    updated[index] = message.copyWith(status: MessageStatus.sending);
    state = AsyncData(updated);
    
    try {
      // 重新发送
      await sendMessage(
        text: message.textContent,
        images: message.imageContent,
        voice: message.audioContent.firstOrNull,
      );
    } catch (_) {
      // 保持失败状态
    }
  }
  
  List<Attachment> _buildAttachments(
    List<ImageContent> images,
    AudioContent? voice,
  ) {
    return [
      ...images.map((img) => ImageAttachment(
        mimeType: img.mimeType,
        data: img.data,
        width: img.width,
        height: img.height,
      )),
      if (voice != null) AudioAttachment(
        mimeType: voice.mimeType,
        data: voice.data,
        duration: voice.duration,
      ),
    ];
  }
}
```

### 3.2 MessageStreamProvider

```dart
// lib/features/messaging/presentation/providers/message_stream_provider.dart

/// 消息流 Provider
@riverpod
Stream<AcpMessage> messageStream(MessageStreamRef ref, String connectionId) {
  final managerState = ref.watch(connectionManagerNotifierProvider);
  
  if (!managerState.isConnected) {
    return Stream.empty();
  }
  
  // 获取 ConnectionManager 的消息流
  return ref.read(connectionManagerNotifierProvider.notifier)._manager.messageStream;
}

/// 流式消息状态
@riverpod
class StreamingMessage extends _$StreamingMessage {
  @override
  StreamingState build(String messageId) {
    return StreamingState.idle();
  }
  
  /// 开始流式接收
  void startStreaming() {
    state = StreamingState.streaming('', DateTime.now());
  }
  
  /// 追加内容
  void appendContent(String content) {
    if (state.status != StreamingStatus.streaming) return;
    
    state = StreamingState.streaming(
      state.content + content,
      state.startTime!,
    );
  }
  
  /// 完成流式接收
  void complete() {
    if (state.status != StreamingStatus.streaming) return;
    
    state = StreamingState.completed(state.content);
  }
  
  /// 错误
  void error(String error) {
    state = StreamingState.error(error);
  }
}

enum StreamingStatus {
  idle,
  streaming,
  completed,
  error,
}

class StreamingState {
  final StreamingStatus status;
  final String content;
  final DateTime? startTime;
  final String? error;
  
  const StreamingState._({
    required this.status,
    this.content = '',
    this.startTime,
    this.error,
  });
  
  static StreamingState idle() => const StreamingState._(status: StreamingStatus.idle);
  
  static StreamingState streaming(String content, DateTime startTime) => StreamingState._(
    status: StreamingStatus.streaming,
    content: content,
    startTime: startTime,
  );
  
  static StreamingState completed(String content) => StreamingState._(
    status: StreamingStatus.completed,
    content: content,
  );
  
  static StreamingState error(String error) => StreamingState._(
    status: StreamingStatus.error,
    error: error,
  );
  
  bool get isStreaming => status == StreamingStatus.streaming;
  bool get isCompleted => status == StreamingStatus.completed;
}
```

### 3.3 DraftProvider

```dart
// lib/features/messaging/presentation/providers/draft_provider.dart

/// 草稿 Provider
@riverpod
class Draft extends _$Draft {
  Timer? _saveTimer;
  
  @override
  DraftState build(String sessionId) {
    _loadDraft();
    
    ref.onDispose(() {
      _saveTimer?.cancel();
      _saveDraft();
    });
    
    return DraftState.empty();
  }
  
  /// 从存储加载草稿
  Future<void> _loadDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = '${StorageKeys.draftPrefix}$sessionId';
    final json = prefs.getString(key);
    
    if (json != null) {
      final data = jsonDecode(json) as Map<String, dynamic>;
      state = DraftState.fromJson(data);
    }
  }
  
  /// 保存草稿到存储
  Future<void> _saveDraft() async {
    if (state.isEmpty) return;
    
    final prefs = ref.read(sharedPreferencesProvider);
    final key = '${StorageKeys.draftPrefix}$sessionId';
    await prefs.setString(key, jsonEncode(state.toJson()));
  }
  
  /// 更新文本
  void updateText(String text) {
    state = state.copyWith(text: text, updatedAt: DateTime.now());
    _scheduleSave();
  }
  
  /// 添加图片
  void addImage(ImageContent image) {
    state = state.copyWith(
      images: [...state.images, image],
      updatedAt: DateTime.now(),
    );
    _scheduleSave();
  }
  
  /// 移除图片
  void removeImage(int index) {
    final images = [...state.images]..removeAt(index);
    state = state.copyWith(images: images, updatedAt: DateTime.now());
    _scheduleSave();
  }
  
  /// 设置语音
  void setVoice(AudioContent voice) {
    state = state.copyWith(voice: voice, updatedAt: DateTime.now());
    _scheduleSave();
  }
  
  /// 清除语音
  void clearVoice() {
    state = state.copyWith(voice: null, updatedAt: DateTime.now());
    _scheduleSave();
  }
  
  /// 清除草稿
  Future<void> clear() async {
    state = DraftState.empty();
    
    final prefs = ref.read(sharedPreferencesProvider);
    final key = '${StorageKeys.draftPrefix}$sessionId';
    await prefs.remove(key);
  }
  
  /// 调度保存 (防抖)
  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }
}

/// 草稿状态
class DraftState {
  final String text;
  final List<ImageContent> images;
  final AudioContent? voice;
  final DateTime? updatedAt;
  
  const DraftState({
    required this.text,
    required this.images,
    this.voice,
    this.updatedAt,
  });
  
  static DraftState empty() => const DraftState(text: '', images: []);
  
  bool get isEmpty => text.isEmpty && images.isEmpty && voice == null;
  bool get isNotEmpty => !isEmpty;
  
  DraftState copyWith({
    String? text,
    List<ImageContent>? images,
    AudioContent? voice,
    DateTime? updatedAt,
    bool clearVoice = false,
  }) {
    return DraftState(
      text: text ?? this.text,
      images: images ?? this.images,
      voice: clearVoice ? null : (voice ?? this.voice),
      updatedAt: updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'text': text,
    'images': images.map((i) => i.toJson()).toList(),
    if (voice != null) 'voice': voice!.toJson(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
  
  factory DraftState.fromJson(Map<String, dynamic> json) => DraftState(
    text: json['text'] as String? ?? '',
    images: (json['images'] as List<dynamic>?)
        ?.map((i) => ImageContent.fromJson(i as Map<String, dynamic>))
        .toList() ?? [],
    voice: json['voice'] != null
        ? AudioContent.fromJson(json['voice'] as Map<String, dynamic>)
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : null,
  );
}
```

---

## 4. Widget 设计

### 4.1 MessageBubble

```
用户消息:

┌─────────────────────────────────────┐
│                                     │
│  Hello, this is my message          │
│                                     │
└─────────────────────────────────────┘
                           ✓✓ 10:30

助手消息:

┌─────────────────────────────────────┐
│                                     │
│  Hello! How can I help you?         │
│                                     │
└─────────────────────────────────────┘

流式消息:

┌─────────────────────────────────────┐
│                                     │
│  I'm processing your request...|    │ ← 闪烁光标
│                                     │
└─────────────────────────────────────┘

带图片消息:

┌─────────────────────────────────────┐
│  ┌───────────┐                      │
│  │   Image   │                      │
│  └───────────┘                      │
│  Check out this image!              │
└─────────────────────────────────────┘
                           ✓  10:31
```

```dart
// lib/features/messaging/presentation/widgets/message_bubble.dart

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isStreaming;
  
  const MessageBubble({
    required this.message,
    this.isStreaming = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: isUser 
              ? CupertinoColors.activeBlue 
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图片内容
            if (message.imageContent.isNotEmpty)
              _ImageGrid(images: message.imageContent),
            
            // 音频内容
            if (message.audioContent.isNotEmpty)
              _AudioPlayer(audio: message.audioContent.first),
            
            // 文本内容
            if (message.textContent.isNotEmpty)
              isStreaming && !isUser
                  ? _StreamingText(text: message.textContent)
                  : Text(
                      message.textContent,
                      style: TextStyle(
                        color: isUser ? CupertinoColors.white : CupertinoColors.label,
                      ),
                    ),
            
            // 状态和时间
            if (isUser) _buildStatusAndTime(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusAndTime() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.status == MessageStatus.sending)
            const CupertinoActivityIndicator(radius: 6)
          else if (message.status == MessageStatus.failed)
            Icon(CupertinoIcons.exclamationmark_circle, 
                 color: CupertinoColors.systemRed, size: 14)
          else
            Icon(CupertinoIcons.checkmark_checkmark, 
                 color: CupertinoColors.white.withValues(alpha: 0.7), size: 14),
          
          if (message.sentAt != null) ...[
            const SizedBox(width: 4),
            Text(
              _formatTime(message.sentAt!),
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 4.2 StreamingText

```dart
// lib/features/messaging/presentation/widgets/streaming_text.dart

class StreamingText extends StatefulWidget {
  final String text;
  final Duration typingSpeed;
  
  const StreamingText({
    required this.text,
    this.typingSpeed = const Duration(milliseconds: 10),
  });
  
  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _timer;
  
  @override
  void initState() {
    super.initState();
    _startTyping();
  }
  
  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.text.length > oldWidget.text.length) {
      // 新内容追加，继续打字
      _startTyping();
    }
  }
  
  void _startTyping() {
    _timer?.cancel();
    
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _displayedText,
            style: AppTextStyles.body,
          ),
        ),
        // 闪烁光标
        if (_charIndex < widget.text.length || widget.text.isEmpty)
          _BlinkingCursor(),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 16,
        color: CupertinoColors.label,
      ),
    );
  }
}
```

### 4.3 ChatScreen

```
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
│  ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░ (流式输出中)                    │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 输入消息...                          📷 │ 🎤 │ ➤ │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 4.4 DraftIndicator

```
有草稿时显示:

┌─────────────────────────────────────────────────────────┐
│ 📝 草稿: Hello, I was typing...                  [清除] │
└─────────────────────────────────────────────────────────┘
```

---

## 5. 测试用例

### 5.1 Provider 测试

```dart
// test/features/messaging/providers/message_list_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockMessageRepository extends Mock implements MessageRepository {}
class MockConnectionManager extends Mock implements ConnectionManager {}

void main() {
  group('MessageListProvider', () {
    late ProviderContainer container;
    late MockMessageRepository mockRepo;
    
    setUp(() {
      mockRepo = MockMessageRepository();
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
    
    test('sendMessage 应乐观更新列表', () async {
      // arrange
      when(() => mockRepo.getMessages(any(), limit: anyNamed('limit')))
          .thenAnswer((_) async => []);
      when(() => mockRepo.save(any()))
          .thenAnswer((_) async {});
      
      // 初始化
      await container.read(messageListProvider('s1').future);
      
      // act
      await container.read(messageListProvider('s1').notifier).sendMessage(
        text: 'Test message',
      );
      
      // assert
      final result = container.read(messageListProvider('s1')).valueOrNull;
      expect(result?.length, equals(1));
      expect(result?[0].textContent, equals('Test message'));
      expect(result?[0].status, equals(MessageStatus.sent));
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
      
      // 初始化
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

### 5.2 Draft Provider 测试

```dart
// test/features/messaging/providers/draft_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('DraftProvider', () {
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
    
    test('初始状态应为空', () {
      // act
      final draft = container.read(draftProvider('s1'));
      
      // assert
      expect(draft.isEmpty, isTrue);
    });
    
    test('updateText 应更新文本并调度保存', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      container.read(draftProvider('s1').notifier).updateText('Hello');
      
      // 等待防抖
      await Future.delayed(Duration(milliseconds: 600));
      
      // assert
      final draft = container.read(draftProvider('s1'));
      expect(draft.text, equals('Hello'));
      verify(() => mockPrefs.setString(any(), any())).called(1);
    });
    
    test('clear 应清除草稿', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      
      container.read(draftProvider('s1').notifier).updateText('Test');
      await Future.delayed(Duration(milliseconds: 100));
      
      // act
      await container.read(draftProvider('s1').notifier).clear();
      
      // assert
      final draft = container.read(draftProvider('s1'));
      expect(draft.isEmpty, isTrue);
      verify(() => mockPrefs.remove(any())).called(1);
    });
  });
}
```

### 5.3 Widget 测试

```dart
// test/features/messaging/widgets/message_bubble_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  group('MessageBubble', () {
    testWidgets('应显示用户消息', (tester) async {
      // arrange
      final message = Message(
        id: 'm1',
        sessionId: 's1',
        connectionId: 'c1',
        role: MessageRole.user,
        content: [TextContent(text: 'Hello, World!')],
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessageBubble(message: message),
        ),
      ));
      
      // assert
      expect(find.text('Hello, World!'), findsOneWidget);
    });
    
    testWidgets('应显示助手消息', (tester) async {
      // arrange
      final message = Message(
        id: 'm1',
        sessionId: 's1',
        connectionId: 'c1',
        role: MessageRole.assistant,
        content: [TextContent(text: 'Hi there!')],
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessageBubble(message: message),
        ),
      ));
      
      // assert
      expect(find.text('Hi there!'), findsOneWidget);
    });
    
    testWidgets('发送失败应显示错误图标', (tester) async {
      // arrange
      final message = Message(
        id: 'm1',
        sessionId: 's1',
        connectionId: 'c1',
        role: MessageRole.user,
        content: [TextContent(text: 'Failed message')],
        status: MessageStatus.failed,
        error: 'Connection lost',
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: MessageBubble(message: message),
        ),
      ));
      
      // assert
      expect(find.byIcon(CupertinoIcons.exclamationmark_circle), findsOneWidget);
    });
  });
}
```

### 5.4 Repository 测试

```dart
// test/features/messaging/data/repositories/message_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('MessageRepositoryImpl', () {
    late MessageRepositoryImpl repository;
    late MockSharedPreferences mockPrefs;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      repository = MessageRepositoryImpl(prefs: mockPrefs);
    });
    
    test('getMessages 应返回会话消息', () async {
      // arrange
      final messages = [
        Message(
          id: 'm1',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'Test')],
          createdAt: DateTime.now(),
        ).toJson(),
      ];
      
      when(() => mockPrefs.getString('clawtalk_messages_s1'))
          .thenReturn(jsonEncode(messages));
      
      // act
      final result = await repository.getMessages('s1');
      
      // assert
      expect(result.length, equals(1));
      expect(result[0].textContent, equals('Test'));
    });
    
    test('save 应保存消息', () async {
      // arrange
      final message = Message(
        id: 'm1',
        sessionId: 's1',
        connectionId: 'c1',
        role: MessageRole.user,
        content: [TextContent(text: 'Test')],
        createdAt: DateTime.now(),
      );
      
      when(() => mockPrefs.getString(any())).thenReturn(null);
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await repository.save(message);
      
      // assert
      verify(() => mockPrefs.setString(any(), any())).called(1);
    });
    
    test('search 应返回匹配的消息', () async {
      // arrange
      final messages = [
        Message(
          id: 'm1',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'Hello World')],
          createdAt: DateTime.now(),
        ).toJson(),
        Message(
          id: 'm2',
          sessionId: 's1',
          connectionId: 'c1',
          role: MessageRole.user,
          content: [TextContent(text: 'Goodbye')],
          createdAt: DateTime.now(),
        ).toJson(),
      ];
      
      when(() => mockPrefs.getString(any()))
          .thenReturn(jsonEncode(messages));
      
      // act
      final result = await repository.search('Hello', 'c1');
      
      // assert
      expect(result.length, equals(1));
      expect(result[0].textContent, contains('Hello'));
    });
  });
}
```

---

## 6. Markdown 渲染设计

### 6.1 Markdown 组件架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Markdown 渲染架构                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                 MessageBubble                        │   │
│  │  判断内容类型，选择渲染器                              │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │                             │
│           ┌──────────────────┼──────────────────┐          │
│           │                  │                  │          │
│           ▼                  ▼                  ▼          │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐   │
│  │ PlainText   │     │MarkdownText │     │ CodeBlock   │   │
│  │ (普通文本)  │     │ (Markdown)  │     │ (代码块)    │   │
│  └─────────────┘     └──────┬──────┘     └──────┬──────┘   │
│                              │                    │          │
│                              ▼                    ▼          │
│                       ┌─────────────┐     ┌─────────────┐   │
│                       │flutter_markdown│   │   highlight  │   │
│                       └─────────────┘     └─────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 MarkdownText Widget

```dart
// lib/features/messaging/presentation/widgets/markdown_text.dart

class MarkdownText extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  
  const MarkdownText({
    required this.text,
    this.isDarkMode = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
      styleSheet: _buildStyleSheet(context),
      builders: {
        'code': CodeElementBuilder(isDarkMode: isDarkMode),
        'pre': PreElementBuilder(isDarkMode: isDarkMode),
      },
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
  }
  
  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final baseStyle = CupertinoTheme.of(context).textTheme.textStyle;
    
    return MarkdownStyleSheet(
      p: baseStyle.copyWith(height: 1.5),
      h1: baseStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold),
      h2: baseStyle.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
      h3: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      code: baseStyle.copyWith(
        fontFamily: 'SF Mono',
        fontSize: 14,
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      blockquote: baseStyle.copyWith(
        color: CupertinoColors.systemGrey,
        fontStyle: FontStyle.italic,
      ),
      tableHead: baseStyle.copyWith(fontWeight: FontWeight.w600),
      tableBody: baseStyle,
      listBullet: baseStyle,
    );
  }
}
```

### 6.3 CodeBlock Widget (代码高亮)

```dart
// lib/features/messaging/presentation/widgets/code_block.dart

class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;
  final bool isDarkMode;
  
  const CodeBlock({
    required this.code,
    this.language,
    this.isDarkMode = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.black.withOpacity(0.8)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 语言标签和复制按钮
          if (language != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? CupertinoColors.black
                    : CupertinoColors.systemGrey5,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Text(
                    language!,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _copyCode(context),
                    child: Icon(
                      CupertinoIcons.doc_on_doc,
                      size: 16,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
          
          // 代码内容
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.all(12),
              child: _buildHighlightedCode(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHighlightedCode() {
    return HighlightView(
      code,
      language: language ?? 'plaintext',
      theme: isDarkMode ? _darkTheme : _lightTheme,
      padding: EdgeInsets.zero,
      textStyle: const TextStyle(
        fontFamily: 'SF Mono',
        fontSize: 14,
      ),
    );
  }
  
  static final _lightTheme = {
    'root': TextStyle(backgroundColor: CupertinoColors.systemGrey6.color),
    'keyword': TextStyle(color: CupertinoColors.activeBlue),
    'string': TextStyle(color: CupertinoColors.activeGreen),
    'comment': TextStyle(color: CupertinoColors.systemGrey),
    'number': TextStyle(color: CupertinoColors.activeOrange),
  };
  
  static final _darkTheme = {
    'root': TextStyle(backgroundColor: CupertinoColors.black.color),
    'keyword': TextStyle(color: CupertinoColors.activeBlue.darkColor),
    'string': TextStyle(color: CupertinoColors.activeGreen.darkColor),
    'comment': TextStyle(color: CupertinoColors.systemGrey.darkColor),
    'number': TextStyle(color: CupertinoColors.activeOrange.darkColor),
  };
  
  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('代码已复制')),
    );
  }
}
```

### 6.4 支持的 Markdown 特性

| 特性 | 支持 | 说明 |
|------|:----:|------|
| 标题 (H1-H6) | ✓ | 完整支持 |
| 粗体/斜体 | ✓ | **bold**, *italic* |
| 删除线 | ✓ | ~~strikethrough~~ |
| 链接 | ✓ | [text](url) |
| 图片 | ✓ | ![alt](url) |
| 列表 (有序/无序) | ✓ | 1. / - |
| 代码 (行内) | ✓ | `code` |
| 代码块 | ✓ | ```language |
| 引用 | ✓ | > quote |
| 表格 | ✓ | GFM tables |
| 任务列表 | ✓ | - [ ] task |

### 6.5 支持的代码高亮语言

| 类别 | 语言 |
|------|------|
| 常用 | JavaScript, TypeScript, Python, Java, C, C++, Go, Rust |
| 前端 | HTML, CSS, SCSS, JSON, YAML |
| Shell | Bash, Shell, PowerShell |
| 其他 | SQL, Markdown, Dockerfile |

---

## 7. 会话恢复设计

### 7.1 崩溃恢复流程

```
┌─────────────────────────────────────────────────────────────┐
│                    崩溃恢复流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  App 启动                                                   │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │CrashRecoveryService                                       │
│  │ 检查是否有未发送消息                                      │
│  └────────┬────────┘                                        │
│           │                                                 │
│     ┌─────┴─────┐                                           │
│     │           │                                           │
│    有          无                                           │
│     │           │                                           │
│     ▼           ▼                                           │
│  ┌─────────┐  ┌─────────┐                                    │
│  │ 显示    │  │ 正常    │                                    │
│  │ 恢复UI  │  │ 启动    │                                    │
│  └────┬────┘  └─────────┘                                    │
│       │                                                     │
│       │ 用户确认/忽略                                        │
│       ▼                                                     │
│  ┌─────────────────┐                                        │
│  │DraftRecoveryProvider                                      │
│  │ 恢复草稿内容                                              │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 7.2 CrashRecoveryService

```dart
// lib/features/messaging/data/services/crash_recovery_service.dart

class CrashRecoveryService {
  static const String _pendingMessagesKey = 'clawtalk_pending_messages';
  static const String _crashFlagKey = 'clawtalk_crash_flag';
  
  final SharedPreferences _prefs;
  
  CrashRecoveryService({required SharedPreferences prefs}) : _prefs = prefs;
  
  /// 设置崩溃标志 (App 启动时清除，异常退出时保留)
  Future<void> setCrashFlag() async {
    await _prefs.setBool(_crashFlagKey, true);
  }
  
  /// 清除崩溃标志 (App 正常退出时调用)
  Future<void> clearCrashFlag() async {
    await _prefs.setBool(_crashFlagKey, false);
  }
  
  /// 检查是否需要恢复
  bool needsRecovery() {
    return _prefs.getBool(_crashFlagKey) ?? false;
  }
  
  /// 保存待发送消息
  Future<void> savePendingMessage(PendingMessage message) async {
    final messages = await getPendingMessages();
    messages.add(message);
    
    await _prefs.setString(
      _pendingMessagesKey,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }
  
  /// 获取待发送消息
  Future<List<PendingMessage>> getPendingMessages() async {
    final json = _prefs.getString(_pendingMessagesKey);
    if (json == null) return [];
    
    final List<dynamic> list = jsonDecode(json);
    return list.map((e) => PendingMessage.fromJson(e)).toList();
  }
  
  /// 清除待发送消息
  Future<void> clearPendingMessages() async {
    await _prefs.remove(_pendingMessagesKey);
  }
}

/// 待发送消息
class PendingMessage {
  final String id;
  final String sessionId;
  final String connectionId;
  final String text;
  final List<String> imagePaths;
  final String? audioPath;
  final DateTime createdAt;
  
  const PendingMessage({
    required this.id,
    required this.sessionId,
    required this.connectionId,
    required this.text,
    this.imagePaths = const [],
    this.audioPath,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'connectionId': connectionId,
    'text': text,
    'imagePaths': imagePaths,
    'audioPath': audioPath,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory PendingMessage.fromJson(Map<String, dynamic> json) => PendingMessage(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    connectionId: json['connectionId'] as String,
    text: json['text'] as String,
    imagePaths: (json['imagePaths'] as List<dynamic>?)?.cast<String>() ?? [],
    audioPath: json['audioPath'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
  );
}
```

### 7.3 DraftRecoveryProvider

```dart
// lib/features/messaging/presentation/providers/draft_recovery_provider.dart

@riverpod
class DraftRecovery extends _$DraftRecovery {
  @override
  RecoveryState build() => RecoveryState.idle();
  
  /// 检查并恢复
  Future<void> checkAndRecover() async {
    final service = ref.read(crashRecoveryServiceProvider);
    
    if (!service.needsRecovery()) {
      state = RecoveryState.noRecoveryNeeded();
      return;
    }
    
    final pendingMessages = await service.getPendingMessages();
    
    if (pendingMessages.isEmpty) {
      state = RecoveryState.noRecoveryNeeded();
      await service.clearCrashFlag();
      return;
    }
    
    state = RecoveryState.hasRecovery(pendingMessages: pendingMessages);
  }
  
  /// 确认恢复
  Future<void> confirmRecovery() async {
    final messages = state.pendingMessages;
    if (messages == null || messages.isEmpty) return;
    
    final firstMessage = messages.first;
    final draftNotifier = ref.read(draftProvider(firstMessage.sessionId).notifier);
    
    draftNotifier.updateText(firstMessage.text);
    
    for (final path in firstMessage.imagePaths) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        draftNotifier.addImage(ImageContent(
          mimeType: _getMimeType(path),
          data: base64Encode(bytes),
        ));
      }
    }
    
    if (firstMessage.audioPath != null) {
      final file = File(firstMessage.audioPath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        draftNotifier.setVoice(AudioContent(
          mimeType: 'audio/mp4',
          data: base64Encode(bytes),
        ));
      }
    }
    
    final service = ref.read(crashRecoveryServiceProvider);
    await service.clearPendingMessages();
    await service.clearCrashFlag();
    
    state = RecoveryState.recovered();
  }
  
  /// 忽略恢复
  Future<void> ignoreRecovery() async {
    final service = ref.read(crashRecoveryServiceProvider);
    await service.clearPendingMessages();
    await service.clearCrashFlag();
    state = RecoveryState.ignored();
  }
  
  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}

enum RecoveryStatus { idle, noRecoveryNeeded, hasRecovery, recovered, ignored }

class RecoveryState {
  final RecoveryStatus status;
  final List<PendingMessage>? pendingMessages;
  
  const RecoveryState._({required this.status, this.pendingMessages});
  
  static RecoveryState idle() => const RecoveryState._(status: RecoveryStatus.idle);
  static RecoveryState noRecoveryNeeded() => const RecoveryState._(status: RecoveryStatus.noRecoveryNeeded);
  static RecoveryState hasRecovery({required List<PendingMessage> pendingMessages}) => 
      RecoveryState._(status: RecoveryStatus.hasRecovery, pendingMessages: pendingMessages);
  static RecoveryState recovered() => const RecoveryState._(status: RecoveryStatus.recovered);
  static RecoveryState ignored() => const RecoveryState._(status: RecoveryStatus.ignored);
  
  bool get hasPendingMessages => status == RecoveryStatus.hasRecovery && (pendingMessages?.isNotEmpty ?? false);
}
```

---

## 8. 消息状态增强设计

### 8.1 完整消息状态 UI

```
消息状态指示器:

发送中:  ⏳ 转圈动画
已发送:  ✓ 单勾 (灰色)
已送达:  ✓✓ 双勾 (灰色)
已读:    ✓✓ 双勾 (蓝色)
失败:    ⚠ 感叹号 (红色) + 点击重试
```

### 8.2 MessageStatusIndicator Widget

```dart
class MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final VoidCallback? onRetry;
  
  const MessageStatusIndicator({required this.status, this.onRetry});
  
  @override
  Widget build(BuildContext context) {
    return switch (status) {
      MessageStatus.sending => const SizedBox(
        width: 14, height: 14,
        child: CupertinoActivityIndicator(radius: 6),
      ),
      MessageStatus.sent => const Icon(CupertinoIcons.checkmark, size: 14, color: CupertinoColors.systemGrey),
      MessageStatus.delivered => const Icon(CupertinoIcons.checkmark_checkmark, size: 14, color: CupertinoColors.systemGrey),
      MessageStatus.read => const Icon(CupertinoIcons.checkmark_checkmark, size: 14, color: CupertinoColors.activeBlue),
      MessageStatus.failed => GestureDetector(
        onTap: onRetry,
        child: const Icon(CupertinoIcons.exclamationmark_circle, size: 14, color: CupertinoColors.systemRed),
      ),
    };
  }
}
```

---

## 9. 附录

### 9.1 Provider 速查表

| Provider | 类型 | 用途 |
|----------|------|------|
| `messageListProvider` | AsyncNotifier | 消息列表 |
| `messageStreamProvider` | Stream | 消息流 |
| `streamingMessageProvider` | StateNotifier | 流式消息状态 |
| `draftProvider` | StateNotifier | 草稿管理 |

### 6.2 消息状态速查表

| 状态 | 值 | 说明 |
|------|------|------|
| `sending` | 0 | 发送中 |
| `sent` | 1 | 已发送 |
| `delivered` | 2 | 已送达 |
| `read` | 3 | 已读 |
| `failed` | 4 | 发送失败 |

### 6.3 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**