# ClawTalk 连接模块设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [API设计](./01-api-design.md)

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

本文档定义 ClawTalk 客户端的连接模块设计，包括：
- 多连接管理架构
- 连接状态机实现
- 认证流程设计
- 重连策略实现
- Repository 数据访问层

### 1.2 功能范围

| 功能 | 描述 |
|------|------|
| 多连接管理 | 支持同时配置多个 Gateway 连接 |
| 连接切换 | 在不同连接间切换 |
| 状态同步 | 实时同步连接状态到 UI |
| 自动重连 | 网络断开后自动重连 |
| 凭证管理 | 安全存储认证信息 |

### 1.3 模块结构

```
lib/
├── features/
│   └── connection/
│       ├── data/
│       │   ├── repositories/
│       │   │   └── connection_config_repository_impl.dart
│       │   └── datasources/
│       │       └── connection_local_datasource.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   └── connection_config.dart
│       │   ├── repositories/
│       │   │   └── connection_config_repository.dart
│       │   └── usecases/
│       │       ├── add_connection.dart
│       │       ├── remove_connection.dart
│       │       └── get_connections.dart
│       ├── presentation/
│       │   ├── providers/
│       │   │   ├── connection_list_provider.dart
│       │   │   ├── active_connection_provider.dart
│       │   │   └── connection_manager_provider.dart
│       │   ├── screens/
│       │   │   ├── connection_list_screen.dart
│       │   │   └── add_connection_screen.dart
│       │   └── widgets/
│       │       ├── connection_card.dart
│       │       └── connection_status_indicator.dart
│       └── connection_module.dart
```

---

## 2. 架构设计

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    连接模块分层架构                           │
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
│  │  │  (实体)     │  │  (用例)     │  │  (接口)     │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                            │                                │
│                            ▼                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Data Layer                         │   │
│  │  ┌─────────────┐  ┌─────────────────────────────┐   │   │
│  │  │Repository   │  │    Data Sources             │   │   │
│  │  │Impl         │  │  Local │ Secure Storage     │   │   │
│  │  └─────────────┘  └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 连接状态机

```
                     ┌──────────────────────────────────────┐
                     │                                      │
                     ▼                                      │
┌─────────────┐  connect()  ┌─────────────┐               │
│             │ ──────────► │             │               │
│ Disconnected│             │ Connecting  │               │
│             │ ◄────────── │             │               │
└──────┬──────┘  cancel()   └──────┬──────┘               │
       │                            │                       │
       │                     ┌──────┴──────┐                │
       │                     │             │                │
       │               success│           │error           │
       │                     ▼             ▼                │
       │              ┌─────────────┐ ┌─────────────┐       │
       │              │  Connected  │ │   Error     │       │
       │              └──────┬──────┘ └──────┬──────┘       │
       │                     │               │               │
       │              auth()          retry()│               │
       │                     │               └───────────────┤
       │                     ▼                               │
       │              ┌─────────────┐                        │
       │              │Authenticating│                       │
       │              └──────┬──────┘                        │
       │                     │                               │
       │              ┌──────┴──────┐                        │
       │         success│           │failed                  │
       │              ▼             ▼                        │
       │       ┌─────────────┐ ┌─────────────┐               │
       │       │Authenticated│ │   Error     │               │
       │       └──────┬──────┘ └──────────────┘               │
       │              │                                       │
       │       disconnect()                                   │
       │              │                                       │
       └──────────────┘                                       │
                                                               
状态转换规则:
- Disconnected → Connecting: 调用 connect()
- Connecting → Connected: WebSocket 连接成功
- Connecting → Error: 连接失败
- Connected → Authenticating: 开始认证
- Authenticating → Authenticated: 认证成功
- Authenticating → Error: 认证失败
- Authenticated → Disconnected: 断开连接
- Error → Connecting: 重试
```

### 2.3 认证流程

```
┌──────────┐                    ┌──────────────┐                    
│  Client  │                    │   Gateway    │                    
└────┬─────┘                    └──────┬───────┘                    
     │                                 │                            
     │  1. WebSocket 握手              │                            
     │ ────────────────────────────────►│                            
     │                                 │                            
     │  2. Connection Challenge        │                            
     │ ◄────────────────────────────────│                            
     │  { "type": "challenge" }         │                            
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
     │  5. Ready                       │                            
     │ ════════════════════════════════│                            
     │                                 │                            
```

### 2.4 重连策略

```dart
/// 重连配置
class ReconnectConfig {
  /// 初始延迟 (毫秒)
  static const int initialDelay = 1000;
  
  /// 最大延迟 (毫秒)
  static const int maxDelay = 30000;
  
  /// 最大重试次数 (0 = 无限)
  static const int maxRetries = 0;
  
  /// 抖动因子 (0.0 - 1.0)
  static const double jitterFactor = 0.3;
  
  /// 计算下次重连延迟 (指数退避 + 抖动)
  static int calculateDelay(int attempt) {
    final baseDelay = initialDelay * (1 << attempt);
    final cappedDelay = baseDelay.clamp(initialDelay, maxDelay);
    
    // 添加随机抖动
    final jitter = cappedDelay * jitterFactor * (Random().nextDouble() * 2 - 1);
    return (cappedDelay + jitter).toInt().clamp(initialDelay, maxDelay);
  }
}

/// 重连时序示例
///
/// 尝试次数 | 延迟 (约)
/// ---------|----------
///    1     |  1s ± 0.3s
///    2     |  2s ± 0.6s
///    3     |  4s ± 1.2s
///    4     |  8s ± 2.4s
///    5     | 16s ± 4.8s
///   6+     | 30s ± 9s (最大)
```

---

## 3. Provider 设计

### 3.1 ConnectionListProvider

```dart
// lib/features/connection/presentation/providers/connection_list_provider.dart

@riverpod
class ConnectionList extends _$ConnectionList {
  @override
  Future<List<ConnectionConfig>> build() async {
    final repo = ref.watch(connectionConfigRepositoryProvider);
    return repo.getAll();
  }
  
  /// 添加新连接
  Future<void> add(ConnectionConfig config) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    await repo.save(config);
    ref.invalidateSelf();
  }
  
  /// 更新连接
  Future<void> update(ConnectionConfig config) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    await repo.save(config);
    ref.invalidateSelf();
  }
  
  /// 删除连接
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
  
  /// 批量导入连接
  Future<int> importFromJson(String json) async {
    final repo = ref.read(connectionConfigRepositoryProvider);
    final List<dynamic> list = jsonDecode(json);
    int count = 0;
    
    for (final item in list) {
      try {
        final config = ConnectionConfig.fromJson(item);
        await repo.save(config);
        count++;
      } catch (_) {
        // 跳过无效配置
      }
    }
    
    ref.invalidateSelf();
    return count;
  }
  
  /// 导出连接配置
  Future<String> exportToJson() async {
    final configs = state.valueOrNull ?? [];
    return jsonEncode(configs.map((c) => c.toJson()).toList());
  }
}
```

### 3.2 ActiveConnectionProvider

```dart
// lib/features/connection/presentation/providers/active_connection_provider.dart

/// 当前活跃连接 ID
@riverpod
class ActiveConnectionId extends _$ActiveConnectionId {
  @override
  String? build() {
    // 从设置中恢复上次连接
    final settings = ref.watch(settingsProvider);
    return settings.lastConnectionId;
  }
  
  /// 设置活跃连接
  Future<void> set(String id) async {
    state = id;
    
    // 持久化到设置
    await ref.read(settingsProvider.notifier).setLastConnectionId(id);
  }
  
  /// 清除活跃连接
  Future<void> clear() async {
    state = null;
    await ref.read(settingsProvider.notifier).setLastConnectionId(null);
  }
}

/// 活跃连接配置
@riverpod
ConnectionConfig? activeConnectionConfig(ActiveConnectionConfigRef ref) {
  final activeId = ref.watch(activeConnectionIdProvider);
  if (activeId == null) return null;
  
  final configs = ref.watch(connectionListProvider).valueOrNull;
  if (configs == null) return null;
  
  return configs.firstWhereOrNull((c) => c.id == activeId);
}

### 3.4 ConnectionSorting - 连接排序 (PRD 5.1.1 P2)

#### 排序条件

| 排序字段 | 说明 | 默认方向 |
|----------|------|----------|
| `name` | 连接名称 | 升序 (A-Z) |
| `lastConnectedAt` | 最后连接时间 | 降序 (最近优先) |
| `createdAt` | 创建时间 | 降序 (最新优先) |

#### Provider 设计

```dart
/// 排序条件枚举
enum SortCriteria {
  name,
  lastConnectedAt,
  createdAt,
}

/// 排序方向
enum SortDirection {
  ascending,
  descending,
}

/// 排序状态
@riverpod
class ConnectionSort extends _$ConnectionSort {
  @override
  ConnectionSortState build() => ConnectionSortState.defaults();
  
  /// 设置排序条件
  void setCriteria(SortCriteria criteria) {
    state = state.copyWith(criteria: criteria);
    _applySort();
  }
  
  /// 切换排序方向
  void toggleDirection() {
    state = state.copyWith(
      direction: state.direction == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending,
    );
    _applySort();
  }
  
  void _applySort() {
    final list = ref.read(connectionListProvider).valueOrNull;
    if (list == null) return;
    
    final sorted = List<ConnectionConfig>.from(list)..sort((a, b) {
      final comparison = switch (state.criteria) {
        SortCriteria.name => a.name.compareTo(b.name),
        SortCriteria.lastConnectedAt => 
          (a.lastConnectedAt ?? DateTime(1970))
              .compareTo(b.lastConnectedAt ?? DateTime(1970)),
        SortCriteria.createdAt => a.createdAt.compareTo(b.createdAt),
      };
      return state.direction == SortDirection.ascending 
          ? comparison 
          : -comparison;
    });
    
    // 更新列表
    ref.read(connectionListProvider.notifier).state = AsyncData(sorted);
  }
}

class ConnectionSortState {
  final SortCriteria criteria;
  final SortDirection direction;
  
  const ConnectionSortState({
    required this.criteria,
    required this.direction,
  });
  
  static ConnectionSortState defaults() => const ConnectionSortState(
    criteria: SortCriteria.lastConnectedAt,
    direction: SortDirection.descending,
  );
  
  ConnectionSortState copyWith({
    SortCriteria? criteria,
    SortDirection? direction,
  }) => ConnectionSortState(
    criteria: criteria ?? this.criteria,
    direction: direction ?? this.direction,
  );
}
```

#### UI 交互

在连接列表页面提供排序选项：
- 排序按钮显示当前排序条件
- 点击切换排序条件
- 长按或右键切换排序方向

### 3.3 ConnectionManagerProvider

```dart
// lib/features/connection/presentation/providers/connection_manager_provider.dart

@riverpod
class ConnectionManagerNotifier extends _$ConnectionManagerNotifier {
  late ConnectionManager _manager;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  StreamSubscription<AcpMessage>? _messageSubscription;
  
  @override
  ConnectionState build() {
    _manager = ConnectionManager();
    
    // 监听状态变化
    _statusSubscription = _manager.statusStream.listen((status) {
      state = ConnectionState(
        status: status,
        connectionId: state.connectionId,
        error: null,
      );
    });
    
    ref.onDispose(() {
      _statusSubscription?.cancel();
      _messageSubscription?.cancel();
      _manager.dispose();
    });
    
    return ConnectionState.disconnected;
  }
  
  /// 连接到指定 Gateway
  Future<void> connect(String connectionId) async {
    final configs = await ref.read(connectionListProvider.future);
    final config = configs.firstWhere((c) => c.id == connectionId);
    
    state = ConnectionState.connecting(connectionId);
    
    try {
      await _manager.connect(config);
      state = ConnectionState.connected(connectionId);
      
      ref.read(activeConnectionIdProvider.notifier).set(connectionId);
      
      // 监听消息流
      _messageSubscription = _manager.messageStream.listen((message) {
        _handleMessage(message);
      });
    } catch (e) {
      state = ConnectionState.error(connectionId, e.toString());
      _scheduleReconnect(connectionId);
    }
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    await _manager.disconnect();
    state = ConnectionState.disconnected;
    ref.read(activeConnectionIdProvider.notifier).clear();
  }
  
  /// 重连
  Future<void> reconnect() async {
    final activeId = ref.read(activeConnectionIdProvider);
    if (activeId != null) {
      await connect(activeId);
    }
  }
  
  /// 发送消息
  Future<void> send(AcpMessage message) async {
    if (!state.isConnected) {
      throw ConnectionNotReadyException();
    }
    await _manager.send(message);
  }
  
  /// 处理收到的消息
  void _handleMessage(AcpMessage message) {
    if (message is AcpEvent) {
      ref.read(eventDispatcherProvider).dispatch(message);
    }
  }
  
  /// 调度重连
  void _scheduleReconnect(String connectionId) {
    int attempt = 0;
    
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (state.isConnected || state.status == ConnectionStatus.connecting) {
        timer.cancel();
        return;
      }
      
      final delay = ReconnectConfig.calculateDelay(attempt);
      await Future.delayed(Duration(milliseconds: delay));
      
      try {
        await connect(connectionId);
        timer.cancel();
      } catch (_) {
        attempt++;
      }
    });
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
  
  static ConnectionState get disconnected => const ConnectionState(
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

### 3.4 配置导入导出详细设计

#### 验证规则

| 验证项 | 规则 | 错误处理 |
|--------|------|----------|
| JSON 格式 | 必须是有效的 JSON 数组 | 跳过并记录日志 |
| 必填字段 | `id`, `name`, `host` 必须存在 | 跳过该配置 |
| 字段类型 | 字段类型必须正确 | 跳过该配置 |
| ID 唯一性 | 导入的 ID 不能与已有重复 | 自动生成新 ID |

#### 错误处理策略

```dart
/// 导入结果
class ImportResult {
  final int successCount;
  final int skippedCount;
  final List<String> errors;

  const ImportResult({
    required this.successCount,
    required this.skippedCount,
    this.errors = const [],
  });
}

Future<ImportResult> importFromJson(String json) async {
  final List<dynamic> list;
  try {
    list = jsonDecode(json);
  } catch (e) {
    return ImportResult(
      successCount: 0,
      skippedCount: 0,
      errors: ['JSON 格式无效: ${e.toString()}'],
    );
  }

  int success = 0;
  int skipped = 0;
  final errors = <String>[];

  for (int i = 0; i < list.length; i++) {
    try {
      final config = ConnectionConfig.fromJson(list[i]);

      // 检查 ID 重复
      if (_exists(config.id)) {
        final newId = _generateNewId();
        config = config.copyWith(id: newId);
      }

      await repo.save(config);
      success++;
    } catch (e) {
      skipped++;
      errors.add('配置 #$i 导入失败: ${e.toString()}');
    }
  }

  return ImportResult(
    successCount: success,
    skippedCount: skipped,
    errors: errors,
  );
}
```

#### 安全考虑

**导出时的敏感数据处理**:
- `token` 和 `password` 字段默认不导出
- 用户可选择是否包含凭证
- 导出文件添加警告提示

```dart
Future<String> exportToJson({bool includeCredentials = false}) async {
  final configs = state.valueOrNull ?? [];

  final exportList = configs.map((c) {
    if (!includeCredentials) {
      return c.copyWith(
        token: null,
        password: null,
      ).toJson();
    }
    return c.toJson();
  }).toList();

  return jsonEncode(exportList);
}
```

**导入时的安全检查**:
- 验证来源文件安全性
- 检测潜在的恶意配置
- 限制单次导入数量 (最多 20 个)

#### 格式版本兼容性

```dart
// 导出格式版本
const kExportFormatVersion = '1.0';

// 导出数据结构
class ExportData {
  final String version;
  final String exportedAt;
  final List<Map<String, dynamic>> connections;

  Map<String, dynamic> toJson() => {
    'version': version,
    'exportedAt': exportedAt,
    'connections': connections,
  };
}
```

---

## 4. Widget 设计

### 4.1 ConnectionCard

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  🟢  我的 Gateway                            [编辑] [删除]│
│      wss://gateway.local:18789                          │
│      已认证 · 最后连接: 2分钟前                          │
│                                                         │
└─────────────────────────────────────────────────────────┘

状态指示器颜色:
- 🟢 已认证: CupertinoColors.activeGreen
- 🔵 已连接: CupertinoColors.activeBlue  
- ⚪ 未连接: CupertinoColors.systemGrey
- 🔴 错误: CupertinoColors.systemRed
```

```dart
// lib/features/connection/presentation/widgets/connection_card.dart

class ConnectionCard extends StatelessWidget {
  final ConnectionConfig config;
  final ConnectionStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  
  const ConnectionCard({
    required this.config,
    this.status = ConnectionStatus.disconnected,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardPadding,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: AppBorderRadius.medium,
          border: Border.all(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusIndicator(status: status),
                AppSpacing.sm.horizontalSpace,
                Expanded(
                  child: Text(
                    config.name,
                    style: AppTextStyles.headline3,
                  ),
                ),
                _buildActions(),
              ],
            ),
            AppSpacing.sm.verticalSpace,
            Text(
              config.wsUrl,
              style: AppTextStyles.bodySecondary,
            ),
            AppSpacing.xs.verticalSpace,
            Text(
              _buildStatusText(),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onEdit,
            child: Icon(CupertinoIcons.pencil, size: 20),
          ),
        if (onDelete != null)
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onDelete,
            child: Icon(CupertinoIcons.trash, size: 20),
          ),
      ],
    );
  }
  
  String _buildStatusText() {
    final statusText = switch (status) {
      ConnectionStatus.authenticated => '已认证',
      ConnectionStatus.connected => '已连接',
      ConnectionStatus.connecting => '连接中...',
      ConnectionStatus.authenticating => '认证中...',
      ConnectionStatus.reconnecting => '重连中...',
      ConnectionStatus.error => '连接错误',
      ConnectionStatus.disconnected => '未连接',
    };
    
    if (config.lastConnectedAt != null) {
      final time = _formatTime(config.lastConnectedAt!);
      return '$statusText · 最后连接: $time';
    }
    
    return statusText;
  }
}
```

### 4.2 AddConnectionScreen

```
┌─────────────────────────────────────────────────────────┐
│ ◀  添加连接                                       [保存] │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  基本信息                                                │
│  ┌─────────────────────────────────────────────────────┐│
│  │ 连接名称                                             ││
│  │ ┌─────────────────────────────────────────────────┐ ││
│  │ │                                                 │ ││
│  │ └─────────────────────────────────────────────────┘ ││
│  │                                                     ││
│  │ 主机地址                                             ││
│  │ ┌─────────────────────────────────────────────────┐ ││
│  │ │                                                 │ ││
│  │ └─────────────────────────────────────────────────┘ ││
│  │                                                     ││
│  │ 端口                                    [18789]    ││
│  │ ┌─────────────────────────────────────┐            ││
│  │ │                                     │            ││
│  │ └─────────────────────────────────────┘            ││
│  │                                                     ││
│  │ 使用 TLS                                 [开关]    ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  认证方式                                                │
│  ┌─────────────────────────────────────────────────────┐│
│  │ ○ Token                                             ││
│  │ ○ 密码                                              ││
│  │                                                     ││
│  │ Token / 密码                                        ││
│  │ ┌─────────────────────────────────────────────────┐ ││
│  │ │ ••••••••••••                                     │ ││
│  │ └─────────────────────────────────────────────────┘ ││
│  └─────────────────────────────────────────────────────┘│
│                                                         │
│  高级选项                                       [展开]  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 4.3 ConnectionStatusIndicator

```dart
// lib/features/connection/presentation/widgets/connection_status_indicator.dart

class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final double size;
  
  const ConnectionStatusIndicator({
    required this.status,
    this.size = 10.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('status_indicator'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getColor(),
      ),
    );
  }
  
  Color _getColor() {
    return switch (status) {
      ConnectionStatus.authenticated => CupertinoColors.activeGreen,
      ConnectionStatus.connected => CupertinoColors.activeBlue,
      ConnectionStatus.connecting => CupertinoColors.activeOrange,
      ConnectionStatus.authenticating => CupertinoColors.activeOrange,
      ConnectionStatus.reconnecting => CupertinoColors.activeOrange,
      ConnectionStatus.error => CupertinoColors.systemRed,
      ConnectionStatus.disconnected => CupertinoColors.systemGrey,
    };
  }
}
```

---

## 5. 测试用例

### 5.1 Provider 测试

```dart
// test/features/connection/providers/connection_list_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockConnectionConfigRepository extends Mock 
    implements ConnectionConfigRepository {}

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
          token: 'token',
        ),
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('应成功加载连接列表', () async {
      // arrange
      final configs = [
        ConnectionConfig(
          id: '1', 
          name: 'Gateway 1', 
          host: 'gw1.example.com',
          createdAt: DateTime.now(),
          token: 'token1',
        ),
        ConnectionConfig(
          id: '2', 
          name: 'Gateway 2', 
          host: 'gw2.example.com',
          createdAt: DateTime.now(),
          token: 'token2',
        ),
      ];
      when(() => mockRepo.getAll()).thenAnswer((_) async => configs);
      
      // act
      final result = await container.read(connectionListProvider.future);
      
      // assert
      expect(result.length, equals(2));
      expect(result[0].name, equals('Gateway 1'));
      expect(result[1].name, equals('Gateway 2'));
    });
    
    test('add 应保存并刷新列表', () async {
      // arrange
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.save(any())).thenAnswer((_) async {});
      
      final newConfig = ConnectionConfig.create(
        name: 'New Gateway',
        host: 'new.example.com',
        token: 'new-token',
      );
      
      // 初始化
      await container.read(connectionListProvider.future);
      
      // act
      await container.read(connectionListProvider.notifier).add(newConfig);
      
      // assert
      verify(() => mockRepo.save(any())).called(1);
    });
    
    test('delete 应删除并刷新列表', () async {
      // arrange
      when(() => mockRepo.getAll()).thenAnswer((_) async => []);
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});
      
      // act
      await container.read(connectionListProvider.notifier).delete('test-id');
      
      // assert
      verify(() => mockRepo.delete('test-id')).called(1);
    });
  });
}
```

### 5.2 ConnectionManager 测试

```dart
// test/features/connection/providers/connection_manager_provider_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}
class MockConnectionConfigRepository extends Mock 
    implements ConnectionConfigRepository {}

void main() {
  group('ConnectionManagerNotifier', () {
    late ProviderContainer container;
    late MockWebSocketChannel mockChannel;
    late MockConnectionConfigRepository mockRepo;
    
    setUp(() {
      mockChannel = MockWebSocketChannel();
      mockRepo = MockConnectionConfigRepository();
      container = ProviderContainer(
        overrides: [
          connectionConfigRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为 disconnected', () {
      // act
      final state = container.read(connectionManagerNotifierProvider);
      
      // assert
      expect(state.status, equals(ConnectionStatus.disconnected));
    });
    
    test('connect 成功后状态应变为 connected', () async {
      // arrange
      final config = ConnectionConfig.create(
        name: 'Test',
        host: 'test.example.com',
        token: 'token',
      );
      
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => [config]);
      when(() => mockChannel.ready)
          .thenAnswer((_) => Future.value());
      when(() => mockChannel.stream)
          .thenAnswer((_) => Stream.value('{"type":"res","ok":true}'));
      
      // act
      await container.read(
        connectionManagerNotifierProvider.notifier
      ).connect(config.id);
      
      // assert
      final state = container.read(connectionManagerNotifierProvider);
      expect(state.isConnected, isTrue);
    });
    
    test('connect 失败后状态应为 error', () async {
      // arrange
      final config = ConnectionConfig.create(
        name: 'Test',
        host: 'test.example.com',
        token: 'token',
      );
      
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => [config]);
      when(() => mockChannel.ready)
          .thenThrow(WebSocketChannelException('Connection refused'));
      
      // act
      await container.read(
        connectionManagerNotifierProvider.notifier
      ).connect(config.id);
      
      // assert
      final state = container.read(connectionManagerNotifierProvider);
      expect(state.hasError, isTrue);
    });
    
    test('disconnect 后状态应为 disconnected', () async {
      // arrange
      final config = ConnectionConfig.create(
        name: 'Test',
        host: 'test.example.com',
        token: 'token',
      );
      
      when(() => mockRepo.getAll())
          .thenAnswer((_) async => [config]);
      when(() => mockChannel.ready)
          .thenAnswer((_) => Future.value());
      
      // 先连接
      await container.read(
        connectionManagerNotifierProvider.notifier
      ).connect(config.id);
      
      // act
      await container.read(
        connectionManagerNotifierProvider.notifier
      ).disconnect();
      
      // assert
      final state = container.read(connectionManagerNotifierProvider);
      expect(state.status, equals(ConnectionStatus.disconnected));
    });
  });
}
```

### 5.3 Widget 测试

```dart
// test/features/connection/widgets/connection_card_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  group('ConnectionCard', () {
    testWidgets('应显示连接名称和 URL', (tester) async {
      // arrange
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test Gateway',
        host: 'gateway.example.com',
        port: 18789,
        useTls: true,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: ConnectionCard(config: config),
        ),
      ));
      
      // assert
      expect(find.text('Test Gateway'), findsOneWidget);
      expect(find.text('wss://gateway.example.com:18789'), findsOneWidget);
    });
    
    testWidgets('已认证状态应显示绿色指示器', (tester) async {
      // arrange
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test',
        host: 'gateway.example.com',
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: ConnectionCard(
            config: config,
            status: ConnectionStatus.authenticated,
          ),
        ),
      ));
      
      // assert
      final indicator = tester.widget<Container>(
        find.byKey(const Key('status_indicator')),
      );
      final decoration = indicator.decoration as BoxDecoration;
      expect(decoration.color, equals(CupertinoColors.activeGreen));
    });
    
    testWidgets('点击应触发 onTap 回调', (tester) async {
      // arrange
      var tapped = false;
      final config = ConnectionConfig(
        id: 'test',
        name: 'Test',
        host: 'gateway.example.com',
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: ConnectionCard(
            config: config,
            onTap: () => tapped = true,
          ),
        ),
      ));
      
      await tester.tap(find.byType(ConnectionCard));
      
      // assert
      expect(tapped, isTrue);
    });
  });
}
```

### 5.4 Repository 测试

```dart
// test/features/connection/data/repositories/connection_config_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('ConnectionConfigRepositoryImpl', () {
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
    
    test('getAll 应返回所有连接配置', () async {
      // arrange
      final configs = [
        ConnectionConfig(
          id: '1',
          name: 'Gateway 1',
          host: 'gw1.example.com',
          createdAt: DateTime.now(),
        ).toJson(),
        ConnectionConfig(
          id: '2',
          name: 'Gateway 2',
          host: 'gw2.example.com',
          createdAt: DateTime.now(),
        ).toJson(),
      ];
      
      when(() => mockPrefs.getString(StorageKeys.connections))
          .thenReturn(jsonEncode(configs));
      
      // act
      final result = await repository.getAll();
      
      // assert
      expect(result.length, equals(2));
      expect(result[0].name, equals('Gateway 1'));
    });
    
    test('save 应保存配置和凭证', () async {
      // arrange
      final config = ConnectionConfig.create(
        name: 'Test',
        host: 'test.example.com',
        token: 'test-token',
      );
      
      when(() => mockPrefs.setString(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});
      when(() => mockPrefs.getString(any())).thenReturn(null);
      
      // act
      await repository.save(config);
      
      // assert
      verify(() => mockPrefs.setString(
        StorageKeys.connections,
        any(),
      )).called(1);
      verify(() => mockStorage.write(
        key: '${StorageKeys.tokenPrefix}${config.id}',
        value: 'test-token',
      )).called(1);
    });
    
    test('delete 应删除配置和凭证', () async {
      // arrange
      const configId = 'test-id';
      
      when(() => mockPrefs.remove(any()))
          .thenAnswer((_) async => true);
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      
      // act
      await repository.delete(configId);
      
      // assert
      verify(() => mockPrefs.remove(any())).called(1);
      verify(() => mockStorage.delete(
        key: '${StorageKeys.tokenPrefix}$configId',
      )).called(1);
    });
  });
}
```

---

## 6. 附录

### 6.1 Provider 速查表

| Provider | 类型 | 用途 |
|----------|------|------|
| `connectionListProvider` | AsyncNotifier | 连接配置列表 |
| `activeConnectionIdProvider` | StateNotifier | 当前活跃连接 ID |
| `activeConnectionConfigProvider` | Provider | 当前活跃连接配置 |
| `connectionManagerNotifierProvider` | StateNotifier | 连接状态管理 |

### 6.2 状态速查表

| 状态 | 值 | 说明 |
|------|------|------|
| `disconnected` | 0 | 已断开 |
| `connecting` | 1 | 连接中 |
| `connected` | 2 | 已连接 |
| `authenticating` | 3 | 认证中 |
| `authenticated` | 4 | 已认证 |
| `error` | 5 | 错误 |
| `reconnecting` | 6 | 重连中 |

### 6.3 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**