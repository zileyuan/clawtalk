# ClawTalk API 设计规范

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md)

---

## 目录

1. [概述](#1-概述)
2. [连接层设计](#2-连接层设计)
3. [消息层设计](#3-消息层设计)
4. [事件处理设计](#4-事件处理设计)
5. [错误处理设计](#5-错误处理设计)
6. [测试用例](#6-测试用例)
7. [附录](#7-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端与 OpenClaw Gateway 之间的 API 接口规范，包括：
- WebSocket 连接管理
- ACP 协议消息格式
- 事件处理机制
- 错误处理策略

### 1.2 范围

```
┌─────────────────────────────────────────────────────────────┐
│                      API 层次结构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   应用层 (Application)               │   │
│  │  ConnectionManager, MessageService, SessionService  │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   API 层 (API Layer)                 │   │
│  │  AcpClient, MessageCodec, EventHandler              │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   传输层 (Transport)                 │   │
│  │  WebSocketClient, TLS Handler, Heartbeat            │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              OpenClaw Gateway (远程服务)             │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.3 依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `web_socket_channel` | ^3.0.0 | WebSocket 通信 |
| `dart:convert` | SDK | JSON 编解码 |

---

## 2. 连接层设计

### 2.1 连接配置

```dart
/// 连接配置
class ConnectionConfig {
  /// 唯一标识
  final String id;
  
  /// 连接名称
  final String name;
  
  /// Gateway 主机地址
  final String host;
  
  /// Gateway 端口 (默认 18789)
  final int port;
  
  /// 是否使用 TLS
  final bool useTls;
  
  /// 认证令牌
  final String? token;
  
  /// 认证密码
  final String? password;
  
  /// 默认会话键
  final String? defaultSessionKey;
  
  /// 标签列表
  final List<String> tags;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 最后连接时间
  final DateTime? lastConnectedAt;
  
  /// 是否启用自动重连
  final bool autoReconnect;
  
  /// 连接超时 (毫秒)
  final int connectionTimeout;
  
  /// 获取 WebSocket URL
  String get wsUrl {
    final scheme = useTls ? 'wss' : 'ws';
    return '$scheme://$host:$port';
  }
}
```

### 2.2 连接状态

```dart
/// 连接状态枚举
enum ConnectionStatus {
  /// 已断开
  disconnected,
  
  /// 连接中
  connecting,
  
  /// 已连接 (WebSocket 已建立)
  connected,
  
  /// 认证中
  authenticating,
  
  /// 已认证 (可以发送消息)
  authenticated,
  
  /// 错误状态
  error,
  
  /// 重连中
  reconnecting,
}
```

### 2.3 连接管理器接口

```dart
/// 连接管理器接口
abstract class ConnectionManager {
  /// 当前连接状态
  ConnectionStatus get status;
  
  /// 状态变化流
  Stream<ConnectionStatus> get statusStream;
  
  /// 当前活跃连接 ID
  String? get activeConnectionId;
  
  /// 连接
  Future<void> connect(String connectionId);
  
  /// 断开连接
  Future<void> disconnect();
  
  /// 发送消息
  Future<void> send(AcpMessage message);
  
  /// 接收消息流
  Stream<AcpMessage> get messageStream;
  
  /// 释放资源
  void dispose();
}
```

### 2.4 连接状态机

```
                    ┌──────────────────────────────────────┐
                    │                                      │
                    ▼                                      │
┌─────────────┐  connect   ┌─────────────┐               │
│             │ ─────────► │             │               │
│ Disconnected│            │ Connecting  │               │
│             │ ◄───────── │             │               │
└──────┬──────┘  cancel    └──────┬──────┘               │
       │                           │                       │
       │                    ┌──────┴──────┐                │
       │                    │             │                │
       │              success │           │ error          │
       │                    ▼             ▼                │
       │             ┌─────────────┐ ┌─────────────┐       │
       │             │  Connected  │ │   Error     │       │
       │             └──────┬──────┘ └──────┬──────┘       │
       │                    │               │               │
       │             auth request    retry/reconnect       │
       │                    │               │               │
       │                    ▼               └───────────────┤
       │             ┌─────────────┐                        │
       │             │Authenticating│                       │
       │             └──────┬──────┘                        │
       │                    │                               │
       │             ┌──────┴──────┐                        │
       │        success │           │ failed                 │
       │             ▼             ▼                        │
       │      ┌─────────────┐ ┌─────────────┐               │
       │      │Authenticated│ │   Error     │               │
       │      └──────┬──────┘ └──────────────┘               │
       │             │                                       │
       │      disconnect                                     │
       │             │                                       │
       └─────────────┘                                       │
                                                              
```

### 2.5 认证流程

```
┌──────────┐                    ┌──────────────┐                    
│  Client  │                    │   Gateway    │                    
└────┬─────┘                    └──────┬───────┘                    
     │                                 │                            
     │  1. WebSocket Handshake         │                            
     │  (wss://host:18789)             │                            
     │ ────────────────────────────────►│                            
     │                                 │                            
     │  2. Connection Challenge        │                            
     │ ◄────────────────────────────────│                            
     │  { "type": "challenge", ... }    │                            
     │                                 │                            
     │  3. Connect Request             │                            
     │ ────────────────────────────────►│                            
     │  { "method": "connect",          │                            
     │    "auth": { "token": "xxx" } }  │                            
     │                                 │                            
     │  4. Connection Response         │                            
     │ ◄────────────────────────────────│                            
     │  { "ok": true, "protocol": 3 }   │                            
     │                                 │                            
     │                                 │                            
     │  5. Ready for Messages          │                            
     │ ════════════════════════════════│                            
     │                                 │                            
```

### 2.6 重连策略

```dart
/// 重连策略
class ReconnectStrategy {
  /// 初始延迟 (毫秒)
  static const int initialDelay = 1000;
  
  /// 最大延迟 (毫秒)
  static const int maxDelay = 30000;
  
  /// 最大重试次数 (0 = 无限)
  static const int maxRetries = 0;
  
  /// 计算下次重连延迟
  static int calculateDelay(int attempt) {
    final delay = initialDelay * (1 << attempt); // 指数退避
    return delay.clamp(initialDelay, maxDelay);
  }
}

/// 重连策略示例
///
/// 尝试次数 | 延迟
/// ---------|------
///    1     |  1s
///    2     |  2s
///    3     |  4s
///    4     |  8s
///    5     | 16s
///   6+     | 30s (最大)
```

---

## 3. 消息层设计

### 3.1 消息基础结构

```dart
/// ACP 消息基类
sealed class AcpMessage {
  /// 消息类型
  String get type;
  
  /// 转换为 JSON
  Map<String, dynamic> toJson();
  
  /// 从 JSON 解析
  factory AcpMessage.fromJson(Map<String, dynamic> json) {
    // 根据 type 分发到具体消息类型
    return switch (json['type']) {
      'req' => AcpRequest.fromJson(json),
      'res' => AcpResponse.fromJson(json),
      'event' => AcpEvent.fromJson(json),
      _ => throw AcpUnknownMessageTypeException(json['type']),
    };
  }
}
```

### 3.2 请求消息

```dart
/// ACP 请求消息
class AcpRequest extends AcpMessage {
  @override
  String get type => 'req';
  
  /// 请求 ID (用于匹配响应)
  final String id;
  
  /// 方法名
  final String method;
  
  /// 请求参数
  final Map<String, dynamic> params;
  
  AcpRequest({
    required this.id,
    required this.method,
    required this.params,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'method': method,
    'params': params,
  };
  
  factory AcpRequest.fromJson(Map<String, dynamic> json) => AcpRequest(
    id: json['id'] as String,
    method: json['method'] as String,
    params: json['params'] as Map<String, dynamic>,
  );
}
```

### 3.3 响应消息

```dart
/// ACP 响应消息
class AcpResponse extends AcpMessage {
  @override
  String get type => 'res';
  
  /// 对应的请求 ID
  final String id;
  
  /// 是否成功
  final bool ok;
  
  /// 响应数据 (ok=true 时)
  final Map<String, dynamic>? payload;
  
  /// 错误信息 (ok=false 时)
  final AcpError? error;
  
  AcpResponse({
    required this.id,
    required this.ok,
    this.payload,
    this.error,
  });
  
  bool get isSuccess => ok && error == null;
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'ok': ok,
    if (payload != null) 'payload': payload,
    if (error != null) 'error': error!.toJson(),
  };
  
  factory AcpResponse.fromJson(Map<String, dynamic> json) => AcpResponse(
    id: json['id'] as String,
    ok: json['ok'] as bool,
    payload: json['payload'] as Map<String, dynamic>?,
    error: json['error'] != null 
      ? AcpError.fromJson(json['error']) 
      : null,
  );
}
```

### 3.4 事件消息

```dart
/// ACP 事件消息 (服务端推送)
class AcpEvent extends AcpMessage {
  @override
  String get type => 'event';
  
  /// 事件名称
  final String event;
  
  /// 事件数据
  final Map<String, dynamic> payload;
  
  /// 序列号 (可选，用于有序事件)
  final int? seq;
  
  /// 状态版本 (可选，用于状态同步)
  final int? stateVersion;
  
  AcpEvent({
    required this.event,
    required this.payload,
    this.seq,
    this.stateVersion,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'event': event,
    'payload': payload,
    if (seq != null) 'seq': seq,
    if (stateVersion != null) 'stateVersion': stateVersion,
  };
  
  factory AcpEvent.fromJson(Map<String, dynamic> json) => AcpEvent(
    event: json['event'] as String,
    payload: json['payload'] as Map<String, dynamic>,
    seq: json['seq'] as int?,
    stateVersion: json['stateVersion'] as int?,
  );
}
```

### 3.5 消息编码器

```dart
/// 消息编解码器
class MessageCodec {
  /// 编码为 NDJSON (换行分隔 JSON)
  static String encode(AcpMessage message) {
    final json = message.toJson();
    return '${jsonEncode(json)}\n';
  }
  
  /// 解码 NDJSON
  static List<AcpMessage> decode(String ndjson) {
    return ndjson
        .split('\n')
        .where((line) => line.isNotEmpty)
        .map((line) => AcpMessage.fromJson(jsonDecode(line)))
        .toList();
  }
  
  /// 解码单条消息
  static AcpMessage decodeOne(String json) {
    return AcpMessage.fromJson(jsonDecode(json));
  }
}
```

### 3.6 核心方法定义

| 方法 | 说明 | 参数 |
|------|------|------|
| `initialize` | 初始化会话 | `clientInfo`, `capabilities` |
| `newSession` | 创建新会话 | `cwd`, `meta` |
| `prompt` | 发送提示 | `session_id`, `prompt` |
| `cancel` | 取消操作 | `session_id` |
| `listSessions` | 列出会话 | `_meta.limit` |
| `listAgents` | 获取 Agent 列表 | 无 |

### 3.7 初始化请求示例

```dart
/// 创建初始化请求
AcpRequest createInitializeRequest() {
  return AcpRequest(
    id: _generateId(),
    method: 'initialize',
    params: {
      'minProtocol': 3,
      'maxProtocol': 3,
      'clientInfo': {
        'id': 'clawtalk',
        'name': 'ClawTalk',
        'version': '1.0.0',
        'platform': Platform.operatingSystem,
        'mode': 'client',
      },
      'capabilities': {},
    },
  );
}
```

### 3.8 发送提示请求示例

```dart
/// 创建提示请求
AcpRequest createPromptRequest({
  required String sessionId,
  required String text,
  List<Attachment> attachments = const [],
}) {
  return AcpRequest(
    id: _generateId(),
    method: 'prompt',
    params: {
      'session_id': sessionId,
      'prompt': {
        'text': text,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      },
    },
  );
}

/// 附件类型
sealed class Attachment {
  String get type;
  String get mimeType;
  String? get data;
  
  Map<String, dynamic> toJson();
}

class ImageAttachment extends Attachment {
  @override
  String get type => 'image';
  
  @override
  final String mimeType;
  
  @override
  final String data; // Base64 编码
  
  final int? width;
  final int? height;
  
  ImageAttachment({
    required this.mimeType,
    required this.data,
    this.width,
    this.height,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'mimeType': mimeType,
    'data': data,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
  };
}

class AudioAttachment extends Attachment {
  @override
  String get type => 'audio';
  
  @override
  final String mimeType;
  
  @override
  final String data; // Base64 编码
  
  final int? duration;
  
  AudioAttachment({
    required this.mimeType,
    required this.data,
    this.duration,
  });
  
  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'mimeType': mimeType,
    'data': data,
    if (duration != null) 'duration': duration,
  };
}
```

---

## 4. 事件处理设计

### 4.1 事件类型

| 事件 | 说明 | 触发时机 |
|------|------|----------|
| `message` | 消息更新 | Agent 回复时 |
| `tool_call` | 工具调用 | Agent 调用工具时 |
| `tool_call_update` | 工具更新 | 工具状态变化 |
| `done` | 完成 | 会话结束时 |
| `session_info_update` | 会话信息更新 | 会话状态变化 |
| `usage_update` | 使用量更新 | Token 使用变化 |

### 4.2 事件处理器接口

```dart
/// 事件处理器接口
abstract class EventHandler {
  /// 处理事件
  Future<void> handle(AcpEvent event);
  
  /// 支持的事件类型
  Set<String> get supportedEvents;
}

/// 事件分发器
class EventDispatcher {
  final Map<String, List<EventHandler>> _handlers = {};
  
  /// 注册处理器
  void register(String event, EventHandler handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }
  
  /// 分发事件
  Future<void> dispatch(AcpEvent event) async {
    final handlers = _handlers[event.event] ?? [];
    for (final handler in handlers) {
      await handler.handle(event);
    }
  }
  
  /// 移除处理器
  void unregister(String event, EventHandler handler) {
    _handlers[event]?.remove(handler);
  }
}
```

### 4.3 消息事件处理器

```dart
/// 消息事件处理器
class MessageEventHandler implements EventHandler {
  final MessageRepository _repository;
  final void Function(Message)? onMessage;
  
  MessageEventHandler({
    required MessageRepository repository,
    this.onMessage,
  }) : _repository = repository;
  
  @override
  Set<String> get supportedEvents => {'message'};
  
  @override
  Future<void> handle(AcpEvent event) async {
    final message = Message.fromJson(event.payload);
    await _repository.save(message);
    onMessage?.call(message);
  }
}
```

### 4.4 工具调用事件处理器

```dart
/// 工具调用事件
class ToolCallEvent {
  final String id;
  final String name;
  final ToolCallStatus status;
  final Map<String, dynamic>? input;
  final Map<String, dynamic>? output;
  final String? error;
  
  ToolCallEvent({
    required this.id,
    required this.name,
    required this.status,
    this.input,
    this.output,
    this.error,
  });
  
  factory ToolCallEvent.fromJson(Map<String, dynamic> json) => ToolCallEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    status: ToolCallStatus.fromString(json['status'] as String),
    input: json['input'] as Map<String, dynamic>?,
    output: json['output'] as Map<String, dynamic>?,
    error: json['error'] as String?,
  );
}

enum ToolCallStatus {
  pending,
  running,
  completed,
  failed;
  
  static ToolCallStatus fromString(String value) {
    return ToolCallStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ToolCallStatus.pending,
    );
  }
}
```

---

## 5. 错误处理设计

### 5.1 错误类型

```dart
/// ACP 错误
class AcpError implements Exception {
  /// 错误码
  final int code;
  
  /// 错误消息
  final String message;
  
  /// 详细数据
  final Map<String, dynamic>? data;
  
  AcpError({
    required this.code,
    required this.message,
    this.data,
  });
  
  factory AcpError.fromJson(Map<String, dynamic> json) => AcpError(
    code: json['code'] as int,
    message: json['message'] as String,
    data: json['data'] as Map<String, dynamic>?,
  );
  
  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
  
  @override
  String toString() => 'AcpError($code): $message';
}
```

### 5.2 标准错误码

| 错误码 | 名称 | 说明 | 处理方式 |
|--------|------|------|----------|
| -32700 | ParseError | 消息解析失败 | 检查消息格式 |
| -32600 | InvalidRequest | 无效请求 | 检查请求参数 |
| -32601 | MethodNotFound | 方法不存在 | 检查方法名 |
| -32602 | InvalidParams | 参数无效 | 检查参数类型 |
| -32603 | InternalError | 内部错误 | 重试或联系支持 |
| -32001 | AuthFailed | 认证失败 | 检查凭证 |
| -32002 | SessionExpired | 会话过期 | 重新认证 |
| -32003 | RateLimited | 请求限流 | 等待后重试 |
| -32004 | AgentUnavailable | Agent 不可用 | 选择其他 Agent |

### 5.3 错误处理器

```dart
/// 错误处理器
class ErrorHandler {
  /// 处理错误
  AcpErrorAction handle(AcpError error) {
    return switch (error.code) {
      -32001 => AcpErrorAction.reauth,
      -32002 => AcpErrorAction.reconnect,
      -32003 => AcpErrorAction.retry,
      >= -32700 && <= -32600 => AcpErrorAction.report,
      _ => AcpErrorAction.retry,
    };
  }
}

enum AcpErrorAction {
  /// 重新认证
  reauth,
  
  /// 重新连接
  reconnect,
  
  /// 重试
  retry,
  
  /// 报告给用户
  report,
  
  /// 忽略
  ignore,
}
```

---

## 6. 测试用例

### 6.1 连接管理测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

void main() {
  group('ConnectionManager', () {
    late ConnectionManager manager;
    late MockWebSocketChannel mockChannel;
    
    setUp(() {
      mockChannel = MockWebSocketChannel();
      manager = ConnectionManagerImpl(channel: mockChannel);
    });
    
    tearDown(() {
      manager.dispose();
    });
    
    test('初始状态应为 disconnected', () {
      expect(manager.status, equals(ConnectionStatus.disconnected));
    });
    
    test('连接成功后状态应变为 connected', () async {
      // arrange
      when(() => mockChannel.ready).thenAnswer((_) => Future.value());
      
      // act
      await manager.connect('test-connection');
      
      // assert
      expect(manager.status, equals(ConnectionStatus.connected));
    });
    
    test('连接失败应抛出 ConnectionException', () async {
      // arrange
      when(() => mockChannel.ready)
          .thenThrow(WebSocketChannelException('Connection refused'));
      
      // act & assert
      expect(
        () => manager.connect('test-connection'),
        throwsA(isA<ConnectionException>()),
      );
    });
    
    test('断开连接后状态应变为 disconnected', () async {
      // arrange
      when(() => mockChannel.ready).thenAnswer((_) => Future.value());
      await manager.connect('test-connection');
      
      // act
      await manager.disconnect();
      
      // assert
      expect(manager.status, equals(ConnectionStatus.disconnected));
    });
    
    test('状态变化应通过 statusStream 发出', () async {
      // arrange
      when(() => mockChannel.ready).thenAnswer((_) => Future.value());
      final states = <ConnectionStatus>[];
      final subscription = manager.statusStream.listen(states.add);
      
      // act
      await manager.connect('test-connection');
      await manager.disconnect();
      
      // await stream events
      await Future.delayed(Duration(milliseconds: 100));
      
      // assert
      expect(states, containsAll([
        ConnectionStatus.connecting,
        ConnectionStatus.connected,
        ConnectionStatus.disconnected,
      ]));
      
      await subscription.cancel();
    });
  });
}
```

### 6.2 消息编解码测试

```dart
void main() {
  group('MessageCodec', () {
    test('应正确编码请求消息', () {
      // arrange
      final request = AcpRequest(
        id: 'test-id',
        method: 'ping',
        params: {},
      );
      
      // act
      final encoded = MessageCodec.encode(request);
      
      // assert
      expect(encoded, contains('"type":"req"'));
      expect(encoded, contains('"id":"test-id"'));
      expect(encoded, contains('"method":"ping"'));
      expect(encoded.endsWith('\n'), isTrue);
    });
    
    test('应正确解码响应消息', () {
      // arrange
      final json = '{"type":"res","id":"test-id","ok":true,"payload":{}}';
      
      // act
      final message = MessageCodec.decodeOne(json);
      
      // assert
      expect(message, isA<AcpResponse>());
      final response = message as AcpResponse;
      expect(response.id, equals('test-id'));
      expect(response.ok, isTrue);
    });
    
    test('应正确解码事件消息', () {
      // arrange
      final json = '{"type":"event","event":"message","payload":{"text":"hello"}}';
      
      // act
      final message = MessageCodec.decodeOne(json);
      
      // assert
      expect(message, isA<AcpEvent>());
      final event = message as AcpEvent;
      expect(event.event, equals('message'));
      expect(event.payload['text'], equals('hello'));
    });
    
    test('解码无效类型应抛出异常', () {
      // arrange
      final json = '{"type":"unknown"}';
      
      // act & assert
      expect(
        () => MessageCodec.decodeOne(json),
        throwsA(isA<AcpUnknownMessageTypeException>()),
      );
    });
    
    test('应正确处理 NDJSON 多条消息', () {
      // arrange
      final ndjson = '''
{"type":"event","event":"message","payload":{}}
{"type":"event","event":"done","payload":{}}
''';
      
      // act
      final messages = MessageCodec.decode(ndjson);
      
      // assert
      expect(messages.length, equals(2));
      expect(messages[0], isA<AcpEvent>());
      expect((messages[0] as AcpEvent).event, equals('message'));
      expect((messages[1] as AcpEvent).event, equals('done'));
    });
  });
}
```

### 6.3 事件分发测试

```dart
class MockEventHandler extends Mock implements EventHandler {}

void main() {
  group('EventDispatcher', () {
    late EventDispatcher dispatcher;
    late MockEventHandler mockHandler;
    
    setUp(() {
      dispatcher = EventDispatcher();
      mockHandler = MockEventHandler();
      when(() => mockHandler.supportedEvents).thenReturn({'message'});
    });
    
    test('注册处理器后应能分发事件', () async {
      // arrange
      dispatcher.register('message', mockHandler);
      final event = AcpEvent(event: 'message', payload: {});
      
      // act
      await dispatcher.dispatch(event);
      
      // assert
      verify(() => mockHandler.handle(event)).called(1);
    });
    
    test('未注册的事件应不被处理', () async {
      // arrange
      dispatcher.register('message', mockHandler);
      final event = AcpEvent(event: 'unknown', payload: {});
      
      // act
      await dispatcher.dispatch(event);
      
      // assert
      verifyNever(() => mockHandler.handle(any()));
    });
    
    test('移除处理器后应不再处理', () async {
      // arrange
      dispatcher.register('message', mockHandler);
      dispatcher.unregister('message', mockHandler);
      final event = AcpEvent(event: 'message', payload: {});
      
      // act
      await dispatcher.dispatch(event);
      
      // assert
      verifyNever(() => mockHandler.handle(any()));
    });
  });
}
```

---

## 7. 附录

### 7.1 术语表

| 术语 | 定义 |
|------|------|
| ACP | Agent Client Protocol，客户端协议 |
| NDJSON | Newline Delimited JSON，换行分隔 JSON |
| WebSocket | 全双工通信协议 |
| Session Key | 会话键，用于路由和标识会话 |

### 7.2 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**