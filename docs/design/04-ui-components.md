# ClawTalk UI 组件规范

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: UI 设计师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md)

---

## 目录

1. [概述](#1-概述)
2. [设计系统](#2-设计系统)
3. [核心组件](#3-核心组件)
4. [页面设计](#4-页面设计)
5. [导航设计](#5-导航设计)
6. [响应式布局](#6-响应式布局)
7. [性能监控设计](#7-性能监控设计)
8. [可访问性设计](#8-可访问性设计-wcag-21-aa)
9. [测试用例](#9-测试用例)
10. [附录](#10-附录)

---

## 1. 概述

### 1.1 设计原则

| 原则 | 说明 |
|------|------|
| 一致性 | 全平台统一 Cupertino 风格 |
| 简洁性 | 减少视觉噪音，突出核心功能 |
| 可访问性 | 支持 VoiceOver/TalkBack |
| 响应式 | 适配手机、平板、桌面 |

### 1.2 设计语言

**统一使用 Cupertino (iOS 风格) 设计语言**

优势:
- 跨平台一致性
- Flutter 原生支持
- 简洁优雅
- 动画流畅

---

## 2. 设计系统

### 2.1 颜色系统

```dart
// lib/core/themes/app_colors.dart

class AppColors {
  // 品牌色
  static const Color primary = CupertinoColors.activeBlue;
  static const Color secondary = CupertinoColors.systemGrey;
  
  // 语义色
  static const Color success = CupertinoColors.activeGreen;
  static const Color warning = CupertinoColors.systemOrange;
  static const Color error = CupertinoColors.systemRed;
  
  // 中性色
  static const Color background = CupertinoColors.systemBackground;
  static const Color surface = CupertinoColors.systemBackground;
  static const Color border = CupertinoColors.separator;
  
  // 文本色
  static const Color textPrimary = CupertinoColors.label;
  static const Color textSecondary = CupertinoColors.secondaryLabel;
  static const Color textTertiary = CupertinoColors.tertiaryLabel;
}

/// 深色模式颜色
class AppDarkColors {
  static const Color background = CupertinoColors.systemBackground.darkColor;
  static const Color surface = CupertinoColors.secondarySystemBackground.darkColor;
  // ... 其他颜色
}
```

### 2.2 字体系统

```dart
// lib/core/themes/app_text_styles.dart

class AppTextStyles {
  // 标题
  static const TextStyle headline1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  // 正文
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  // 标签
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
```

### 2.3 间距系统

```dart
// lib/core/constants/app_spacing.dart

class AppSpacing {
  // 基础单位
  static const double unit = 4.0;
  
  // 常用间距
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // 组件内边距
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
}
```

### 2.4 圆角系统

```dart
// lib/core/constants/app_border_radius.dart

class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
  
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
}
```

---

## 3. 核心组件

### 3.1 CTButton - 按钮

```
┌─────────────────────────────────────┐
│                                     │
│           Button Text               │
│                                     │
└─────────────────────────────────────┘
```

**规格**:

| 属性 | 值 |
|------|-----|
| 高度 | 44dp |
| 最小宽度 | 80dp |
| 圆角 | 10dp |
| 内边距 | 16dp 水平 |
| 字体 | 17pt, Medium |

**变体**:

| 类型 | 背景 | 文字 |
|------|------|------|
| Primary | primary | white |
| Secondary | systemGrey5 | primary |
| Destructive | systemRed | white |
| Text | transparent | primary |

```dart
/// CTButton 使用示例
CTButton(
  text: '连接',
  onPressed: () => _connect(),
),
```

### 3.2 CTTextField - 文本输入框

```
┌─────────────────────────────────────┐
│ Placeholder                         │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

**规格**:

| 属性 | 值 |
|------|-----|
| 高度 | 44dp (单行) |
| 圆角 | 10dp |
| 内边距 | 12dp |
| 字体 | 17pt |
| 边框 | 无 / 1px grey |

**特性**:
- 支持多行
- 支持字数统计
- 支持清除按钮
- 支持右键菜单

```dart
/// CTTextField 使用示例
CTTextField(
  placeholder: '输入消息...',
  maxLines: null,
  maxLength: 10000,
  onChanged: (text) => _updateText(text),
),
```

### 3.3 CTConnectionCard - 连接卡片

```
┌─────────────────────────────────────────────┐
│ 🟢 我的 Gateway                             │
│     wss://gateway.local:18789               │
│     已认证 · 最后连接: 2分钟前               │
└─────────────────────────────────────────────┘
```

**元素**:

| 元素 | 字体 | 颜色 |
|------|------|------|
| 名称 | headline3 | textPrimary |
| 地址 | bodySecondary | textSecondary |
| 状态 | caption | textSecondary |
| 状态图标 | - | success/error |

**状态指示器**:

| 状态 | 颜色 |
|------|------|
| 已认证 | activeGreen |
| 已连接 | activeBlue |
| 未连接 | systemGrey |
| 错误 | systemRed |

### 3.4 CTMessageBubble - 消息气泡

**用户消息**:

```
┌─────────────────────────────────────┐
│                                     │
│  Hello, this is my message          │
│                                     │
└─────────────────────────────────────┘
                          ✓✓ 10:30
```

**助手消息**:

```
┌─────────────────────────────────────┐
│                                     │
│  Hello! How can I help you?         │
│                                     │
└─────────────────────────────────────┘
```

**规格**:

| 属性 | 用户消息 | 助手消息 |
|------|----------|----------|
| 背景 | primary | systemGrey5 |
| 文字 | white | textPrimary |
| 圆角 | 18dp | 18dp |
| 最大宽度 | 80% | 80% |
| 内边距 | 12dp | 12dp |

### 3.5 CTAttachmentPreview - 附件预览

**图片预览**:

```
┌─────────────────────────────────────┐
│                                     │
│   ┌───────────┐                     │
│   │           │                     │
│   │   Image   │                     │
│   │           │                     │
│   └───────────┘                     │
│   image.jpg · 1.2MB        ✕        │
└─────────────────────────────────────┘
```

**语音预览**:

```
┌─────────────────────────────────────┐
│ 🎤  ▶ ━━━━━━━━━━○─────────  0:32    │
│                             ✕        │
└─────────────────────────────────────┘
```

### 3.6 CTRouteAwareScaffold - 页面骨架

```
┌─────────────────────────────────────┐
│ ◀  Title                      操作  │ ← NavigationBar
├─────────────────────────────────────┤
│                                     │
│                                     │
│            Content                  │
│                                     │
│                                     │
├─────────────────────────────────────┤
│   Tab1    Tab2    Tab3              │ ← TabBar (可选)
└─────────────────────────────────────┘
```

---

## 4. 页面设计

### 4.1 连接列表页 (ConnectionListScreen)

**手机端**:

```
┌─────────────────────────────────────────┐
│ ◀  连接管理                        添加 │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🟢 我的 Gateway                 │   │
│  │     wss://gateway.local:18789   │   │
│  │     已认证 · 2分钟前            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⚪ 测试服务器                    │   │
│  │     wss://test.example.com:18789│   │
│  │     未连接                      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ ⚪ 生产环境                      │   │
│  │     wss://prod.example.com:18789│   │
│  │     未连接                      │   │
│  └─────────────────────────────────┘   │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│   连接      会话      设置              │
└─────────────────────────────────────────┘
```

**平板/桌面端**:

```
┌────────────┬────────────────────────────────────────┐
│            │ ◀  连接管理                      添加 │
│  连接      ├────────────────────────────────────────┤
│            │                                        │
│  会话      │  ┌────────────────────────────────┐   │
│            │  │ 🟢 我的 Gateway                │   │
│  设置      │  │     wss://gateway.local:18789  │   │
│            │  │     已认证 · 2分钟前           │   │
│            │  └────────────────────────────────┘   │
│            │                                        │
│            │  ┌────────────────────────────────┐   │
│            │  │ ⚪ 测试服务器                   │   │
│            │  │     wss://test.example.com:... │   │
│            │  └────────────────────────────────┘   │
│            │                                        │
└────────────┴────────────────────────────────────────┘
```

### 4.2 会话页面 (ChatScreen)

```
┌─────────────────────────────────────────┐
│ ◀  Main Agent                    [Agent]│
├─────────────────────────────────────────┤
│                                         │
│  Agent: Hello! How can I help you?     │
│                                         │
│                              10:30      │
│                                         │
│           User: I need help with...     │
│                                         │
│                              10:31      │
│                                         │
│  Agent: Sure! Let me help you...        │
│  ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░                  │
│                                         │
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 输入消息...              📷 │ 🎤 │ ➤ │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### 4.3 设置页面 (SettingsScreen)

```
┌─────────────────────────────────────────┐
│ ◀  设置                                 │
├─────────────────────────────────────────┤
│                                         │
│  外观                                   │
│  ┌─────────────────────────────────────┐│
│  │ 主题                      跟随系统 >││
│  │ 语言                      中文     >││
│  └─────────────────────────────────────┘│
│                                         │
│  通知                                   │
│  ┌─────────────────────────────────────┐│
│  │ 推送通知                     开关  ││
│  └─────────────────────────────────────┘│
│                                         │
│  数据                                   │
│  ┌─────────────────────────────────────┐│
│  │ 清除缓存                           ││
│  │ 清除所有数据                       ││
│  └─────────────────────────────────────┘│
│                                         │
│  关于                                   │
│  ┌─────────────────────────────────────┐│
│  │ 版本                      1.0.0    ││
│  │ 开源许可证                 >       ││
│  └─────────────────────────────────────┘│
│                                         │
└─────────────────────────────────────────┘
```

---

## 5. 导航设计

### 5.1 导航结构

```
┌─────────────────────────────────────────────────────────────┐
│                      导航层次结构                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     ┌─────────────┐                         │
│                     │   MainApp   │                         │
│                     └──────┬──────┘                         │
│                            │                                │
│           ┌────────────────┼────────────────┐               │
│           │                │                │               │
│           ▼                ▼                ▼               │
│    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│    │ConnectionTab│  │  ChatTab    │  │ SettingsTab │        │
│    └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│           │                │                │               │
│           ▼                ▼                ▼               │
│    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│    │ConnectionList│  │  ChatScreen │  │SettingsScreen│        │
│    └──────┬──────┘  └──────┬──────┘  └─────────────┘        │
│           │                │                                 │
│           │                ├─────────────────┐               │
│           │                │                 │               │
│           ▼                ▼                 ▼               │
│    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│    │AddConnection│  │ AgentSelect │  │ ImagePreview│        │
│    └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 5.2 路由定义

```dart
// lib/core/navigation/app_router.dart

enum AppRoute {
  connectionList,
  addConnection,
  editConnection,
  chat,
  agentSelect,
  settings,
  imagePreview,
  voicePreview,
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoute.connectionList:
        return CupertinoPageRoute(
          builder: (_) => const ConnectionListScreen(),
        );
        
      case AppRoute.addConnection:
        return CupertinoPageRoute(
          builder: (_) => const AddConnectionScreen(),
        );
        
      case AppRoute.chat:
        final args = settings.arguments as ChatScreenArgs;
        return CupertinoPageRoute(
          builder: (_) => ChatScreen(
            connectionId: args.connectionId,
            sessionId: args.sessionId,
          ),
        );
        
      // ... 其他路由
    }
  }
}
```

### 5.3 Tab 导航

```dart
// lib/main.dart

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.link),
            label: '连接',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chat_bubble_2),
            label: '会话',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: '设置',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return switch (index) {
              0 => const ConnectionListScreen(),
              1 => const ChatScreen(),
              2 => const SettingsScreen(),
              _ => const SizedBox.shrink(),
            };
          },
        );
      },
    );
  }
}
```

---

## 6. 响应式布局

### 6.1 断点定义

```dart
// lib/core/constants/breakpoints.dart

class Breakpoints {
  /// 手机 (0-599)
  static const double compact = 600;
  
  /// 大屏手机/小平板 (600-839)
  static const double medium = 840;
  
  /// 平板/桌面 (840+)
  static const double expanded = 1200;
}

extension BuildContextX on BuildContext {
  bool get isCompact => MediaQuery.sizeOf(this).width < Breakpoints.compact;
  bool get isMedium => MediaQuery.sizeOf(this).width >= Breakpoints.compact 
      && MediaQuery.sizeOf(this).width < Breakpoints.medium;
  bool get isExpanded => MediaQuery.sizeOf(this).width >= Breakpoints.medium;
}
```

### 6.2 响应式布局组件

```dart
// lib/core/widgets/responsive_layout.dart

class ResponsiveLayout extends StatelessWidget {
  final Widget compact;
  final Widget? medium;
  final Widget? expanded;
  
  const ResponsiveLayout({
    required this.compact,
    this.medium,
    this.expanded,
  });
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Breakpoints.medium) {
          return expanded ?? medium ?? compact;
        }
        if (constraints.maxWidth >= Breakpoints.compact) {
          return medium ?? compact;
        }
        return compact;
      },
    );
  }
}
```

### 6.3 使用示例

```dart
ResponsiveLayout(
  compact: MobileLayout(),      // 手机布局
  medium: TabletLayout(),       // 平板布局
  expanded: DesktopLayout(),    // 桌面布局
)
```

---

## 7. 性能监控设计

### 7.1 性能指标定义

| 指标 | 目标值 | 测量方法 |
|------|--------|----------|
| 帧率 (FPS) | ≥ 60 FPS | Flutter DevTools |
| UI 线程延迟 | < 16ms | Performance Overlay |
| 内存占用 (基线) | < 200MB | DevTools Memory |
| 内存占用 (峰值) | < 500MB | DevTools Memory |
| 图片加载时间 | < 500ms | Stopwatch |
| WebSocket 延迟 | < 100ms | Time diff |

### 7.2 性能监控工具

```dart
// lib/core/utils/performance_monitor.dart

/// 性能监控器
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._();
  
  /// 记录操作耗时
  Future<T> track<T>(String operation, Future<T> Function() action) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      _log(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      _log('$operation (error)', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }
  
  /// 同步操作计时
  T trackSync<T>(String operation, T Function() action) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = action();
      stopwatch.stop();
      _log(operation, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e) {
      stopwatch.stop();
      _log('$operation (error)', stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }
  
  void _log(String operation, int milliseconds) {
    if (kDebugMode) {
      print('[Perf] $operation: ${milliseconds}ms');
    }
  }
}
```

### 7.3 Debug Overlay 设计

```
┌─────────────────────────────────────────────────────────────┐
│  [FPS: 60] [Memory: 128MB] [Network: 12ms]      [×]       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                      应用内容                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

```dart
/// Debug Overlay Widget
class DebugOverlay extends StatelessWidget {
  final Widget child;
  
  const DebugOverlay({required this.child});
  
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    
    return Stack(
      children: [
        child,
        Positioned(
          top: MediaQuery.of(context).padding.top,
          left: 0,
          right: 0,
          child: _buildStatsBar(),
        ),
      ],
    );
  }
  
  Widget _buildStatsBar() {
    return Consumer(
      builder: (context, ref, child) {
        final fps = ref.watch(fpsProvider);
        final memory = ref.watch(memoryProvider);
        final network = ref.watch(networkLatencyProvider);
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: Colors.black54,
          child: Row(
            children: [
              _StatItem(label: 'FPS', value: '$fps'),
              _StatItem(label: 'Memory', value: '${memory}MB'),
              _StatItem(label: 'Network', value: '${network}ms'),
            ],
          ),
        );
      },
    );
  }
}
```

### 7.4 性能预算

| 操作 | 预算 |
|------|------|
| 页面首次渲染 | < 100ms |
| 列表滚动帧率 | ≥ 60 FPS |
| 图片加载 | < 500ms |
| 网络请求 | < 1s |
| 流式消息渲染 | < 50ms/chunk |

### 7.5 性能优化策略

#### 图片优化
- 使用 `cached_network_image` 缓存
- 缩略图预加载
- 懒加载长列表图片

#### 列表优化
- 使用 `ListView.builder`
- 实现 `AutomaticKeepAliveClientMixin`
- 避免在 build 中创建对象

#### 状态管理优化
- 使用 `select` 精确订阅
- 避免全局重建
- 合并多个 Provider 更新

### 7.6 监控集成

```dart
// main.dart

void main() {
  if (kDebugMode) {
    // 启用性能叠加层
    debugProfileBuildsEnabled = true;
    debugProfilePaintsEnabled = true;
  }
  
  runApp(
    ProviderScope(
      child: DebugOverlay(
        child: ClawTalkApp(),
      ),
    ),
  );
}
```

---

## 8. 可访问性设计 (WCAG 2.1 AA)

### 8.1 设计原则

| 原则 | 说明 |
|------|------|
| 可感知 | 信息必须可被用户感知 |
| 可操作 | 界面元素必须可操作 |
| 可理解 | 信息和操作必须可理解 |
| 健壮性 | 兼容辅助技术 |

### 8.2 屏幕阅读器支持

#### 平台支持

| 平台 | 屏幕阅读器 |
|------|------------|
| iOS | VoiceOver |
| Android | TalkBack |
| macOS | VoiceOver |
| Windows | NVDA / Narrator |

#### 语义标签规范

```dart
/// 组件语义标签示例

// 按钮
CupertinoButton(
  semanticsLabel: '发送消息',
  semanticsHint: '双击发送当前消息',
  child: Icon(CupertinoIcons.paperplane),
)

// 输入框
CupertinoTextField(
  semanticsLabel: '消息输入框',
  semanticsHint: '输入要发送的消息',
  placeholder: '输入消息...',
)

// 列表项
Semantics(
  label: '连接: ${config.name}',
  hint: '状态: ${statusText}',
  button: true,
  child: ConnectionCard(config: config),
)

// 状态指示器
Semantics(
  label: '连接状态: $statusText',
  child: ConnectionStatusIndicator(status: status),
)
```

### 8.3 焦点管理

```dart
/// 焦点遍历顺序
class FocusTraversalOrder {
  static const connectionList = 1;
  static const addConnection = 2;
  static const messageInput = 3;
  static const sendButton = 4;
}

// 使用 FocusNode 管理焦点
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageFocusNode = FocusNode();
  final _sendFocusNode = FocusNode();
  
  @override
  void dispose() {
    _messageFocusNode.dispose();
    _sendFocusNode.dispose();
    super.dispose();
  }
  
  void _focusMessageInput() {
    _messageFocusNode.requestFocus();
  }
}
```

### 8.4 颜色对比度

#### WCAG 2.1 AA 要求

| 元素类型 | 最小对比度 |
|----------|------------|
| 正文文本 | 4.5:1 |
| 大文本 (≥18pt 或 ≥14pt 粗体) | 3:1 |
| UI 组件 | 3:1 |
| 焦点指示器 | 3:1 |

#### 颜色对比度验证

```dart
// 颜色定义时确保对比度
class AppColors {
  // 主文本 - 对比度 7:1 ✓
  static const textPrimary = CupertinoColors.label;
  
  // 次要文本 - 对比度 4.5:1 ✓
  static const textSecondary = CupertinoColors.secondaryLabel;
  
  // 错误文本 - 对比度 4.5:1 ✓
  static const error = CupertinoColors.systemRed;
  
  // 链接文本 - 对比度 4.5:1 ✓
  static const link = CupertinoColors.activeBlue;
}
```

### 8.5 触摸目标尺寸

#### 最小尺寸要求

| 要求 | 尺寸 |
|------|------|
| 最小触摸目标 | 44x44 pt |
| 推荐触摸目标 | 48x48 pt |
| 目标间距 | ≥ 8pt |

```dart
// 确保按钮满足最小尺寸
CupertinoButton(
  minSize: 44, // Cupertino 默认 44
  padding: EdgeInsets.all(12),
  child: Icon(CupertinoIcons.add),
)

// 小图标需要扩展触摸区域
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () {},
  child: Container(
    width: 44,  // 扩展触摸区域
    height: 44,
    alignment: Alignment.center,
    child: Icon(CupertinoIcons.close, size: 20),
  ),
)
```

### 8.6 动画与运动

#### 减少动画选项

```dart
// 检测用户偏好
MediaQuery.of(context).accessibleNavigation // 减少动画
MediaQuery.of(context).disableAnimations // 禁用动画

// 条件动画
AnimatedContainer(
  duration: MediaQuery.of(context).disableAnimations 
      ? Duration.zero 
      : Duration(milliseconds: 200),
  child: ...,
)
```

### 8.7 无障碍测试清单

- [ ] VoiceOver/TalkBack 可正确朗读所有元素
- [ ] 焦点顺序符合视觉顺序
- [ ] 所有交互元素可通过键盘操作
- [ ] 颜色对比度符合 WCAG 2.1 AA
- [ ] 触摸目标尺寸 ≥ 44x44 pt
- [ ] 动画尊重减少动画偏好
- [ ] 错误信息清晰且可被朗读
- [ ] 表单标签与输入框关联

---

## 9. 测试用例

### 9.1 组件测试

```dart
void main() {
  group('CTButton', () {
    testWidgets('应显示按钮文字', (tester) async {
      await tester.pumpWidget(CupertinoApp(
        home: CTButton(text: '测试按钮', onPressed: () {}),
      ));
      
      expect(find.text('测试按钮'), findsOneWidget);
    });
    
    testWidgets('点击应触发回调', (tester) async {
      var pressed = false;
      
      await tester.pumpWidget(CupertinoApp(
        home: CTButton(
          text: '按钮',
          onPressed: () => pressed = true,
        ),
      ));
      
      await tester.tap(find.byType(CTButton));
      
      expect(pressed, isTrue);
    });
    
    testWidgets('禁用状态不应响应点击', (tester) async {
      var pressed = false;
      
      await tester.pumpWidget(CupertinoApp(
        home: CTButton(
          text: '按钮',
          enabled: false,
          onPressed: () => pressed = true,
        ),
      ));
      
      await tester.tap(find.byType(CTButton));
      
      expect(pressed, isFalse);
    });
  });
}
```

### 9.2 页面测试

```dart
void main() {
  group('ConnectionListScreen', () {
    testWidgets('应显示添加按钮', (tester) async {
      await tester.pumpWidget(CupertinoApp(
        home: ConnectionListScreen(),
      ));
      
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });
    
    testWidgets('应显示连接列表', (tester) async {
      // 需要 mock provider
      await tester.pumpWidget(CupertinoApp(
        home: ProviderScope(
          overrides: [
            connectionListProvider.overrideWith(
              () => MockConnectionList([
                ConnectionConfig(id: '1', name: 'Test', host: 'test.com', createdAt: DateTime.now()),
              ]),
            ),
          ],
          child: ConnectionListScreen(),
        ),
      ));
      
      await tester.pumpAndSettle();
      
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
```

---

## 10. 附录

### 10.1 组件清单

| 组件 | 文件 | 用途 |
|------|------|------|
| CTButton | button.dart | 按钮 |
| CTTextField | text_field.dart | 文本输入 |
| CTConnectionCard | connection_card.dart | 连接卡片 |
| CTMessageBubble | message_bubble.dart | 消息气泡 |
| CTAttachmentPreview | attachment_preview.dart | 附件预览 |
| CTStatusIndicator | status_indicator.dart | 状态指示器 |
| CTEmptyState | empty_state.dart | 空状态 |

### 10.2 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | UI 设计师 |

---

**文档结束**