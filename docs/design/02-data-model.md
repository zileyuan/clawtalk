# ClawTalk 数据模型设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md)

---

## 目录

1. [概述](#1-概述)
2. [核心实体](#2-核心实体)
3. [值对象](#3-值对象)
4. [存储设计](#4-存储设计)
5. [数据关系图](#5-数据关系图)
6. [测试用例](#6-测试用例)
7. [附录](#7-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端的核心数据模型，包括：
- 实体定义与关系
- 值对象与枚举
- 持久化策略
- 数据验证规则

### 1.2 设计原则

| 原则 | 说明 |
|------|------|
| 不可变性 | 所有实体字段使用 `final`，修改通过 `copyWith` |
| 类型安全 | 使用 sealed class 和枚举避免非法状态 |
| 验证优先 | 构造函数中进行数据验证 |
| JSON 兼容 | 所有实体支持 JSON 序列化/反序列化 |

### 1.3 模块结构

```
lib/
├── core/
│   └── models/
│       ├── connection/
│       │   ├── connection_config.dart
│       │   └── connection_status.dart
│       ├── messaging/
│       │   ├── message.dart
│       │   ├── message_role.dart
│       │   ├── message_status.dart
│       │   └── content_block.dart
│       ├── session/
│       │   └── session.dart
│       └── settings/
│           └── app_settings.dart
```

---

## 2. 核心实体

### 2.1 ConnectionConfig - 连接配置

```dart
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// 连接配置实体
class ConnectionConfig extends Equatable {
  /// 唯一标识
  final String id;
  
  /// 连接名称
  final String name;
  
  /// Gateway 主机地址
  final String host;
  
  /// Gateway 端口
  final int port;
  
  /// 是否使用 TLS (wss)
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

  const ConnectionConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port = 18789,
    this.useTls = true,
    this.token,
    this.password,
    this.defaultSessionKey,
    this.tags = const [],
    required this.createdAt,
    this.lastConnectedAt,
    this.autoReconnect = true,
    this.connectionTimeout = 10000,
  });

  /// 创建新连接配置
  factory ConnectionConfig.create({
    required String name,
    required String host,
    int port = 18789,
    bool useTls = true,
    String? token,
    String? password,
    String? defaultSessionKey,
    List<String> tags = const [],
    bool autoReconnect = true,
    int connectionTimeout = 10000,
  }) {
    if (name.isEmpty) {
      throw ValidationException('连接名称不能为空');
    }
    if (host.isEmpty) {
      throw ValidationException('主机地址不能为空');
    }
    if (token == null && password == null) {
      throw ValidationException('必须提供 token 或 password');
    }
    
    return ConnectionConfig(
      id: const Uuid().v4(),
      name: name,
      host: host,
      port: port,
      useTls: useTls,
      token: token,
      password: password,
      defaultSessionKey: defaultSessionKey,
      tags: tags,
      createdAt: DateTime.now(),
      autoReconnect: autoReconnect,
      connectionTimeout: connectionTimeout,
    );
  }

  /// 获取 WebSocket URL
  String get wsUrl {
    final scheme = useTls ? 'wss' : 'ws';
    return '$scheme://$host:$port';
  }

  /// 是否已配置认证
  bool get hasAuth => token != null || password != null;

  /// 更新最后连接时间
  ConnectionConfig withLastConnected() => copyWith(
    lastConnectedAt: DateTime.now(),
  );

  /// 复制并修改
  ConnectionConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    bool? useTls,
    String? token,
    String? password,
    String? defaultSessionKey,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? lastConnectedAt,
    bool? autoReconnect,
    int? connectionTimeout,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      useTls: useTls ?? this.useTls,
      token: token ?? this.token,
      password: password ?? this.password,
      defaultSessionKey: defaultSessionKey ?? this.defaultSessionKey,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    );
  }

  @override
  List<Object?> get props => [
    id, name, host, port, useTls, token, password,
    defaultSessionKey, tags, createdAt, lastConnectedAt,
    autoReconnect, connectionTimeout,
  ];

  /// JSON 序列化
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'useTls': useTls,
    'token': token,
    'password': password,
    'defaultSessionKey': defaultSessionKey,
    'tags': tags,
    'createdAt': createdAt.toIso8601String(),
    'lastConnectedAt': lastConnectedAt?.toIso8601String(),
    'autoReconnect': autoReconnect,
    'connectionTimeout': connectionTimeout,
  };

  /// JSON 反序列化
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int? ?? 18789,
      useTls: json['useTls'] as bool? ?? true,
      token: json['token'] as String?,
      password: json['password'] as String?,
      defaultSessionKey: json['defaultSessionKey'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      connectionTimeout: json['connectionTimeout'] as int? ?? 10000,
    );
  }
}
```

### 2.2 Session - 会话

```dart
/// 会话实体
class Session extends Equatable {
  /// 会话 ID
  final String id;
  
  /// 所属连接 ID
  final String connectionId;
  
  /// 会话键
  final String sessionKey;
  
  /// 会话标签
  final String? label;
  
  /// 工作目录
  final String? cwd;
  
  /// 会话状态
  final SessionStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime updatedAt;

  const Session({
    required this.id,
    required this.connectionId,
    required this.sessionKey,
    this.label,
    this.cwd,
    this.status = SessionStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 是否活跃
  bool get isActive => status == SessionStatus.active;

  @override
  List<Object?> get props => [
    id, connectionId, sessionKey, label, cwd, status,
    createdAt, updatedAt,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'connectionId': connectionId,
    'sessionKey': sessionKey,
    'label': label,
    'cwd': cwd,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    id: json['id'] as String,
    connectionId: json['connectionId'] as String,
    sessionKey: json['sessionKey'] as String,
    label: json['label'] as String?,
    cwd: json['cwd'] as String?,
    status: SessionStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SessionStatus.active,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// 会话状态
enum SessionStatus {
  /// 活跃
  active,
  
  /// 已暂停
  paused,
  
  /// 已完成
  completed,
  
  /// 已取消
  cancelled,
}
```

### 2.3 Message - 消息

```dart
/// 消息实体
class Message extends Equatable {
  /// 消息 ID
  final String id;
  
  /// 所属会话 ID
  final String sessionId;
  
  /// 所属连接 ID
  final String connectionId;
  
  /// 消息角色
  final MessageRole role;
  
  /// 消息内容
  final List<ContentBlock> content;
  
  /// 消息状态
  final MessageStatus status;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 发送时间
  final DateTime? sentAt;
  
  /// 错误信息
  final String? error;

  const Message({
    required this.id,
    required this.sessionId,
    required this.connectionId,
    required this.role,
    required this.content,
    this.status = MessageStatus.pending,
    required this.createdAt,
    this.sentAt,
    this.error,
  });

  /// 是否为用户消息
  bool get isUser => role == MessageRole.user;

  /// 是否为助手消息
  bool get isAssistant => role == MessageRole.assistant;

  /// 获取文本内容
  String get textContent {
    return content
        .whereType<TextContent>()
        .map((c) => c.text)
        .join('\n');
  }

  /// 获取图片附件
  List<ImageContent> get imageContent {
    return content.whereType<ImageContent>().toList();
  }

  /// 获取音频附件
  List<AudioContent> get audioContent {
    return content.whereType<AudioContent>().toList();
  }

  @override
  List<Object?> get props => [
    id, sessionId, connectionId, role, content, status,
    createdAt, sentAt, error,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'connectionId': connectionId,
    'role': role.name,
    'content': content.map((c) => c.toJson()).toList(),
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'sentAt': sentAt?.toIso8601String(),
    'error': error,
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    connectionId: json['connectionId'] as String,
    role: MessageRole.values.firstWhere((e) => e.name == json['role']),
    status: MessageStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => MessageStatus.pending,
    ),
    content: (json['content'] as List<dynamic>)
        .map((c) => ContentBlock.fromJson(c as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    sentAt: json['sentAt'] != null
        ? DateTime.parse(json['sentAt'] as String)
        : null,
    error: json['error'] as String?,
  );
}
```

---

## 3. 值对象

### 3.1 枚举定义

```dart
/// 消息角色
enum MessageRole {
  /// 用户消息
  user,
  
  /// 助手消息
  assistant,
  
  /// 系统消息
  system,
}

/// 消息状态
enum MessageStatus {
  /// 发送中
  sending,
  
  /// 已发送
  sent,
  
  /// 已送达
  delivered,
  
  /// 已读
  read,
  
  /// 发送失败
  failed,
}

/// 连接状态
enum ConnectionStatus {
  /// 已断开
  disconnected,
  
  /// 连接中
  connecting,
  
  /// 已连接
  connected,
  
  /// 认证中
  authenticating,
  
  /// 已认证
  authenticated,
  
  /// 错误
  error,
  
  /// 重连中
  reconnecting,
}
```

### 3.2 ContentBlock - 内容块 (Sealed Class)

```dart
/// 内容块基类
sealed class ContentBlock extends Equatable {
  /// 内容类型
  String get type;
  
  /// 转换为 JSON
  Map<String, dynamic> toJson();
  
  /// 从 JSON 解析
  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return switch (json['type'] as String) {
      'text' => TextContent.fromJson(json),
      'image' => ImageContent.fromJson(json),
      'audio' => AudioContent.fromJson(json),
      _ => throw UnknownContentTypeException(json['type'] as String),
    };
  }
}

/// 文本内容
class TextContent extends ContentBlock {
  @override
  String get type => 'text';
  
  /// 文本内容
  final String text;

  const TextContent({required this.text});

  @override
  List<Object?> get props => [text];

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
  };

  factory TextContent.fromJson(Map<String, dynamic> json) =>
      TextContent(text: json['text'] as String);
}

/// 图片内容
class ImageContent extends ContentBlock {
  @override
  String get type => 'image';
  
  /// MIME 类型
  final String mimeType;
  
  /// Base64 数据
  final String data;
  
  /// 图片宽度
  final int? width;
  
  /// 图片高度
  final int? height;
  
  /// 文件大小 (字节)
  final int? size;

  const ImageContent({
    required this.mimeType,
    required this.data,
    this.width,
    this.height,
    this.size,
  });

  @override
  List<Object?> get props => [mimeType, data, width, height, size];

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'mimeType': mimeType,
    'data': data,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (size != null) 'size': size,
  };

  factory ImageContent.fromJson(Map<String, dynamic> json) => ImageContent(
    mimeType: json['mimeType'] as String,
    data: json['data'] as String,
    width: json['width'] as int?,
    height: json['height'] as int?,
    size: json['size'] as int?,
  );
}

/// 音频内容
class AudioContent extends ContentBlock {
  @override
  String get type => 'audio';
  
  /// MIME 类型
  final String mimeType;
  
  /// Base64 数据
  final String data;
  
  /// 时长 (秒)
  final int? duration;
  
  /// 文件大小 (字节)
  final int? size;

  const AudioContent({
    required this.mimeType,
    required this.data,
    this.duration,
    this.size,
  });

  @override
  List<Object?> get props => [mimeType, data, duration, size];

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    'mimeType': mimeType,
    'data': data,
    if (duration != null) 'duration': duration,
    if (size != null) 'size': size,
  };

  factory AudioContent.fromJson(Map<String, dynamic> json) => AudioContent(
    mimeType: json['mimeType'] as String,
    data: json['data'] as String,
    duration: json['duration'] as int?,
    size: json['size'] as int?,
  );
}
```

### 3.3 AppSettings - 应用设置

```dart
/// 应用设置
class AppSettings extends Equatable {
  /// 主题模式
  final ThemeMode themeMode;
  
  /// 语言代码
  final String locale;
  
  /// 是否启用推送通知
  final bool notificationsEnabled;
  
  /// 默认连接 ID
  final String? defaultConnectionId;
  
  /// 最后使用的连接 ID
  final String? lastConnectionId;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = 'zh_CN',
    this.notificationsEnabled = true,
    this.defaultConnectionId,
    this.lastConnectionId,
  });

  /// 默认设置
  static const defaults = AppSettings();

  @override
  List<Object?> get props => [
    themeMode, locale, notificationsEnabled,
    defaultConnectionId, lastConnectionId,
  ];

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'locale': locale,
    'notificationsEnabled': notificationsEnabled,
    'defaultConnectionId': defaultConnectionId,
    'lastConnectionId': lastConnectionId,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    themeMode: ThemeMode.values.firstWhere(
      (e) => e.name == json['themeMode'],
      orElse: () => ThemeMode.system,
    ),
    locale: json['locale'] as String? ?? 'zh_CN',
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    defaultConnectionId: json['defaultConnectionId'] as String?,
    lastConnectionId: json['lastConnectionId'] as String?,
  );

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? locale,
    bool? notificationsEnabled,
    String? defaultConnectionId,
    String? lastConnectionId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultConnectionId: defaultConnectionId ?? this.defaultConnectionId,
      lastConnectionId: lastConnectionId ?? this.lastConnectionId,
    );
  }
}

/// 主题模式
enum ThemeMode {
  /// 跟随系统
  system,
  
  /// 浅色模式
  light,
  
  /// 深色模式
  dark,
}
```

---

## 4. 存储设计

### 4.1 存储架构

```
┌─────────────────────────────────────────────────────────────┐
│                      存储层次                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              安全存储 (Secure Storage)               │   │
│  │  flutter_secure_storage                             │   │
│  │  • Token                                            │   │
│  │  • Password                                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              偏好存储 (Preferences)                  │   │
│  │  shared_preferences                                 │   │
│  │  • ConnectionConfig (JSON)                          │   │
│  │  • AppSettings                                      │   │
│  │  • Session (JSON)                                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              缓存存储 (Cache)                        │   │
│  │  SharedPreferences + 内存缓存                        │   │
│  │  • Message (最近 1000 条)                           │   │
│  │  • Agent 列表                                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 存储键定义

```dart
/// 存储键常量
class StorageKeys {
  // 连接配置
  static const String connections = 'clawtalk_connections';
  
  // 应用设置
  static const String settings = 'clawtalk_settings';
  
  // 会话列表
  static const String sessions = 'clawtalk_sessions';
  
  // 消息缓存前缀
  static const String messagesPrefix = 'clawtalk_messages_';
  
  // 凭证前缀 (安全存储)
  static const String tokenPrefix = 'clawtalk_token_';
  static const String passwordPrefix = 'clawtalk_password_';
  
  // 草稿前缀
  static const String draftPrefix = 'clawtalk_draft_';
}
```

### 4.3 存储接口

```dart
/// 连接配置存储接口
abstract class ConnectionConfigRepository {
  /// 获取所有连接配置
  Future<List<ConnectionConfig>> getAll();
  
  /// 根据 ID 获取连接配置
  Future<ConnectionConfig?> getById(String id);
  
  /// 保存连接配置
  Future<void> save(ConnectionConfig config);
  
  /// 删除连接配置
  Future<void> delete(String id);
  
  /// 获取凭证
  Future<Credentials?> getCredentials(String id);
  
  /// 保存凭证
  Future<void> saveCredentials(String id, Credentials credentials);
  
  /// 删除凭证
  Future<void> deleteCredentials(String id);
}

/// 凭证
class Credentials extends Equatable {
  final String? token;
  final String? password;

  const Credentials({this.token, this.password});

  bool get hasAuth => token != null || password != null;

  @override
  List<Object?> get props => [token, password];
}

/// 消息存储接口
abstract class MessageRepository {
  /// 获取消息列表
  Future<List<Message>> getMessages(String sessionId, {
    int limit = 50,
    String? beforeId,
  });
  
  /// 保存消息
  Future<void> save(Message message);
  
  /// 删除消息
  Future<void> delete(String messageId);
  
  /// 清除会话的所有消息
  Future<void> clearSession(String sessionId);
  
  /// 搜索消息
  Future<List<Message>> search(String query, String connectionId);
  
  /// 获取缓存数量
  Future<int> count(String sessionId);
}
```

### 4.4 数据迁移策略

```dart
/// 数据版本管理
class DataVersion {
  static const int current = 1;
  static const String key = 'clawtalk_data_version';
  
  /// 检查并执行迁移
  static Future<void> migrate(
    SharedPreferences prefs,
    int fromVersion,
  ) async {
    if (fromVersion >= current) return;
    
    switch (fromVersion) {
      case 0:
        // 首次安装，无需迁移
        break;
      // 未来版本迁移：
      // case 1:
      //   await migrateFrom1to2(prefs);
      //   break;
    }
    
    await prefs.setInt(key, current);
  }
}
```

---

## 5. 数据关系图

```
┌─────────────────────────────────────────────────────────────┐
│                      实体关系图                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────┐                                      │
│  │  ConnectionConfig │                                      │
│  │───────────────────│                                      │
│  │ id: String        │                                      │
│  │ name: String      │                                      │
│  │ host: String      │                                      │
│  │ port: int         │                                      │
│  │ token?: String    │──────┐                               │
│  │ password?: String │      │ Secure Storage                │
│  └─────────┬─────────┘      │                               │
│            │                ▼                               │
│            │ 1      ┌───────────────────┐                   │
│            │        │   Credentials     │                   │
│            │        │───────────────────│                   │
│            │        │ token?: String    │                   │
│            │        │ password?: String │                   │
│            │        └───────────────────┘                   │
│            │                                               │
│            │ *                                             │
│            ▼                                               │
│  ┌───────────────────┐                                      │
│  │     Session       │                                      │
│  │───────────────────│                                      │
│  │ id: String        │                                      │
│  │ connectionId: FK  │                                      │
│  │ sessionKey: String│                                      │
│  │ status: Enum      │                                      │
│  └─────────┬─────────┘                                      │
│            │                                               │
│            │ *                                             │
│            ▼                                               │
│  ┌───────────────────┐      ┌───────────────────┐          │
│  │     Message       │      │   ContentBlock    │          │
│  │───────────────────│      │───────────────────│          │
│  │ id: String        │      │ type: String      │          │
│  │ sessionId: FK     │─────►│ (sealed class)    │          │
│  │ role: Enum        │      │                   │          │
│  │ status: Enum      │      │ ┌───────────────┐ │          │
│  │ content: List     │──────┼─│ TextContent   │ │          │
│  └───────────────────┘      │ ├───────────────┤ │          │
│                             │ │ ImageContent  │ │          │
│                             │ ├───────────────┤ │          │
│                             │ │ AudioContent  │ │          │
│                             │ └───────────────┘ │          │
│                             └───────────────────┘          │
│                                                            │
│  ┌───────────────────┐                                     │
│  │   AppSettings     │                                     │
│  │───────────────────│                                     │
│  │ themeMode: Enum   │                                     │
│  │ locale: String    │                                     │
│  │ defaultConnId: FK │                                     │
│  └───────────────────┘                                     │
│                                                            │
└─────────────────────────────────────────────────────────────┘

关系说明:
  ConnectionConfig 1 -- * Session (一个连接可有多个会话)
  Session 1 -- * Message (一个会话可有多条消息)
  Message 1 -- * ContentBlock (一条消息可有多块内容)
  AppSettings * -- 1 ConnectionConfig (默认连接引用)
```

---

## 6. 测试用例

### 6.1 实体测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:clawtalk/core/models/connection/connection_config.dart';

void main() {
  group('ConnectionConfig', () {
    test('应正确创建连接配置', () {
      // act
      final config = ConnectionConfig.create(
        name: 'Test Gateway',
        host: 'gateway.example.com',
        token: 'test-token',
      );
      
      // assert
      expect(config.name, equals('Test Gateway'));
      expect(config.host, equals('gateway.example.com'));
      expect(config.port, equals(18789));
      expect(config.useTls, isTrue);
      expect(config.token, equals('test-token'));
      expect(config.id, isNotEmpty);
    });
    
    test('空名称应抛出验证异常', () {
      // act & assert
      expect(
        () => ConnectionConfig.create(
          name: '',
          host: 'gateway.example.com',
          token: 'test-token',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
    
    test('无认证信息应抛出验证异常', () {
      // act & assert
      expect(
        () => ConnectionConfig.create(
          name: 'Test',
          host: 'gateway.example.com',
        ),
        throwsA(isA<ValidationException>()),
      );
    });
    
    test('应正确生成 WebSocket URL', () {
      // arrange
      final tlsConfig = ConnectionConfig.create(
        name: 'TLS',
        host: 'secure.example.com',
        token: 'token',
        useTls: true,
      );
      final plainConfig = ConnectionConfig.create(
        name: 'Plain',
        host: 'insecure.example.com',
        token: 'token',
        useTls: false,
      );
      
      // assert
      expect(tlsConfig.wsUrl, equals('wss://secure.example.com:18789'));
      expect(plainConfig.wsUrl, equals('ws://insecure.example.com:18789'));
    });
    
    test('copyWith 应正确复制并修改', () {
      // arrange
      final original = ConnectionConfig.create(
        name: 'Original',
        host: 'original.example.com',
        token: 'token',
      );
      
      // act
      final modified = original.copyWith(name: 'Modified');
      
      // assert
      expect(modified.name, equals('Modified'));
      expect(modified.host, equals('original.example.com'));
      expect(modified.id, equals(original.id));
    });
    
    test('应正确序列化和反序列化 JSON', () {
      // arrange
      final original = ConnectionConfig.create(
        name: 'Test',
        host: 'gateway.example.com',
        port: 8080,
        token: 'test-token',
        tags: ['production', 'main'],
      );
      
      // act
      final json = original.toJson();
      final deserialized = ConnectionConfig.fromJson(json);
      
      // assert
      expect(deserialized, equals(original));
      expect(deserialized.tags, equals(['production', 'main']));
    });
  });
}
```

### 6.2 值对象测试

```dart
void main() {
  group('ContentBlock', () {
    test('应正确解析文本内容', () {
      // arrange
      final json = {
        'type': 'text',
        'text': 'Hello, World!',
      };
      
      // act
      final content = ContentBlock.fromJson(json);
      
      // assert
      expect(content, isA<TextContent>());
      expect((content as TextContent).text, equals('Hello, World!'));
    });
    
    test('应正确解析图片内容', () {
      // arrange
      final json = {
        'type': 'image',
        'mimeType': 'image/png',
        'data': 'base64data...',
        'width': 100,
        'height': 100,
      };
      
      // act
      final content = ContentBlock.fromJson(json);
      
      // assert
      expect(content, isA<ImageContent>());
      final image = content as ImageContent;
      expect(image.mimeType, equals('image/png'));
      expect(image.width, equals(100));
    });
    
    test('未知类型应抛出异常', () {
      // arrange
      final json = {'type': 'unknown'};
      
      // act & assert
      expect(
        () => ContentBlock.fromJson(json),
        throwsA(isA<UnknownContentTypeException>()),
      );
    });
  });
  
  group('Message', () {
    test('应正确提取文本内容', () {
      // arrange
      final message = Message(
        id: 'msg-1',
        sessionId: 'session-1',
        connectionId: 'conn-1',
        role: MessageRole.assistant,
        content: [
          TextContent(text: 'Hello'),
          TextContent(text: 'World'),
          ImageContent(mimeType: 'image/png', data: 'base64'),
        ],
        createdAt: DateTime.now(),
      );
      
      // act
      final text = message.textContent;
      
      // assert
      expect(text, equals('Hello\nWorld'));
    });
    
    test('应正确过滤图片内容', () {
      // arrange
      final message = Message(
        id: 'msg-1',
        sessionId: 'session-1',
        connectionId: 'conn-1',
        role: MessageRole.user,
        content: [
          TextContent(text: 'Check this'),
          ImageContent(mimeType: 'image/png', data: 'img1'),
          ImageContent(mimeType: 'image/jpeg', data: 'img2'),
        ],
        createdAt: DateTime.now(),
      );
      
      // act
      final images = message.imageContent;
      
      // assert
      expect(images.length, equals(2));
      expect(images[0].mimeType, equals('image/png'));
      expect(images[1].mimeType, equals('image/jpeg'));
    });
  });
}
```

### 6.3 存储测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ConnectionConfigRepository', () {
    late ConnectionConfigRepositoryImpl repository;
    late MockSharedPreferences mockPrefs;
    late MockSecureStorage mockStorage;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      mockStorage = MockSecureStorage();
      repository = ConnectionConfigRepositoryImpl(
        prefs: mockPrefs,
        secureStorage: mockStorage,
      );
    });
    
    test('应正确保存和获取连接配置', () async {
      // arrange
      final config = ConnectionConfig.create(
        name: 'Test',
        host: 'gateway.example.com',
        token: 'token',
      );
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getString(any())).thenReturn(null);
      
      // act
      await repository.save(config);
      
      // assert
      verify(() => mockPrefs.setString(
        StorageKeys.connections,
        any(),
      )).called(1);
    });
    
    test('应正确删除连接配置和凭证', () async {
      // arrange
      final configId = 'test-id';
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      
      // act
      await repository.delete(configId);
      
      // assert
      verify(() => mockPrefs.remove(any())).called(1);
      verify(() => mockStorage.delete(key: '${StorageKeys.tokenPrefix}$configId'))
          .called(1);
      verify(() => mockStorage.delete(key: '${StorageKeys.passwordPrefix}$configId'))
          .called(1);
    });
  });
}
```

---

## 7. 附录

### 7.1 术语表

| 术语 | 定义 |
|------|------|
| Entity | 实体，具有唯一标识的对象 |
| Value Object | 值对象，无唯一标识，通过值判断相等 |
| Sealed Class | 密封类，限制子类继承的类 |
| Repository | 仓库，数据访问抽象层 |

### 7.2 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**