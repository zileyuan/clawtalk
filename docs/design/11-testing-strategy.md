# ClawTalk 测试策略文档

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md)

---

## 目录

1. [概述](#1-概述)
2. [测试哲学](#2-测试哲学)
3. [测试金字塔](#3-测试金字塔)
4. [测试分类](#4-测试分类)
5. [Mock 策略](#5-mock-策略)
6. [覆盖率要求](#6-覆盖率要求)
7. [CICD 集成](#7-cicd-集成)
8. [测试用例模板](#8-测试用例模板)
9. [附录](#9-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 项目的测试策略，包括：
- 测试方法论
- 测试分类与优先级
- Mock 和 Stub 策略
- 覆盖率要求
- CI/CD 集成

### 1.2 测试目标

| 目标 | 描述 |
|------|------|
| 质量保证 | 确保代码符合需求规格 |
| 回归保护 | 防止已有功能被破坏 |
| 文档作用 | 测试即文档，展示预期行为 |
| 设计驱动 | TDD 驱动更好的设计 |

### 1.3 测试范围

```
┌─────────────────────────────────────────────────────────────┐
│                      测试范围                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Presentation Layer                 │   │
│  │  • Widget Tests (组件渲染、交互)                     │   │
│  │  • Provider Tests (状态管理)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Domain Layer                      │   │
│  │  • Unit Tests (实体、值对象)                         │   │
│  │  • Use Case Tests (业务逻辑)                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                     Data Layer                       │   │
│  │  • Repository Tests (数据访问)                       │   │
│  │  • API Client Tests (网络通信)                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                  Integration Tests                   │   │
│  │  • 端到端测试 (完整用户流程)                         │   │
│  │  • 平台集成测试                                      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 测试哲学

### 2.1 TDD 工作流

```
┌─────────────────────────────────────────────────────────────┐
│                    TDD 循环                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                     ┌─────────┐                             │
│                     │  RED    │                             │
│                     │ 写失败  │                             │
│                     │ 测试    │                             │
│                     └────┬────┘                             │
│                          │                                  │
│                          ▼                                  │
│                     ┌─────────┐                             │
│           ┌────────│  GREEN  │────────┐                     │
│           │        │ 写最少  │        │                     │
│           │        │ 代码    │        │                     │
│           │        └────┬────┘        │                     │
│           │             │             │                     │
│           │             ▼             │                     │
│           │        ┌─────────┐        │                     │
│           │        │REFACTOR │        │                     │
│           └───────►│ 重构    │◄───────┘                     │
│                    │ 代码    │                               │
│                    └─────────┘                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 TDD 原则

| 原则 | 说明 |
|------|------|
| 先写测试 | 在写代码前先写失败的测试 |
| 最小实现 | 只写足以通过测试的代码 |
| 重构 | 通过测试后优化代码结构 |
| 快速反馈 | 测试应快速执行，提供即时反馈 |

### 2.3 GIVEN-WHEN-THEN 模式

```dart
test('应正确验证用户输入', () {
  // GIVEN (前置条件)
  final validator = InputValidator();
  final input = '';
  
  // WHEN (执行操作)
  final result = validator.validate(input);
  
  // THEN (验证结果)
  expect(result.isValid, isFalse);
  expect(result.error, equals('输入不能为空'));
});
```

---

## 3. 测试金字塔

### 3.1 层次分布

```
                    ┌───────────┐
                    │   E2E     │  10%
                    │  Integration│
                    │   Tests   │
                    ├───────────┤
                    │  Widget   │  20%
                    │  Tests    │
                    ├───────────┤
                    │           │
                    │   Unit    │  70%
                    │  Tests    │
                    │           │
                    └───────────┘
```

### 3.2 各层职责

| 层次 | 比例 | 执行时间 | 目的 |
|------|------|----------|------|
| 单元测试 | 70% | 毫秒级 | 测试独立单元逻辑 |
| Widget 测试 | 20% | 秒级 | 测试 UI 组件行为 |
| 集成测试 | 10% | 分钟级 | 测试完整流程 |

### 3.3 测试命名规范

```dart
// 格式: test('should [expected behavior] when [condition]', () {});

// 好的命名
test('should return true when input is valid', () {});
test('should throw ValidationException when name is empty', () {});
test('should emit [Connecting, Connected] when connect succeeds', () {});

// 不好的命名
test('test connection', () {});
test('works correctly', () {});
test('error case', () {});
```

---

## 4. 测试分类

### 4.1 单元测试

**定义**: 测试独立的代码单元（函数、类、方法）

**特点**:
- 不依赖外部系统
- 执行快速
- 隔离性强

**示例目录结构**:
```
test/
├── unit/
│   ├── core/
│   │   ├── models/
│   │   │   ├── connection_config_test.dart
│   │   │   ├── message_test.dart
│   │   │   └── content_block_test.dart
│   │   └── utils/
│   │       └── validators_test.dart
│   ├── features/
│   │   ├── connection/
│   │   │   └── providers/
│   │   │       └── connection_manager_test.dart
│   │   └── messaging/
│   │       └── providers/
│   │           └── message_list_test.dart
│   └── acp/
│       ├── message_codec_test.dart
│       └── event_dispatcher_test.dart
```

### 4.2 Widget 测试

**定义**: 测试 Flutter Widget 的渲染和交互

**特点**:
- 测试 UI 组件
- 模拟用户交互
- 验证渲染结果

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:clawtalk/features/connection/presentation/widgets/connection_card.dart';

void main() {
  group('ConnectionCard', () {
    testWidgets('应显示连接名称和状态', (tester) async {
      // arrange
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test Gateway',
        host: 'gateway.example.com',
        port: 18789,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConnectionCard(config: config),
        ),
      ));
      
      // assert
      expect(find.text('Test Gateway'), findsOneWidget);
      expect(find.text('wss://gateway.example.com:18789'), findsOneWidget);
    });
    
    testWidgets('点击应触发 onTap 回调', (tester) async {
      // arrange
      var tapped = false;
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test',
        host: 'gateway.example.com',
        port: 18789,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConnectionCard(
            config: config,
            onTap: () => tapped = true,
          ),
        ),
      ));
      
      await tester.tap(find.byType(ConnectionCard));
      
      // assert
      expect(tapped, isTrue);
    });
    
    testWidgets('已认证状态应显示绿色指示器', (tester) async {
      // arrange
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test',
        host: 'gateway.example.com',
        port: 18789,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ConnectionCard(
            config: config,
            status: ConnectionStatus.authenticated,
          ),
        ),
      ));
      
      // assert
      final indicator = tester.widget<Container>(
        find.byKey(const Key('status_indicator')),
      );
      expect(
        (indicator.decoration as BoxDecoration).color,
        equals(CupertinoColors.activeGreen),
      );
    });
  });
}
```

### 4.3 集成测试

**定义**: 测试多个组件协作的完整流程

**特点**:
- 真实环境模拟
- 端到端测试
- 验证用户场景

**示例目录结构**:
```
integration_test/
├── app_test.dart
├── connection_flow_test.dart
├── messaging_flow_test.dart
└── helpers/
    ├── pump_app.dart
    └── test_helpers.dart
```

**示例**:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:clawtalk/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('连接流程集成测试', () {
    testWidgets('用户可以添加连接并发送消息', (tester) async {
      // 启动应用
      app.main();
      await tester.pumpAndSettle();

      // 1. 导航到连接管理页面
      await tester.tap(find.text('连接'));
      await tester.pumpAndSettle();

      // 2. 添加新连接
      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();

      // 3. 填写连接信息
      await tester.enterText(
        find.byKey(Key('connection_name')),
        'Test Gateway',
      );
      await tester.enterText(
        find.byKey(Key('connection_host')),
        'gateway.example.com',
      );
      await tester.enterText(
        find.byKey(Key('connection_token')),
        'test-token',
      );

      // 4. 保存连接
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 5. 连接
      await tester.tap(find.text('Test Gateway'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 6. 验证连接成功
      expect(find.text('已认证'), findsOneWidget);
    });
  });
}
```

---

## 5. Mock 策略

### 5.1 Mock 工具

| 工具 | 用途 |
|------|------|
| `mocktail` | 创建 Mock 对象 |
| `fake` | 创建 Fake 实现 |
| `no methodology` | 简单对象直接实现 |

### 5.2 接口 Mock

```dart
// 使用 mocktail 创建 Mock
class MockConnectionManager extends Mock implements ConnectionManager {}
class MockMessageRepository extends Mock implements MessageRepository {}
class MockWebSocketChannel extends Mock implements WebSocketChannel {}

// 注册回退值
void setUpMocks() {
  registerFallbackValue(ConnectionConfig(
    id: 'fallback',
    name: 'fallback',
    host: 'fallback',
    createdAt: DateTime.now(),
  ));
  registerFallbackValue(const ConnectionStatus.disconnected());
}
```

### 5.3 平台插件 Mock

```dart
// SharedPreferences Mock
class FakeSharedPreferences extends Fake implements SharedPreferences {
  final Map<String, dynamic> _data = {};
  
  @override
  String? getString(String key) => _data[key] as String?;
  
  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }
  
  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }
}

// Secure Storage Mock
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};
  
  @override
  Future<String?> read({required String key}) async => _data[key];
  
  @override
  Future<void> write({required String key, required String value}) async {
    _data[key] = value;
  }
  
  @override
  Future<void> delete({required String key}) async {
    _data.remove(key);
  }
}
```

### 5.4 Platform Channel Mock

```dart
// MethodChannel Mock
void setupPlatformChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/camera'),
    (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initialize':
          return {'cameraId': 0};
        case 'takePicture':
          return '/tmp/test_image.jpg';
        default:
          return null;
      }
    },
  );
}
```

---

## 6. 覆盖率要求

### 6.1 分层覆盖率

| 层次 | 最低覆盖率 | 目标覆盖率 |
|------|------------|------------|
| Domain Layer | 90% | 95% |
| Data Layer | 80% | 90% |
| Presentation Layer | 70% | 80% |
| **总体** | **80%** | **85%** |

### 6.2 测量方法

```bash
# 运行测试并生成覆盖率报告
flutter test --coverage

# 生成 HTML 报告
genhtml coverage/lcov.info -o coverage/html

# 查看报告
open coverage/html/index.html
```

### 6.3 覆盖率检查脚本

```yaml
# .github/workflows/test.yml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: VeryGoodOpenSource/very_good_coverage@v2
        with:
          min_coverage: 80
```

### 6.4 排除配置

```yaml
# coverage_exclusions.yaml
exclusions:
  - "lib/main.dart"
  - "lib/**/generated/**"
  - "lib/**/*.g.dart"
  - "lib/**/*.freezed.dart"
  - "lib/l10n/**"
```

---

## 7. CICD 集成

### 7.1 测试流水线

```yaml
# .github/workflows/test.yml
name: Test Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze

  unit-test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  widget-test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test test/widget/

  integration-test:
    runs-on: macos-latest
    needs: [unit-test, widget-test]
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test integration_test/
```

### 7.2 Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# 运行分析
flutter analyze
if [ $? -ne 0 ]; then
  echo "静态分析失败"
  exit 1
fi

# 运行受影响的测试
flutter test
if [ $? -ne 0 ]; then
  echo "测试失败"
  exit 1
fi
```

### 7.3 PR 检查清单

```markdown
## PR Checklist

- [ ] 代码通过 `flutter analyze`
- [ ] 新代码有对应的测试
- [ ] 所有测试通过
- [ ] 覆盖率不低于 80%
- [ ] 更新了相关文档
```

---

## 8. 测试用例模板

### 8.1 单元测试模板

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock 定义
class MockDependency extends Mock implements Dependency {}

void main() {
  group('Subject', () {
    late Subject subject;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      subject = Subject(dependency: mockDependency);
      registerFallbackValue(FallbackValue());
    });
    
    tearDown(() {
      subject.dispose();
    });
    
    test('should [expected behavior] when [condition]', () {
      // arrange
      when(() => mockDependency.method())
          .thenReturn(expectedValue);
      
      // act
      final result = subject.methodUnderTest();
      
      // assert
      expect(result, equals(expectedValue));
      verify(() => mockDependency.method()).called(1);
    });
  });
}
```

### 8.2 Widget 测试模板

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('WidgetName', () {
    testWidgets('should display [content] when [condition]', (tester) async {
      // arrange
      const expectedText = 'Expected Content';
      
      // act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetUnderTest(),
        ),
      ));
      
      // assert
      expect(find.text(expectedText), findsOneWidget);
    });
    
    testWidgets('should call [callback] when [action]', (tester) async {
      // arrange
      var callbackCalled = false;
      
      // act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WidgetUnderTest(
            onPressed: () => callbackCalled = true,
          ),
        ),
      ));
      
      await tester.tap(find.byType(WidgetUnderTest));
      
      // assert
      expect(callbackCalled, isTrue);
    });
  });
}
```

### 8.3 Provider 测试模板

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('ProviderName', () {
    late ProviderContainer container;
    late MockDependency mockDependency;
    
    setUp(() {
      mockDependency = MockDependency();
      container = ProviderContainer(
        overrides: [
          dependencyProvider.overrideWithValue(mockDependency),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('should initialize with correct state', () {
      // act
      final state = container.read(providerProvider);
      
      // assert
      expect(state, equals(InitialState()));
    });
    
    test('should update state when action is called', () async {
      // arrange
      when(() => mockDependency.fetch())
          .thenAnswer((_) async => ExpectedData());
      
      // act
      container.read(providerProvider.notifier).performAction();
      await container.read(providerProvider.future);
      
      // assert
      final state = container.read(providerProvider);
      expect(state, isA<SuccessState>());
    });
  });
}
```

---

## 9. 附录

### 9.1 测试命令速查

| 命令 | 说明 |
|------|------|
| `flutter test` | 运行所有测试 |
| `flutter test test/unit/` | 运行指定目录测试 |
| `flutter test --coverage` | 生成覆盖率报告 |
| `flutter test --reporter expanded` | 详细输出 |
| `flutter test -r` | 失败时自动重试 |
| `flutter test integration_test/` | 运行集成测试 |

### 9.2 调试技巧

```dart
// 打印 Widget 树
debugPrint(find.byType(Container).evaluate().first.toStringDeep());

// 延迟等待异步操作
await tester.pumpAndSettle(const Duration(seconds: 2));

// 查找多个 Widget
final widgets = find.byType(CustomWidget);
for (var widget in widgets.evaluate()) {
  debugPrint(widget.toString());
}
```

### 9.3 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**