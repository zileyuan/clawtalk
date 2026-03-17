# ClawTalk 技术架构文档 (TAD)

**产品名称**: ClawTalk  
**产品定位**: OpenClaw 跨平台客户端  
**文档类型**: 技术架构文档  
**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**文档状态**: 初稿  
**作者**: 架构师  
**主要读者**: 开发团队、技术负责人、DevOps

---

## 文档关系

本文档与 [产品需求文档 (PRD)](./product-requirements.md) 配套使用：
- **产品需求文档 (PRD)**: 定义"做什么"和"为什么" - 业务需求、用户场景、验收标准
- **本文档 (TAD)**: 定义"怎么做" - 技术实现、架构设计、开发规范

---

## 目录

1. [项目背景](#1-项目背景)
2. [ACP 协议规范](#2-acp-协议规范)
3. [技术架构](#3-技术架构)
4. [输入模块设计](#4-输入模块设计)
5. [连接模块设计](#5-连接模块设计)
6. [消息模块设计](#6-消息模块设计)
7. [非功能性目标](#7-非功能性目标)
8. [UI/UX 技术实现](#8-uiux-技术实现)
9. [附录](#9-附录)

---

## 1. 项目背景

**ClawTalk** 是 OpenClaw 的跨平台客户端，基于 Flutter 开发，通过 ACP 协议与 OpenClaw Gateway 通信。

**技术栈概览**:

| 层次 | 技术选型 |
|------|----------|
| 框架 | Flutter 3.x |
| 状态管理 | Riverpod |
| UI 组件 | Cupertino (iOS 风格) |
| 国际化 | flutter_localizations + intl |
| 网络通信 | WebSocket (ACP) |
| 本地存储 | SharedPreferences + flutter_secure_storage |

**相关文档**: 详细业务需求和验收标准见 [PRD](./product-requirements.md)

---

## 2. ACP 协议规范

### 2.1 协议概述

ACP (Agent Client Protocol) 是 OpenClaw 定义的客户端协议，用于客户端与 Gateway 之间的通信。

**官方文档**:
- ACP CLI 文档: https://docs.openclaw.ai/zh-CN/cli/acp
- 技术规范: https://github.com/openclaw/openclaw/blob/main/docs.acp.md

#### 2.1.1 核心特性

| 特性 | 说明 |
|------|------|
| 消息格式 | NDJSON (Newline Delimited JSON) |
| 传输层 | stdio (客户端) + WebSocket (Gateway) |
| 会话映射 | ACP 会话映射到 Gateway 会话键 |
| 流式响应 | 支持 Gateway 流式事件实时推送 |

### 2.2 连接管理

#### 2.2.1 连接端点

OpenClaw Gateway 默认端口: **18789**

```
ws://127.0.0.1:18789          # 本地 Gateway
wss://gateway-host:18789      # 远程 Gateway (TLS)
```

#### 2.2.2 连接状态机

```
┌─────────────┐     connect      ┌─────────────┐
│ Disconnected│ ───────────────► │ Connecting  │
└─────────────┘                  └──────┬──────┘
     ▲                                  │
     │                         ┌────────┴────────┐
     │                         │ success         │ error
     │                         ▼                 ▼
     │                  ┌─────────────┐   ┌─────────────┐
     │                  │  Connected  │   │   Error     │
     │                  └──────┬──────┘   └─────────────┘
     │                         │
     │                  auth success
     │                         │
     │                         ▼
     │                  ┌─────────────┐
     └──────────────────│Authenticated│
       disconnect       └─────────────┘
```

#### 2.2.3 连接参数

| 参数 | 值 | 说明 |
|------|-----|------|
| 连接超时 | 10 秒 | 首次连接建立超时 |
| 握手超时 | 5 秒 | WebSocket 握手超时 |
| 心跳间隔 | 30 秒 | Ping/Pong 心跳间隔 |
| 心跳超时 | 10 秒 | 未收到 Pong 则断开 |

#### 2.2.4 重连策略

采用**指数退避**重连策略：

| 重试次数 | 等待时间 |
|----------|----------|
| 1 | 1 秒 |
| 2 | 2 秒 |
| 3 | 4 秒 |
| 4 | 8 秒 |
| 5+ | 30 秒 (最大) |

### 2.3 认证流程

#### 2.3.1 认证方式

| 方式 | 说明 | 推荐场景 |
|------|------|----------|
| Token | `Authorization: Bearer <token>` | 生产环境 |
| Password | 基本认证头 | 开发/测试环境 |

#### 2.3.2 凭证存储

| 平台 | 存储方案 |
|------|----------|
| macOS | Keychain |
| Windows | Credential Manager |
| Android | EncryptedSharedPreferences |
| iOS | Keychain Services |

### 2.4 协议方法

| 方法 | 说明 | 状态 |
|------|------|------|
| `initialize` | 初始化 ACP 会话 | 已实现 |
| `newSession` | 创建新会话 | 已实现 |
| `prompt` | 发送提示消息 | 已实现 |
| `cancel` | 取消当前操作 | 已实现 |
| `listSessions` | 列出会话 | 已实现 |
| `loadSession` | 加载已有会话 | 部分实现 |
| `session/set_mode` | 设置会话模式 | 部分实现 |

### 2.5 消息格式

#### 2.5.1 初始化请求

```json
{
  "method": "initialize",
  "params": {
    "clientInfo": {
      "name": "ClawTalk",
      "version": "1.0.0"
    },
    "capabilities": {}
  }
}
```

#### 2.5.2 发送提示

```json
{
  "method": "prompt",
  "params": {
    "session_id": "sess-xxx",
    "prompt": {
      "text": "Hello, Agent!",
      "attachments": [
        {
          "type": "image",
          "mimeType": "image/jpeg",
          "data": "<base64>"
        }
      ]
    }
  }
}
```

#### 2.5.3 流式响应事件

```json
// 消息更新
{
  "method": "message",
  "params": {
    "session_id": "sess-xxx",
    "message": {
      "role": "assistant",
      "content": [{ "type": "text", "text": "Hello!" }]
    }
  }
}

// 工具调用
{
  "method": "tool_call",
  "params": {
    "session_id": "sess-xxx",
    "tool_call": {
      "id": "call-xxx",
      "name": "browser.navigate",
      "status": "running"
    }
  }
}

// 完成
{
  "method": "done",
  "params": {
    "session_id": "sess-xxx",
    "reason": "stop"
  }
}
```

### 2.6 会话管理

#### 2.6.1 会话键格式

| 格式 | 说明 | 示例 |
|------|------|------|
| `acp:<uuid>` | ACP 默认隔离会话 | `acp:550e8400-e29b-41d4-a716-446655440000` |
| `agent:<name>:<session>` | Agent 作用域会话 | `agent:main:main` |

#### 2.6.2 会话元数据

```json
{
  "_meta": {
    "sessionKey": "agent:main:main",
    "sessionLabel": "My Session",
    "resetSession": false,
    "requireExisting": false
  }
}
```

### 2.7 媒体数据传输

**ACP 原生支持 Base64 直接传输媒体数据，无需临时存储服务器。**

#### 2.7.1 图片传输

```json
{
  "type": "image",
  "mimeType": "image/png",
  "data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB..."
}
```

#### 2.7.2 音频传输

```json
{
  "type": "audio",
  "mimeType": "audio/mp4",
  "data": "AAAAHGZ0eXBpc29tAAACAGlzb21pc28..."
}
```

#### 2.7.3 传输策略

| 文件大小 | 传输方式 |
|----------|----------|
| < 500KB | Base64 直接传输 |
| 500KB - 10MB | Base64 直接传输 (压缩后) |
| > 10MB | 拒绝发送 |

### 2.8 兼容性矩阵

| ACP 功能 | 状态 | 说明 |
|----------|------|------|
| `initialize`, `newSession`, `prompt`, `cancel` | ✅ | 核心流程 |
| `listSessions`, slash commands | ✅ | 会话列表 |
| `loadSession` | ⚠️ 部分 | 仅回放文本历史 |
| Per-session MCP servers | ❌ | 在 Gateway 层配置 |
| Client filesystem (`fs/*`) | ❌ | 桥接模式不支持 |
| Client terminal (`terminal/*`) | ❌ | 桥接模式不支持 |

---

## 3. 技术架构

### 3.1 架构模式

**架构**: **Riverpod + Clean Architecture**

```
┌─────────────────────────────────────────────────────────────────┐
│                        架构层次                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                   Presentation Layer                     │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │   Widgets   │  │  Providers  │  │  Platform   │      │   │
│  │  │             │  │ (Riverpod)  │  │  Adapters   │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                     Domain Layer                         │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │  Use Cases  │  │  Entities   │  │ Repository  │      │   │
│  │  │             │  │             │  │  Interfaces │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      Data Layer                          │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ Repositories│  │ ACP Client  │  │Local Storage│      │   │
│  │  │   Impl.     │  │             │  │             │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                              │                                  │
│                              ▼                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Platform Layer                        │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │   Camera    │  │ Microphone  │  │Notifications│      │   │
│  │  │  Plugin     │  │   Plugin    │  │   Plugin    │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

```
lib/
├── core/                      # 核心基础设施
│   ├── constants/             # 常量定义
│   ├── errors/                # 错误处理
│   ├── themes/                # Cupertino 主题配置
│   ├── l10n/                  # 国际化
│   │   ├── app_en.arb         # 英文翻译
│   │   └── app_zh.arb         # 中文翻译
│   └── utils/                 # 工具函数
│
├── acp/                       # ACP 协议实现
│   ├── client/                # WebSocket 客户端
│   │   ├── acp_client.dart
│   │   ├── connection_manager.dart
│   │   └── message_handler.dart
│   ├── models/                # 消息模型
│   │   ├── acp_message.dart
│   │   ├── session.dart
│   │   └── content_block.dart
│   ├── services/              # 协议服务
│   └── exceptions/            # 协议异常
│
├── features/
│   ├── connection/            # 多连接管理
│   │   ├── data/
│   │   ├── domain/
│   │   ├── providers/
│   │   └── presentation/
│   │
│   ├── messaging/             # 消息处理
│   │   ├── data/
│   │   ├── domain/
│   │   ├── providers/
│   │   └── presentation/
│   │
│   ├── input/                 # 输入模块
│   │   ├── text/
│   │   ├── image/
│   │   └── voice/
│   │
│   ├── agents/                # Agent 交互
│   │
│   └── settings/              # 设置
│
└── platform/                  # 平台适配
    ├── macos/
    ├── windows/
    ├── android/
    └── ios/
```

### 3.3 状态管理

**状态管理方案**: **Riverpod**

#### 3.3.1 Provider 类型使用

| Provider 类型 | 用途 | 示例 |
|---------------|------|------|
| `Provider` | 只读数据、依赖注入 | 配置、常量 |
| `StateProvider` | 简单状态 | 当前选中项、开关状态 |
| `StateNotifierProvider` | 复杂状态逻辑 | 连接管理、消息列表 |
| `FutureProvider` | 异步数据获取 | Agent 列表加载 |
| `StreamProvider` | 实时数据流 | WebSocket 消息、连接状态 |

#### 3.3.2 状态分层

| 状态类型 | 管理方式 | 持久化 |
|----------|----------|--------|
| 连接状态 | StateNotifierProvider | SharedPreferences + 加密 |
| 消息状态 | StateNotifierProvider | SharedPreferences |
| Agent 状态 | StateProvider | 否 |
| 用户设置 | StateNotifierProvider | SharedPreferences |
| UI 状态 | StateProvider | 否 |

### 3.4 数据流

```
用户输入
    │
    ▼
┌──────────┐    验证     ┌──────────┐    发送     ┌──────────┐
│ Widget   │ ─────────► │ Provider │ ─────────► │   ACP    │
│          │            │ (Riverpod)│            │  Client  │
└──────────┘            └────┬─────┘            └────┬─────┘
                             │                       │
                             ▼                       ▼
                       ┌──────────┐            ┌──────────┐
                       │  Local   │            │WebSocket │
                       │  Cache   │            │Connection│
                       └──────────┘            └────┬─────┘
                                                    │
                                                    ▼
                                             ┌───────────┐
                                             │ OpenClaw  │
                                             │  Gateway  │
                                             └───────────┘
```

### 3.5 关键依赖

| 包名 | 用途 | 版本 |
|------|------|------|
| `flutter_riverpod` | 状态管理 | ^2.5.0 |
| `riverpod_annotation` | 代码生成 | ^2.3.0 |
| `web_socket_channel` | WebSocket 通信 | ^3.0.0 |
| `camera` | 相机访问 | ^0.11.0 |
| `image_picker` | 图片选择 | ^1.1.0 |
| `record` | 音频录制 | ^5.1.0 |
| `audioplayers` | 音频播放 | ^6.1.0 |
| `flutter_secure_storage` | 安全存储 | ^9.2.0 |
| `shared_preferences` | 本地存储 | ^2.3.0 |
| `dio` | HTTP 客户端 | ^5.5.0 |
| `connectivity_plus` | 网络状态 | ^6.0.0 |
| `flutter_localizations` | 国际化 | Flutter SDK |
| `intl` | 国际化工具 | ^0.19.0 |

---

## 4. 输入模块设计

### 4.1 文字输入

#### 4.1.1 技术实现

- 使用 `CupertinoTextField` 作为基础组件
- 支持多行文本 (`maxLines: null`)
- 实现字符计数和限制验证

#### 4.1.2 Provider 设计

```dart
// 文字输入状态
@riverpod
class TextInput extends _$TextInput {
  @override
  TextInputState build() => TextInputState.empty();
  
  void updateText(String text);
  void clear();
  void pasteFromClipboard();
}
```

### 4.2 图片输入

#### 4.2.1 技术实现

| 功能 | 实现方案 |
|------|----------|
| 相机拍摄 | `camera` 插件 |
| 相册选择 | `image_picker` 插件 |
| 拖放上传 | `desktop_drop` 插件 (桌面端) |
| 剪贴板粘贴 | `pasteboard` 插件 |

#### 4.2.2 图片处理流程

```dart
// 图片处理服务
class ImageProcessingService {
  /// 压缩图片
  Future<Uint8List> compress(Uint8List data, {int maxSizeMB = 10});
  
  /// 移除 EXIF 敏感数据
  Future<Uint8List> stripExif(Uint8List data);
  
  /// 生成缩略图
  Future<Uint8List> generateThumbnail(Uint8List data, {int maxSize = 200});
  
  /// 转换为 Base64
  String toBase64(Uint8List data);
}
```

#### 4.2.3 Provider 设计

```dart
@riverpod
class ImageInput extends _$ImageInput {
  @override
  ImageInputState build() => ImageInputState.empty();
  
  Future<void> pickFromGallery();
  Future<void> captureFromCamera();
  Future<void> addFromPath(String path);
  void removeImage(int index);
  Future<List<String>> toBase64List();
}
```

### 4.3 语音输入

#### 4.3.1 技术实现

| 功能 | 实现方案 |
|------|----------|
| 音频录制 | `record` 插件 |
| 音频播放 | `audioplayers` 插件 |
| 波形显示 | 自定义 `CustomPainter` |
| 后台录音 | 平台特定实现 |

#### 4.3.2 录音状态机

```dart
enum RecordingState {
  idle,
  recording,
  paused,
  preview,
}

@riverpod
class VoiceInput extends _$VoiceInput {
  @override
  VoiceInputState build() => VoiceInputState.idle();
  
  Future<void> startRecording();
  Future<void> stopRecording();
  Future<void> cancelRecording();
  Future<void> playPreview();
  Future<String?> toBase64();
}
```

#### 4.3.3 平台特定实现

| 平台 | 后台录音实现 |
|------|--------------|
| Android | Foreground Service + 通知 |
| iOS | Background Audio Session |
| macOS | 后台任务 |
| Windows | 后台任务 |

---

## 5. 连接模块设计

### 5.1 多连接管理

#### 5.1.1 数据模型

```dart
class ConnectionConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? token;
  final String? password;
  final String? defaultSessionKey;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? lastConnectedAt;
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticating,
  authenticated,
  error,
}
```

#### 5.1.2 Provider 设计

```dart
@riverpod
class ConnectionManager extends _$ConnectionManager {
  @override
  ConnectionManagerState build();
  
  // 连接管理
  Future<void> addConnection(ConnectionConfig config);
  Future<void> updateConnection(String id, ConnectionConfig config);
  Future<void> deleteConnection(String id);
  
  // 连接操作
  Future<void> connect(String id);
  Future<void> disconnect(String id);
  Future<void> switchConnection(String id);
  
  // 状态查询
  ConnectionStatus getStatus(String id);
  List<ConnectionConfig> getAllConnections();
  ConnectionConfig? getActiveConnection();
}
```

### 5.2 会话隔离

每个连接维护独立的：
- 会话历史缓存
- 草稿内容
- Agent 列表
- 会话键映射

---

## 6. 消息模块设计

### 6.1 消息模型

```dart
class Message {
  final String id;
  final String sessionId;
  final String connectionId;
  final MessageRole role;
  final List<ContentBlock> content;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;
}

enum MessageRole { user, assistant, system }

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}
```

### 6.2 Provider 设计

```dart
@riverpod
class MessageList extends _$MessageList {
  @override
  AsyncValue<List<Message>> build(String connectionId);
  
  Future<void> sendMessage(Message message);
  Future<void> retryMessage(String messageId);
  Future<void> loadHistory({int limit = 50});
  Future<List<Message>> search(String query);
}

@riverpod
Stream<Message> messageStream(MessageStreamRef ref, String connectionId) {
  // 监听 WebSocket 消息流
}
```

### 6.3 本地缓存

- 使用 `SharedPreferences` 存储最近消息
- 每个连接缓存上限: 1000 条消息
- 支持消息搜索

---

## 7. 非功能性目标

### 7.1 性能目标

| 指标 | 目标值 | 验证方法 |
|------|--------|----------|
| 冷启动时间 | < 2 秒 | Flutter DevTools Performance |
| 内存占用 (基线) | < 200MB | DevTools Memory |
| 内存占用 (峰值) | < 500MB | DevTools Memory |
| 图片 Base64 编码 | < 100ms/MB | 单元测试 |
| WebSocket 消息延迟 | < 100ms | 集成测试 |

### 7.2 可靠性目标

| 指标 | 目标值 | 验证方法 |
|------|--------|----------|
| 崩溃率 | < 0.1% | Firebase Crashlytics |
| 自动重连 | < 5 秒 | 集成测试 |
| 消息丢失率 | 0% | 端到端测试 |

### 7.3 安全实现

| 要求 | 实现方案 |
|------|----------|
| 凭证存储 | `flutter_secure_storage` |
| 传输加密 | TLS 1.3 (wss://) |
| 输入验证 | Domain 层验证器 |
| 日志脱敏 | Logger 过滤敏感信息 |

### 7.4 测试策略

| 测试类型 | 覆盖目标 | 工具 |
|----------|----------|------|
| 单元测试 | > 80% | `flutter_test` |
| Widget 测试 | 关键组件 | `flutter_test` |
| 集成测试 | 核心流程 | `integration_test` |
| 性能测试 | 关键指标 | DevTools |

---

## 8. UI/UX 技术实现

### 8.1 Cupertino 组件使用

| 组件 | 用途 |
|------|------|
| `CupertinoPageScaffold` | 页面骨架 |
| `CupertinoNavigationBar` | 导航栏 |
| `CupertinoTabBar` | 底部 Tab 栏 |
| `CupertinoListTile` | 列表项 |
| `CupertinoButton` | 按钮 |
| `CupertinoTextField` | 输入框 |
| `CupertinoAlertDialog` | 对话框 |
| `CupertinoActionSheet` | 操作表 |

### 8.2 国际化实现

```yaml
# l10n.yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```dart
// 使用
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.helloWorld);
```

### 8.3 主题配置

```dart
// Cupertino 主题
class AppTheme {
  static CupertinoThemeData get light => CupertinoThemeData(
    primaryColor: CupertinoColors.activeBlue,
    brightness: Brightness.light,
  );
  
  static CupertinoThemeData get dark => CupertinoThemeData(
    primaryColor: CupertinoColors.activeBlue,
    brightness: Brightness.dark,
  );
}
```

### 8.4 响应式布局

```dart
// 断点定义
class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

// 使用 LayoutBuilder 自适应
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= Breakpoints.expanded) {
      return ExpandedLayout();
    } else {
      return CompactLayout();
    }
  },
);
```

---

## 9. 附录

### 9.1 术语表

| 术语 | 定义 |
|------|------|
| ACP | Agent Client Protocol，OpenClaw 客户端协议 |
| NDJSON | Newline Delimited JSON，换行分隔的 JSON 格式 |
| Riverpod | Flutter 状态管理库，响应式依赖注入 |
| Cupertino | iOS 风格设计语言和 Flutter 组件库 |
| Provider | Riverpod 的核心概念，状态容器 |
| WebSocket | 全双工通信协议 |

### 9.2 参考文档

- [产品需求文档 (PRD)](./product-requirements.md)
- [OpenClaw 官网](https://openclaw.ai/)
- [OpenClaw ACP CLI 文档](https://docs.openclaw.ai/zh-CN/cli/acp)
- [ACP 技术规范](https://github.com/openclaw/openclaw/blob/main/docs.acp.md)
- [Riverpod 官方文档](https://riverpod.dev/)
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Cupertino 组件](https://api.flutter.dev/flutter/cupertino/cupertino-library.html)
- [Flutter 国际化](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)

### 9.3 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 从 requirements.md 拆分创建 | 架构师 |
| 1.0.1 | 2026-03-16 | 产品正式命名为 **ClawTalk** | 架构师 |

---

**文档结束**