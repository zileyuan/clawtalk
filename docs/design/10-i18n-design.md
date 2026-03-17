# ClawTalk 国际化设计文档

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [UI Components](04-ui-components.md)

---

## 目录

1. [概述](#1-概述)
2. [ARB 文件结构](#2-arb-文件结构)
3. [flutter_localizations 集成](#3-flutter_localizations-集成)
4. [语言切换机制](#4-语言切换机制)
5. [日期和数字格式化](#5-日期和数字格式化)
6. [RTL 语言支持](#6-rtl-语言支持)
7. [Provider 设计](#7-provider-设计)
8. [测试用例](#8-测试用例)
9. [附录](#9-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端的国际化（i18n）架构设计，包括：
- 多语言资源管理机制
- ARB 文件组织和命名规范
- flutter_localizations 集成方案
- 运行时语言切换策略
- RTL（从右到左）语言支持
- 日期、数字、货币格式化

### 1.2 支持语言

| 语言代码 | 语言 | 状态 | 文本方向 |
|----------|------|------|----------|
| `zh_CN` | 简体中文 | 主要 | LTR |
| `en_US` | 英语（美国） | 主要 | LTR |
| `ar` | 阿拉伯语 | 未来 | RTL |
| `he` | 希伯来语 | 未来 | RTL |

### 1.3 架构概览

```
┌─────────────────────────────────────────────────────────────┐
│                      国际化架构                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Presentation Layer                 │   │
│  │  Localizations.of(context) · LocaleProvider         │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   AppLocalizations                   │   │
│  │  · 生成的本地化类                                    │   │
│  │  · 类型安全的翻译访问                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   ARB 资源文件                       │   │
│  │  app_en.arb · app_zh.arb · app_ar.arb               │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   intl 格式化                        │   │
│  │  DateFormat · NumberFormat · Bidi                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 1.4 依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| `flutter_localizations` | SDK | 官方本地化支持 |
| `intl` | ^0.19.0 | 日期、数字格式化 |
| `flutter_riverpod` | ^2.4.0 | 状态管理 |
| `shared_preferences` | ^2.2.0 | 语言偏好持久化 |

---

## 2. ARB 文件结构

### 2.1 文件命名规范

```
l10n/
├── l10n.yaml              # 生成配置
├── app_en.arb            # 英文资源
├── app_zh.arb            # 中文资源
├── app_ar.arb            # 阿拉伯语（未来）
└── untranslated.json     # 未翻译键追踪
```

**命名规则**：
- 主文件：`app_<language_code>.arb`
- 语言代码遵循 IETF BCP 47 标准
- 区域变体：`app_en_US.arb`, `app_zh_CN.arb`

### 2.2 基础结构示例

```json
{
  "@@locale": "zh",
  "appTitle": "ClawTalk",
  "@appTitle": {
    "description": "应用标题",
    "type": "text"
  },

  "welcomeMessage": "欢迎使用 ClawTalk",
  "@welcomeMessage": {
    "description": "欢迎消息"
  },

  "buttonSend": "发送",
  "@buttonSend": {
    "description": "发送按钮文本"
  },

  "buttonCancel": "取消",
  "buttonConfirm": "确认",
  "buttonSave": "保存",
  "buttonDelete": "删除"
}
```

### 2.3 带参数的翻译

```json
{
  "messageCount": "你有 {count} 条新消息",
  "@messageCount": {
    "description": "消息数量提示",
    "placeholders": {
      "count": {
        "type": "int",
        "format": "compact"
      }
    }
  },

  "lastConnected": "上次连接：{time}",
  "@lastConnected": {
    "description": "上次连接时间",
    "placeholders": {
      "time": {
        "type": "DateTime",
        "format": "yMd"
      }
    }
  },

  "sessionDuration": "会话时长：{hours} 小时 {minutes} 分钟",
  "@sessionDuration": {
    "description": "会话持续时间",
    "placeholders": {
      "hours": {
        "type": "int"
      },
      "minutes": {
        "type": "int"
      }
    }
  }
}
```

### 2.4 复数形式

```json
{
  "unreadMessages": "{count, plural, =0{没有未读消息} =1{1 条未读消息} other{{count} 条未读消息}}",
  "@unreadMessages": {
    "description": "未读消息数量",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },

  "selectedSessions": "{count, plural, =0{未选择会话} =1{已选择 1 个会话} other{已选择 {count} 个会话}}",
  "@selectedSessions": {
    "description": "选中的会话数量"
  }
}
```

### 2.5 性别形式

```json
{
  "userWelcome": "{gender, select, male{欢迎先生} female{欢迎女士} other{欢迎}}",
  "@userWelcome": {
    "description": "根据性别显示欢迎语",
    "placeholders": {
      "gender": {
        "type": "String"
      }
    }
  }
}
```

### 2.6 按模块组织

```json
{
  "@@locale": "zh",
  
  "// Common": "通用",
  "common_ok": "确定",
  "common_cancel": "取消",
  "common_save": "保存",
  "common_delete": "删除",
  "common_edit": "编辑",
  "common_loading": "加载中...",
  "common_error": "出错了",
  "common_retry": "重试",

  "// Connection": "连接模块",
  "connection_title": "连接管理",
  "connection_add": "添加连接",
  "connection_edit": "编辑连接",
  "connection_name": "连接名称",
  "connection_host": "主机地址",
  "connection_port": "端口",
  "connection_token": "令牌",
  "connection_status_connected": "已连接",
  "connection_status_disconnected": "未连接",
  "connection_status_connecting": "连接中...",

  "// Messaging": "消息模块",
  "messaging_title": "消息",
  "messaging_input_placeholder": "输入消息...",
  "messaging_send": "发送",
  "messaging_attach": "附件",
  "messaging_recording": "录音中...",

  "// Settings": "设置模块",
  "settings_title": "设置",
  "settings_language": "语言",
  "settings_theme": "主题",
  "settings_notifications": "通知",
  "settings_about": "关于"
}
```

---

## 3. flutter_localizations 集成

### 3.1 l10n.yaml 配置

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated/l10n
synthetic-package: false
output-class: AppLocalizations
preferred-supported-locales:
  - zh
  - en
nullable-getter: false
untranslated-messages-file: lib/l10n/untranslated.json
format: true
```

### 3.2 pubspec.yaml 依赖

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  flutter_riverpod: ^2.4.0
  shared_preferences: ^2.2.0

flutter:
  generate: true  # 启用代码生成
```

### 3.3 MaterialApp 配置

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generated/l10n/app_localizations.dart';
import 'providers/locale_provider.dart';

class ClawTalkApp extends ConsumerWidget {
  const ClawTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'ClawTalk',
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      home: const HomePage(),
    );
  }
}
```

### 3.4 代码中使用

```dart
import 'generated/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Center(
        child: Column(
          children: [
            Text(l10n.welcomeMessage),
            ElevatedButton(
              onPressed: () {},
              child: Text(l10n.buttonSend),
            ),
            // 带参数的翻译
            Text(l10n.messageCount(5)),
            // 复数形式
            Text(l10n.unreadMessages(3)),
          ],
        ),
      ),
    );
  }
}
```

### 3.5 扩展方法封装

```dart
// lib/extensions/l10n_extension.dart
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// 使用
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.welcomeMessage);
  }
}
```

---

## 4. 语言切换机制

### 4.1 运行时切换

```dart
// lib/services/locale_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const String _localeKey = 'app_locale';
  
  final SharedPreferences _prefs;
  
  LocaleService(this._prefs);
  
  /// 获取当前保存的语言设置
  Locale? getSavedLocale() {
    final localeString = _prefs.getString(_localeKey);
    if (localeString == null) return null;
    
    final parts = localeString.split('_');
    if (parts.length == 1) {
      return Locale(parts[0]);
    }
    return Locale(parts[0], parts[1]);
  }
  
  /// 保存语言设置
  Future<void> saveLocale(Locale locale) async {
    final localeString = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await _prefs.setString(_localeKey, localeString);
  }
  
  /// 清除语言设置（跟随系统）
  Future<void> clearLocale() async {
    await _prefs.remove(_localeKey);
  }
  
  /// 获取系统语言
  static Locale getSystemLocale() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }
  
  /// 检查是否支持该语言
  static bool isSupported(Locale locale) {
    const supportedLocales = [
      Locale('zh', 'CN'),
      Locale('en', 'US'),
    ];
    
    return supportedLocales.any((supported) =>
        supported.languageCode == locale.languageCode);
  }
}
```

### 4.2 语言选择持久化

```dart
// lib/services/locale_service.dart（扩展）

/// 语言设置选项
enum LocaleMode {
  system,    // 跟随系统
  chinese,   // 简体中文
  english,   // 英文
}

extension LocaleModeExtension on LocaleMode {
  String get displayName {
    return switch (this) {
      LocaleMode.system => '跟随系统',
      LocaleMode.chinese => '简体中文',
      LocaleMode.english => 'English',
    };
  }
  
  Locale? get locale {
    return switch (this) {
      LocaleMode.system => null,
      LocaleMode.chinese => const Locale('zh', 'CN'),
      LocaleMode.english => const Locale('en', 'US'),
    };
  }
  
  static LocaleMode fromLocale(Locale? locale) {
    if (locale == null) return LocaleMode.system;
    if (locale.languageCode == 'zh') return LocaleMode.chinese;
    if (locale.languageCode == 'en') return LocaleMode.english;
    return LocaleMode.system;
  }
}

class LocaleService {
  static const String _localeModeKey = 'locale_mode';
  
  /// 获取语言模式
  LocaleMode getLocaleMode() {
    final modeString = _prefs.getString(_localeModeKey);
    return LocaleMode.values.firstWhere(
      (mode) => mode.name == modeString,
      orElse: () => LocaleMode.system,
    );
  }
  
  /// 保存语言模式
  Future<void> saveLocaleMode(LocaleMode mode) async {
    await _prefs.setString(_localeModeKey, mode.name);
  }
}
```

### 4.3 跟随系统设置

```dart
// lib/services/locale_service.dart（扩展）

class LocaleService {
  /// 解析系统语言为支持的语言
  Locale resolveSystemLocale() {
    final systemLocale = getSystemLocale();
    
    // 检查精确匹配
    if (isSupported(systemLocale)) {
      return systemLocale;
    }
    
    // 检查语言代码匹配
    final languageMatch = _getSupportedLocaleForLanguage(systemLocale.languageCode);
    if (languageMatch != null) {
      return languageMatch;
    }
    
    // 默认返回英文
    return const Locale('en', 'US');
  }
  
  Locale? _getSupportedLocaleForLanguage(String languageCode) {
    const supportedLocales = [
      Locale('zh', 'CN'),
      Locale('en', 'US'),
    ];
    
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == languageCode,
      orElse: () => const Locale('en', 'US'),
    );
  }
  
  /// 监听系统语言变化
  void listenToSystemLocaleChanges(VoidCallback onChanged) {
    WidgetsBinding.instance.platformDispatcher.onLocaleChanged = onChanged;
  }
}
```

---

## 5. 日期和数字格式化

### 5.1 intl 包使用

```dart
import 'package:intl/intl.dart';

class Formatters {
  /// 根据当前语言获取格式化器
  static DateFormat getDateFormat(String pattern, String locale) {
    return DateFormat(pattern, locale);
  }
  
  /// 格式化日期
  static String formatDate(
    DateTime date, {
    required String locale,
    String pattern = 'yMd',
  }) {
    return DateFormat(pattern, locale).format(date);
  }
  
  /// 格式化时间
  static String formatTime(
    DateTime time, {
    required String locale,
    bool use24Hour = false,
  }) {
    final pattern = use24Hour ? 'HH:mm' : 'h:mm a';
    return DateFormat(pattern, locale).format(time);
  }
  
  /// 格式化日期时间
  static String formatDateTime(
    DateTime dateTime, {
    required String locale,
    String? pattern,
  }) {
    final effectivePattern = pattern ?? 'yMd HH:mm';
    return DateFormat(effectivePattern, locale).format(dateTime);
  }
  
  /// 相对时间
  static String formatRelativeTime(
    DateTime dateTime, {
    required String locale,
  }) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 365) {
      return DateFormat('yMd', locale).format(dateTime);
    } else if (difference.inDays > 7) {
      return DateFormat('MMMd', locale).format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }
}
```

### 5.2 日期格式示例

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateFormatExamples extends StatelessWidget {
  final DateTime sampleDate = DateTime(2026, 3, 16, 14, 30);
  
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    
    return Column(
      children: [
        // 短日期格式
        Text(DateFormat.yMd(locale).format(sampleDate)),
        // 中文: 2026/3/16
        // 英文: 3/16/2026
        
        // 长日期格式
        Text(DateFormat.yMMMEd(locale).format(sampleDate)),
        // 中文: 2026年3月16日周一
        // 英文: Mon, Mar 16, 2026
        
        // 完整日期格式
        Text(DateFormat.yMMMMEEEEd(locale).format(sampleDate)),
        // 中文: 2026年3月16日星期一
        // 英文: Monday, March 16, 2026
        
        // 时间格式
        Text(DateFormat.jm(locale).format(sampleDate)),
        // 中文: 下午2:30
        // 英文: 2:30 PM
        
        // 24小时制
        Text(DateFormat.Hm(locale).format(sampleDate)),
        // 14:30
        
        // 日期时间组合
        Text(DateFormat('yyyy-MM-dd HH:mm', locale).format(sampleDate)),
        // 2026-03-16 14:30
      ],
    );
  }
}
```

### 5.3 数字格式示例

```dart
import 'package:intl/intl.dart';

class NumberFormatters {
  /// 格式化整数
  static String formatInteger(int number, String locale) {
    return NumberFormat.decimalPattern(locale).format(number);
  }
  // 1234567 -> 1,234,567 (英文) 或 1,234,567 (中文)
  
  /// 格式化小数
  static String formatDecimal(
    double number,
    String locale, {
    int decimalDigits = 2,
  }) {
    return NumberFormat.decimalPattern(locale)
        .format(number);
  }
  // 1234.56 -> 1,234.56
  
  /// 百分比
  static String formatPercent(
    double value,
    String locale, {
    int decimalDigits = 1,
  }) {
    return NumberFormat.percentPattern(locale)
        .format(value);
  }
  // 0.856 -> 85.6%
  
  /// 紧凑数字
  static String formatCompact(
    int number,
    String locale,
  ) {
    return NumberFormat.compact(locale: locale).format(number);
  }
  // 1500 -> 1.5K (英文) 或 1500万 (中文)
  
  /// 货币
  static String formatCurrency(
    double amount,
    String locale,
    String currencyCode,
  ) {
    return NumberFormat.currency(
      locale: locale,
      symbol: currencyCode,
    ).format(amount);
  }
  // 1234.5 -> $1,234.50 (英文) 或 ¥1,234.50 (中文)
  
  /// 文件大小
  static String formatFileSize(int bytes, String locale) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    final formatted = NumberFormat.decimalPattern(locale)
        .format(size);
    return '$formatted ${units[unitIndex]}';
  }
  // 1536000 -> 1.5 MB
}
```

### 5.4 格式化工具类

```dart
// lib/utils/formatters.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppFormatters {
  final String locale;
  
  AppFormatters(this.locale);
  
  /// 消息时间戳
  String messageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (messageDay == today) {
      // 今天只显示时间
      return DateFormat.jm(locale).format(timestamp);
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      // 昨天
      return '昨天 ${DateFormat.jm(locale).format(timestamp)}';
    } else {
      // 更早显示完整日期
      return DateFormat.yMd(locale).add_jm().format(timestamp);
    }
  }
  
  /// 会话时长
  String sessionDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
  
  /// 消息数量
  String messageCount(int count) {
    return NumberFormat.compact(locale: locale).format(count);
  }
  
  /// 连接延迟
  String connectionLatency(int milliseconds) {
    if (milliseconds < 1000) {
      return '${milliseconds}ms';
    }
    return '${(milliseconds / 1000).toStringAsFixed(1)}s';
  }
}
```

---

## 6. RTL 语言支持

### 6.1 TextDirection 检测

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DirectionalityUtils {
  /// 判断是否为 RTL 语言
  static bool isRtlLocale(Locale locale) {
    const rtlLanguages = ['ar', 'he', 'fa', 'ur', 'dv'];
    return rtlLanguages.contains(locale.languageCode);
  }
  
  /// 获取文本方向
  static TextDirection getTextDirection(Locale locale) {
    return isRtlLocale(locale) ? TextDirection.rtl : TextDirection.ltr;
  }
  
  /// 获取文本对齐方式
  static TextAlign getTextAlign(Locale locale) {
    return isRtlLocale(locale) ? TextAlign.right : TextAlign.left;
  }
  
  /// 包装 Directionality
  static Widget wrapDirectionality(
    BuildContext context,
    Widget child, {
    Locale? locale,
  }) {
    final effectiveLocale = locale ?? Localizations.localeOf(context);
    return Directionality(
      textDirection: getTextDirection(effectiveLocale),
      child: child,
    );
  }
}
```

### 6.2 布局镜像策略

```dart
import 'package:flutter/material.dart';

/// 支持 RTL 的边距
EdgeInsetsDirectional getDirectionalPadding(
  BuildContext context, {
  double start = 0,
  double top = 0,
  double end = 0,
  double bottom = 0,
}) {
  return EdgeInsetsDirectional.only(
    start: start,
    top: top,
    end: end,
    bottom: bottom,
  );
}

/// 支持 RTL 的位置
AlignmentDirectional getDirectionalAlignment(
  BuildContext context, {
  bool alignStart = true,
}) {
  return alignStart
      ? AlignmentDirectional.centerStart
      : AlignmentDirectional.centerEnd;
}

/// RTL 安全的行
class DirectionalRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  
  const DirectionalRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: Directionality.of(context),
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

/// RTL 安全的列表项
class DirectionalListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  
  const DirectionalListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
```

### 6.3 图标方向处理

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final bool shouldFlip;
  
  const DirectionalIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.shouldFlip = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    
    // 某些图标在 RTL 模式下需要翻转
    final needsFlip = shouldFlip && _isDirectionalIcon(icon);
    
    if (needsFlip && textDirection == TextDirection.rtl) {
      return Transform.flip(
        flipX: true,
        child: Icon(icon, size: size, color: color),
      );
    }
    
    return Icon(icon, size: size, color: color);
  }
  
  bool _isDirectionalIcon(IconData icon) {
    final directionalIcons = [
      Icons.arrow_back,
      Icons.arrow_forward,
      Icons.chevron_left,
      Icons.chevron_right,
      Icons.navigate_before,
      Icons.navigate_next,
      CupertinoIcons.back,
      CupertinoIcons.forward,
      CupertinoIcons.left_chevron,
      CupertinoIcons.right_chevron,
    ];
    return directionalIcons.contains(icon);
  }
}

/// RTL 安全的返回按钮
class DirectionalBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  
  const DirectionalBackButton({
    super.key,
    this.onPressed,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const DirectionalIcon(Icons.arrow_back),
      color: color,
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
    );
  }
}
```

### 6.4 Cupertino 组件 RTL 适配

```dart
import 'package:flutter/cupertino.dart';

/// RTL 安全的 CupertinoNavigationBar
class DirectionalCupertinoNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final Color? backgroundColor;
  
  const DirectionalCupertinoNavigationBar({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    
    return CupertinoNavigationBar(
      leading: isRtl ? trailing : leading,
      middle: middle,
      trailing: isRtl ? leading : trailing,
      backgroundColor: backgroundColor,
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(44);
  
  @override
  bool shouldFullyObstruct(BuildContext context) => true;
}

/// RTL 安全的 CupertinoTextField
class DirectionalCupertinoTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  
  const DirectionalCupertinoTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      textAlign: DirectionalityUtils.getTextAlign(
        Localizations.localeOf(context),
      ),
    );
  }
}
```

### 6.5 RTL 工具混入

```dart
// lib/mixins/rtl_aware_mixin.dart
import 'package:flutter/material.dart';

mixin RtlAwareMixin<T extends StatefulWidget> on State<T> {
  bool get isRtl {
    return Directionality.of(context) == TextDirection.rtl;
  }
  
  TextDirection get textDirection {
    return Directionality.of(context);
  }
  
  /// 根据方向获取值
  R directionalValue<R>(R ltrValue, R rtlValue) {
    return isRtl ? rtlValue : ltrValue;
  }
  
  /// 根据方向获取边距
  EdgeInsets directionalPadding({
    double horizontal = 0,
    double vertical = 0,
    double? start,
    double? end,
  }) {
    return EdgeInsetsDirectional.only(
      start: start ?? horizontal,
      end: end ?? horizontal,
      top: vertical,
      bottom: vertical,
    );
  }
}

// 使用示例
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with RtlAwareMixin {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: directionalPadding(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 内容自动适配 RTL
          Icon(directionalValue(Icons.arrow_forward, Icons.arrow_back)),
        ],
      ),
    );
  }
}
```

---

## 7. Provider 设计

### 7.1 LocaleProvider

```dart
// lib/providers/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/locale_service.dart';

/// Locale 状态
class LocaleState {
  final Locale? locale;
  final LocaleMode mode;
  
  const LocaleState({
    this.locale,
    this.mode = LocaleMode.system,
  });
  
  LocaleState copyWith({
    Locale? locale,
    LocaleMode? mode,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
      mode: mode ?? this.mode,
    );
  }
  
  /// 获取实际使用的 locale
  Locale get effectiveLocale {
    if (mode == LocaleMode.system || locale == null) {
      return LocaleService.getSystemLocale();
    }
    return locale!;
  }
  
  /// 是否跟随系统
  bool get isSystem => mode == LocaleMode.system;
}

/// Locale Provider
class LocaleNotifier extends StateNotifier<LocaleState> {
  final LocaleService _localeService;
  
  LocaleNotifier(this._localeService) : super(const LocaleState()) {
    _loadSavedLocale();
  }
  
  Future<void> _loadSavedLocale() async {
    final mode = _localeService.getLocaleMode();
    Locale? locale;
    
    if (mode != LocaleMode.system) {
      locale = mode.locale;
    }
    
    state = LocaleState(
      locale: locale,
      mode: mode,
    );
  }
  
  /// 设置为系统语言
  Future<void> useSystemLocale() async {
    await _localeService.saveLocaleMode(LocaleMode.system);
    await _localeService.clearLocale();
    
    state = LocaleState(
      locale: null,
      mode: LocaleMode.system,
    );
  }
  
  /// 设置简体中文
  Future<void> setChinese() async {
    const locale = Locale('zh', 'CN');
    await _localeService.saveLocaleMode(LocaleMode.chinese);
    await _localeService.saveLocale(locale);
    
    state = LocaleState(
      locale: locale,
      mode: LocaleMode.chinese,
    );
  }
  
  /// 设置英文
  Future<void> setEnglish() async {
    const locale = Locale('en', 'US');
    await _localeService.saveLocaleMode(LocaleMode.english);
    await _localeService.saveLocale(locale);
    
    state = LocaleState(
      locale: locale,
      mode: LocaleMode.english,
    );
  }
  
  /// 设置指定语言
  Future<void> setLocale(Locale locale) async {
    final mode = LocaleModeExtension.fromLocale(locale);
    await _localeService.saveLocaleMode(mode);
    await _localeService.saveLocale(locale);
    
    state = LocaleState(
      locale: locale,
      mode: mode,
    );
  }
  
  /// 切换语言
  Future<void> toggleLocale() async {
    if (state.mode == LocaleMode.chinese) {
      await setEnglish();
    } else {
      await setChinese();
    }
  }
}

/// Provider 定义
final localeServiceProvider = Provider<LocaleService>((ref) {
  throw UnimplementedError('需在 ProviderScope 中覆盖');
});

final localeProvider = StateNotifierProvider<LocaleNotifier, LocaleState>(
  (ref) {
    final localeService = ref.watch(localeServiceProvider);
    return LocaleNotifier(localeService);
  },
);

/// 便捷获取 locale
final currentLocaleProvider = Provider<Locale>((ref) {
  return ref.watch(localeProvider).effectiveLocale;
});

/// 是否 RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(currentLocaleProvider);
  return DirectionalityUtils.isRtlLocale(locale);
});
```

### 7.2 Provider 初始化

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/locale_provider.dart';
import 'services/locale_service.dart';
import 'claw_talk_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final localeService = LocaleService(prefs);
  
  runApp(
    ProviderScope(
      overrides: [
        localeServiceProvider.overrideWithValue(localeService),
      ],
      child: const ClawTalkApp(),
    ),
  );
}
```

### 7.3 语言选择 UI

```dart
// lib/presentation/widgets/language_selector.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeState = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguage),
      subtitle: Text(localeState.mode.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showLanguageDialog(context, ref, localeState),
    );
  }
  
  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    LocaleState currentState,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.settingsLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<LocaleMode>(
              title: const Text('跟随系统'),
              value: LocaleMode.system,
              groupValue: currentState.mode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).useSystemLocale();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<LocaleMode>(
              title: const Text('简体中文'),
              value: LocaleMode.chinese,
              groupValue: currentState.mode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setChinese();
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<LocaleMode>(
              title: const Text('English'),
              value: LocaleMode.english,
              groupValue: currentState.mode,
              onChanged: (value) {
                ref.read(localeProvider.notifier).setEnglish();
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. 测试用例

### 8.1 LocaleProvider 测试

```dart
// test/providers/locale_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clawtalk/providers/locale_provider.dart';
import 'package:clawtalk/services/locale_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocaleProvider', () {
    late ProviderContainer container;
    late MockSharedPreferences mockPrefs;
    late LocaleService localeService;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      localeService = LocaleService(mockPrefs);
      
      container = ProviderContainer(
        overrides: [
          localeServiceProvider.overrideWithValue(localeService),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始化时应为系统语言模式', () {
      // arrange
      when(() => mockPrefs.getString('locale_mode'))
          .thenReturn(null);
      
      // act
      final state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.system));
      expect(state.locale, isNull);
    });
    
    test('应正确加载保存的中文设置', () {
      // arrange
      when(() => mockPrefs.getString('locale_mode'))
          .thenReturn('chinese');
      when(() => mockPrefs.getString('app_locale'))
          .thenReturn('zh_CN');
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      container.invalidate(localeProvider);
      final state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.chinese));
      expect(state.locale, equals(const Locale('zh', 'CN')));
    });
    
    test('setChinese 应更新状态并持久化', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await container.read(localeProvider.notifier).setChinese();
      final state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.chinese));
      expect(state.locale, equals(const Locale('zh', 'CN')));
      verify(() => mockPrefs.setString('locale_mode', 'chinese')).called(1);
      verify(() => mockPrefs.setString('app_locale', 'zh_CN')).called(1);
    });
    
    test('setEnglish 应更新状态并持久化', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await container.read(localeProvider.notifier).setEnglish();
      final state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.english));
      expect(state.locale, equals(const Locale('en', 'US')));
    });
    
    test('toggleLocale 应在中英文间切换', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.getString('locale_mode'))
          .thenReturn('chinese');
      when(() => mockPrefs.getString('app_locale'))
          .thenReturn('zh_CN');
      
      container.invalidate(localeProvider);
      
      // act - 从中文切换到英文
      await container.read(localeProvider.notifier).toggleLocale();
      var state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.english));
      
      // act - 从英文切换到中文
      await container.read(localeProvider.notifier).toggleLocale();
      state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.chinese));
    });
    
    test('useSystemLocale 应清除语言设置', () async {
      // arrange
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await container.read(localeProvider.notifier).useSystemLocale();
      final state = container.read(localeProvider);
      
      // assert
      expect(state.mode, equals(LocaleMode.system));
      expect(state.locale, isNull);
      verify(() => mockPrefs.remove('app_locale')).called(1);
    });
  });
}
```

### 8.2 LocaleService 测试

```dart
// test/services/locale_service_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clawtalk/services/locale_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocaleService', () {
    late LocaleService localeService;
    late MockSharedPreferences mockPrefs;
    
    setUp(() {
      mockPrefs = MockSharedPreferences();
      localeService = LocaleService(mockPrefs);
    });
    
    test('getSavedLocale 应返回保存的语言设置', () {
      // arrange
      when(() => mockPrefs.getString('app_locale'))
          .thenReturn('zh_CN');
      
      // act
      final locale = localeService.getSavedLocale();
      
      // assert
      expect(locale, equals(const Locale('zh', 'CN')));
    });
    
    test('getSavedLocale 无保存设置时应返回 null', () {
      // arrange
      when(() => mockPrefs.getString('app_locale'))
          .thenReturn(null);
      
      // act
      final locale = localeService.getSavedLocale();
      
      // assert
      expect(locale, isNull);
    });
    
    test('saveLocale 应正确保存语言代码', () async {
      // arrange
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      
      // act
      await localeService.saveLocale(const Locale('en', 'US'));
      
      // assert
      verify(() => mockPrefs.setString('app_locale', 'en_US')).called(1);
    });
    
    test('isSupported 应正确识别支持的语言', () {
      expect(
        LocaleService.isSupported(const Locale('zh', 'CN')),
        isTrue,
      );
      expect(
        LocaleService.isSupported(const Locale('en', 'US')),
        isTrue,
      );
      expect(
        LocaleService.isSupported(const Locale('fr', 'FR')),
        isFalse,
      );
    });
    
    test('getLocaleMode 应返回正确的模式', () {
      // arrange
      when(() => mockPrefs.getString('locale_mode'))
          .thenReturn('chinese');
      
      // act
      final mode = localeService.getLocaleMode();
      
      // assert
      expect(mode, equals(LocaleMode.chinese));
    });
    
    test('getLocaleMode 无设置时应返回 system', () {
      // arrange
      when(() => mockPrefs.getString('locale_mode'))
          .thenReturn(null);
      
      // act
      final mode = localeService.getLocaleMode();
      
      // assert
      expect(mode, equals(LocaleMode.system));
    });
  });
}
```

### 8.3 格式化测试

```dart
// test/utils/formatters_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:clawtalk/utils/formatters.dart';

void main() {
  group('AppFormatters', () {
    late AppFormatters zhFormatters;
    late AppFormatters enFormatters;
    
    setUp(() {
      zhFormatters = AppFormatters('zh_CN');
      enFormatters = AppFormatters('en_US');
    });
    
    test('messageTimestamp 应正确格式化当天时间', () {
      // arrange
      final now = DateTime.now();
      final todayMessage = DateTime(now.year, now.month, now.day, 14, 30);
      
      // act
      final zhResult = zhFormatters.messageTimestamp(todayMessage);
      final enResult = enFormatters.messageTimestamp(todayMessage);
      
      // assert
      expect(zhResult, contains('14:30'));
      expect(enResult, contains('2:30'));
    });
    
    test('sessionDuration 应正确格式化时长', () {
      // act
      final shortDuration = zhFormatters.sessionDuration(
        const Duration(minutes: 45),
      );
      final longDuration = zhFormatters.sessionDuration(
        const Duration(hours: 2, minutes: 30),
      );
      
      // assert
      expect(shortDuration, equals('45m'));
      expect(longDuration, equals('2h 30m'));
    });
    
    test('messageCount 应正确格式化大数字', () {
      // act
      final zhResult = zhFormatters.messageCount(1500);
      final enResult = enFormatters.messageCount(1500);
      
      // assert
      expect(zhResult, isNotEmpty);
      expect(enResult, isNotEmpty);
    });
    
    test('connectionLatency 应正确格式化延迟', () {
      // act
      final ms = zhFormatters.connectionLatency(150);
      final seconds = zhFormatters.connectionLatency(1500);
      
      // assert
      expect(ms, equals('150ms'));
      expect(seconds, equals('1.5s'));
    });
  });
  
  group('NumberFormatters', () {
    test('formatInteger 应添加千分位分隔符', () {
      // act
      final result = NumberFormatters.formatInteger(1234567, 'en_US');
      
      // assert
      expect(result, equals('1,234,567'));
    });
    
    test('formatCompact 应使用紧凑格式', () {
      // act
      final enResult = NumberFormatters.formatCompact(1500, 'en_US');
      final zhResult = NumberFormatters.formatCompact(1500, 'zh_CN');
      
      // assert
      expect(enResult.toLowerCase(), contains('k'));
      expect(zhResult, isNotEmpty);
    });
    
    test('formatFileSize 应正确格式化文件大小', () {
      // act
      final bytes = NumberFormatters.formatFileSize(512, 'en_US');
      final kb = NumberFormatters.formatFileSize(1536, 'en_US');
      final mb = NumberFormatters.formatFileSize(1572864, 'en_US');
      
      // assert
      expect(bytes, contains('B'));
      expect(kb, contains('KB'));
      expect(mb, contains('MB'));
    });
  });
}
```

### 8.4 Widget 本地化测试

```dart
// test/widgets/localized_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clawtalk/generated/l10n/app_localizations.dart';

void main() {
  group('Localized Widget Tests', () {
    Widget buildLocalizedWidget(Locale locale) {
      return MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('en', 'US'),
        ],
        locale: locale,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: Column(
                children: [
                  Text(l10n.appTitle),
                  Text(l10n.welcomeMessage),
                  Text(l10n.messageCount(5)),
                ],
              ),
            );
          },
        ),
      );
    }
    
    testWidgets('应正确显示中文文本', (tester) async {
      // act
      await tester.pumpWidget(buildLocalizedWidget(const Locale('zh', 'CN')));
      await tester.pumpAndSettle();
      
      // assert
      expect(find.text('ClawTalk'), findsOneWidget);
      expect(find.textContaining('欢迎'), findsOneWidget);
    });
    
    testWidgets('应正确显示英文文本', (tester) async {
      // act
      await tester.pumpWidget(buildLocalizedWidget(const Locale('en', 'US')));
      await tester.pumpAndSettle();
      
      // assert
      expect(find.text('ClawTalk'), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });
  });
}
```

---

## 9. 附录

### 9.1 ARB 键命名规范

| 前缀 | 用途 | 示例 |
|------|------|------|
| `app_` | 应用级 | `appTitle`, `appVersion` |
| `common_` | 通用 | `common_ok`, `common_cancel` |
| `connection_` | 连接模块 | `connection_title` |
| `messaging_` | 消息模块 | `messaging_send` |
| `settings_` | 设置模块 | `settings_language` |
| `error_` | 错误消息 | `error_network`, `error_auth` |
| `validation_` | 验证消息 | `validation_required` |

### 9.2 术语表

| 术语 | 定义 |
|------|------|
| ARB | Application Resource Bundle，Flutter 本地化资源格式 |
| L10n | Localization 缩写，表示本地化 |
| i18n | Internationalization 缩写，表示国际化 |
| RTL | Right-to-Left，从右到左文本方向 |
| BCP 47 | 语言标签标准（如 zh-CN, en-US） |
| Locale | 语言区域标识，包含语言和区域代码 |
| Delegates | 本地化委托，提供资源加载和格式化 |

### 9.3 常用命令

```bash
# 生成本地化代码
flutter gen-l10n

# 运行测试
flutter test

# 生成并运行
flutter gen-l10n && flutter run

# 检查未翻译键
cat lib/l10n/untranslated.json

# 格式化 ARB 文件
flutter gen-l10n --format
```

### 9.4 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**
