# ClawTalk Agent 模块设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [数据模型](./02-data-model.md)

---

## 目录

1. [概述](#1-概述)
2. [架构设计](#2-架构设计)
3. [数据模型](#3-数据模型)
4. [Provider 设计](#4-provider-设计)
5. [Widget 设计](#5-widget-设计)
6. [ACP 方法](#6-acp-方法)
7. [测试用例](#7-测试用例)
8. [附录](#8-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端 Agent 模块的详细设计，包括：
- Agent 发现与列表管理
- Agent 选择与状态管理
- 任务处理与进度跟踪
- 工具调用事件处理

### 1.2 功能范围

| 功能 | 描述 | 优先级 |
|------|------|--------|
| Agent 列表 | 显示可用 Agent 及其状态 | P0 |
| Agent 详情 | 显示 Agent 信息、能力描述 | P1 |
| Agent 搜索 | 搜索特定 Agent | P2 |
| Agent 选择 | 选择要交互的 Agent | P0 |
| 默认 Agent | 设置默认 Agent | P1 |
| 任务进度 | 显示长时任务进度 | P0 |
| 取消任务 | 取消正在执行的任务 | P0 |
| 任务结果 | 显示任务执行结果 | P0 |

### 1.3 模块结构

```
lib/features/agents/
├── data/
│   ├── repositories/
│   │   └── agent_repository_impl.dart
│   └── services/
│       └── agent_service.dart
├── domain/
│   ├── entities/
│   │   ├── agent.dart
│   │   ├── agent_status.dart
│   │   └── task.dart
│   ├── repositories/
│   │   └── agent_repository.dart
│   └── usecases/
│       ├── get_agents.dart
│       ├── select_agent.dart
│       └── cancel_task.dart
├── presentation/
│   ├── providers/
│   │   ├── agent_list_provider.dart
│   │   ├── selected_agent_provider.dart
│   │   └── task_progress_provider.dart
│   ├── screens/
│   │   └── agent_select_screen.dart
│   └── widgets/
│       ├── agent_card.dart
│       ├── agent_status_indicator.dart
│       ├── task_progress_bar.dart
│       └── tool_call_display.dart
└── agents_module.dart
```

---

## 2. 架构设计

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Agent 模块分层架构                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Presentation Layer                      │   │
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
│  │  │Repository   │  │    Services                 │   │   │
│  │  │Impl         │  │  AgentService │ ACP Client  │   │   │
│  │  └─────────────┘  └─────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Agent 发现流程

```
┌─────────────────────────────────────────────────────────────┐
│                    Agent 发现流程                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐                                        │
│  │  AgentListScreen│                                        │
│  │  (用户请求)      │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ refresh()                                       │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │AgentListProvider│                                        │
│  │  1. 更新状态为加载中                                      │
│  │  2. 调用 AgentService                                    │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ getAgents()                                     │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │  AgentService   │                                        │
│  │  发送 ACP 请求   │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ AcpRequest                                      │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ ConnectionManager│                                       │
│  │  (WebSocket)     │                                       │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ AcpEvent (agent_list)                           │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │AgentListProvider│                                        │
│  │  解析响应并更新状态                                       │
│  └─────────────────┘                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.3 任务处理流程

```
┌─────────────────────────────────────────────────────────────┐
│                    任务处理流程                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  用户发送消息                                                 │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ MessageListProvider                                       │
│  │  发送 prompt 请求                                         │
│  └────────┬────────┘                                        │
│           │                                                 │
│           │ AcpEvent 流                                     │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │TaskProgressProvider                                       │
│  │  监听 tool_call 事件                                      │
│  └────────┬────────┘                                        │
│           │                                                 │
│     ┌─────┴─────┬─────────┬─────────┐                       │
│     │           │         │         │                       │
│     ▼           ▼         ▼         ▼                       │
│  tool_call  tool_call  message   done                      │
│     │       _update                                │       │
│     ▼                                             ▼         │
│  ┌─────────┐                                 ┌─────────┐   │
│  │TaskBar  │                                 │Complete │   │
│  │ (进度)  │                                 │ (完成)  │   │
│  └─────────┘                                 └─────────┘   │
│                                                             │
│  工具调用状态:                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  pending → running → completed/failed               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 数据模型

### 3.1 Agent 实体

```dart
/// Agent 实体
class Agent extends Equatable {
  /// Agent ID
  final String id;
  
  /// Agent 名称
  final String name;
  
  /// Agent 描述
  final String? description;
  
  /// Agent 能力列表
  final List<String> capabilities;
  
  /// Agent 状态
  final AgentStatus status;
  
  /// Agent 图标 URL
  final String? iconUrl;
  
  /// Agent 版本
  final String? version;
  
  /// 是否为默认 Agent
  final bool isDefault;
  
  /// 创建时间
  final DateTime createdAt;

  const Agent({
    required this.id,
    required this.name,
    this.description,
    this.capabilities = const [],
    this.status = AgentStatus.offline,
    this.iconUrl,
    this.version,
    this.isDefault = false,
    required this.createdAt,
  });
  
  /// 是否在线
  bool get isOnline => status == AgentStatus.online;
  
  /// 是否忙碌
  bool get isBusy => status == AgentStatus.busy;

  @override
  List<Object?> get props => [
    id, name, description, capabilities, status,
    iconUrl, version, isDefault, createdAt,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'capabilities': capabilities,
    'status': status.name,
    'iconUrl': iconUrl,
    'version': version,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    capabilities: (json['capabilities'] as List<dynamic>?)?.cast<String>() ?? [],
    status: AgentStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => AgentStatus.offline,
    ),
    iconUrl: json['iconUrl'] as String?,
    version: json['version'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );
  
  Agent copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? capabilities,
    AgentStatus? status,
    String? iconUrl,
    String? version,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      capabilities: capabilities ?? this.capabilities,
      status: status ?? this.status,
      iconUrl: iconUrl ?? this.iconUrl,
      version: version ?? this.version,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

### 3.2 Agent 状态枚举

```dart
/// Agent 状态枚举
enum AgentStatus {
  /// 在线
  online,
  
  /// 离线
  offline,
  
  /// 忙碌
  busy,
  
  /// 错误
  error,
}
```

### 3.3 Task 实体

```dart
/// 任务实体
class Task extends Equatable {
  /// 任务 ID
  final String id;
  
  /// 会话 ID
  final String sessionId;
  
  /// Agent ID
  final String agentId;
  
  /// 任务名称
  final String name;
  
  /// 任务状态
  final TaskStatus status;
  
  /// 进度 (0.0 - 1.0)
  final double progress;
  
  /// 任务结果
  final Map<String, dynamic>? result;
  
  /// 错误信息
  final String? error;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 完成时间
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.sessionId,
    required this.agentId,
    required this.name,
    this.status = TaskStatus.pending,
    this.progress = 0.0,
    this.result,
    this.error,
    required this.createdAt,
    this.completedAt,
  });
  
  /// 是否完成
  bool get isCompleted => status == TaskStatus.completed;
  
  /// 是否失败
  bool get isFailed => status == TaskStatus.failed;
  
  /// 是否运行中
  bool get isRunning => status == TaskStatus.running;
  
  /// 是否可取消
  bool get canCancel => status == TaskStatus.pending || status == TaskStatus.running;

  @override
  List<Object?> get props => [
    id, sessionId, agentId, name, status, progress,
    result, error, createdAt, completedAt,
  ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'agentId': agentId,
    'name': name,
    'status': status.name,
    'progress': progress,
    'result': result,
    'error': error,
    'createdAt': createdAt.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    agentId: json['agentId'] as String,
    name: json['name'] as String,
    status: TaskStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => TaskStatus.pending,
    ),
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    result: json['result'] as Map<String, dynamic>?,
    error: json['error'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
    completedAt: json['completedAt'] != null
        ? DateTime.parse(json['completedAt'])
        : null,
  );
  
  Task copyWith({
    String? id,
    String? sessionId,
    String? agentId,
    String? name,
    TaskStatus? status,
    double? progress,
    Map<String, dynamic>? result,
    String? error,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      agentId: agentId ?? this.agentId,
      name: name ?? this.name,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// 任务状态枚举
enum TaskStatus {
  /// 待执行
  pending,
  
  /// 执行中
  running,
  
  /// 已完成
  completed,
  
  /// 已失败
  failed,
  
  /// 已取消
  cancelled,
}
```

### 3.4 ToolCall 事件

```dart
/// 工具调用事件
class ToolCallEvent extends Equatable {
  /// 调用 ID
  final String id;
  
  /// 工具名称
  final String name;
  
  /// 调用状态
  final ToolCallStatus status;
  
  /// 输入参数
  final Map<String, dynamic>? input;
  
  /// 输出结果
  final Map<String, dynamic>? output;
  
  /// 错误信息
  final String? error;
  
  /// 时间戳
  final DateTime timestamp;

  const ToolCallEvent({
    required this.id,
    required this.name,
    required this.status,
    this.input,
    this.output,
    this.error,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, name, status, input, output, error, timestamp];

  factory ToolCallEvent.fromJson(Map<String, dynamic> json) => ToolCallEvent(
    id: json['id'] as String,
    name: json['name'] as String,
    status: ToolCallStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => ToolCallStatus.pending,
    ),
    input: json['input'] as Map<String, dynamic>?,
    output: json['output'] as Map<String, dynamic>?,
    error: json['error'] as String?,
    timestamp: DateTime.now(),
  );
}

/// 工具调用状态
enum ToolCallStatus {
  pending,
  running,
  completed,
  failed,
}
```

---

## 4. Provider 设计

### 4.1 AgentListProvider

```dart
// lib/features/agents/presentation/providers/agent_list_provider.dart

@riverpod
class AgentList extends _$AgentList {
  @override
  Future<List<Agent>> build() async {
    // 加载本地缓存的 Agent 列表
    final repo = ref.watch(agentRepositoryProvider);
    return repo.getCachedAgents();
  }
  
  /// 刷新 Agent 列表
  Future<void> refresh() async {
    state = const AsyncLoading();
    
    try {
      final connectionId = ref.read(activeConnectionIdProvider);
      if (connectionId == null) {
        throw NoActiveConnectionException();
      }
      
      // 发送 ACP 请求获取 Agent 列表
      final service = ref.read(agentServiceProvider);
      final agents = await service.getAgents(connectionId);
      
      // 缓存到本地
      final repo = ref.read(agentRepositoryProvider);
      await repo.cacheAgents(agents);
      
      state = AsyncData(agents);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
  
  /// 搜索 Agent
  List<Agent> search(String query) {
    final agents = state.valueOrNull ?? [];
    if (query.isEmpty) return agents;
    
    final lowerQuery = query.toLowerCase();
    return agents.where((agent) {
      return agent.name.toLowerCase().contains(lowerQuery) ||
          agent.description?.toLowerCase().contains(lowerQuery) == true ||
          agent.capabilities.any((c) => c.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  /// 按状态过滤
  List<Agent> filterByStatus(AgentStatus? status) {
    final agents = state.valueOrNull ?? [];
    if (status == null) return agents;
    return agents.where((a) => a.status == status).toList();
  }
}
```

### 4.2 SelectedAgentProvider

```dart
// lib/features/agents/presentation/providers/selected_agent_provider.dart

/// 当前选中的 Agent ID
@riverpod
class SelectedAgentId extends _$SelectedAgentId {
  @override
  String? build() {
    // 从设置中恢复默认 Agent
    final settings = ref.watch(settingsProvider);
    return settings.defaultAgentId;
  }
  
  /// 选择 Agent
  Future<void> select(String agentId) async {
    state = agentId;
    
    // 更新设置
    await ref.read(settingsProvider.notifier).setDefaultAgentId(agentId);
  }
  
  /// 清除选择
  void clear() {
    state = null;
  }
}

/// 当前选中的 Agent 配置
@riverpod
Agent? selectedAgent(SelectedAgentRef ref) {
  final selectedId = ref.watch(selectedAgentIdProvider);
  if (selectedId == null) return null;
  
  final agents = ref.watch(agentListProvider).valueOrNull;
  if (agents == null) return null;
  
  return agents.firstWhereOrNull((a) => a.id == selectedId);
}
```

### 4.3 TaskProgressProvider

```dart
// lib/features/agents/presentation/providers/task_progress_provider.dart

@riverpod
class TaskProgress extends _$TaskProgress {
  StreamSubscription<AcpEvent>? _eventSubscription;
  
  @override
  Map<String, Task> build() {
    // 订阅工具调用事件
    _subscribeToEvents();
    
    ref.onDispose(() {
      _eventSubscription?.cancel();
    });
    
    return {};
  }
  
  /// 订阅事件
  void _subscribeToEvents() {
    final connectionId = ref.read(activeConnectionIdProvider);
    if (connectionId == null) return;
    
    _eventSubscription = ref.read(
      messageStreamProvider(connectionId)
    ).listen((event) {
      if (event.event == 'tool_call') {
        _handleToolCall(event);
      } else if (event.event == 'tool_call_update') {
        _handleToolCallUpdate(event);
      }
    });
  }
  
  /// 处理工具调用
  void _handleToolCall(AcpEvent event) {
    final payload = event.payload;
    final toolCall = payload['tool_call'] as Map<String, dynamic>?;
    
    if (toolCall == null) return;
    
    final taskId = toolCall['id'] as String;
    final task = Task(
      id: taskId,
      sessionId: ref.read(activeSessionIdProvider) ?? '',
      agentId: ref.read(selectedAgentIdProvider) ?? '',
      name: toolCall['name'] as String,
      status: TaskStatus.running,
      createdAt: DateTime.now(),
    );
    
    state = {...state, taskId: task};
  }
  
  /// 处理工具调用更新
  void _handleToolCallUpdate(AcpEvent event) {
    final payload = event.payload;
    final toolCall = payload['tool_call'] as Map<String, dynamic>?;
    
    if (toolCall == null) return;
    
    final taskId = toolCall['id'] as String;
    final existingTask = state[taskId];
    
    if (existingTask == null) return;
    
    final status = _parseStatus(toolCall['status'] as String?);
    final output = toolCall['output'] as Map<String, dynamic>?;
    final error = toolCall['error'] as String?;
    
    final updatedTask = existingTask.copyWith(
      status: status,
      output: output,
      error: error,
      completedAt: status == TaskStatus.completed || status == TaskStatus.failed
          ? DateTime.now()
          : null,
    );
    
    state = {...state, taskId: updatedTask};
  }
  
  /// 取消任务
  Future<void> cancelTask(String taskId) async {
    final task = state[taskId];
    if (task == null || !task.canCancel) return;
    
    // 更新状态为取消中
    state = {
      ...state,
      taskId: task.copyWith(status: TaskStatus.cancelled),
    };
    
    try {
      // 发送取消请求
      final connectionId = ref.read(activeConnectionIdProvider);
      if (connectionId == null) return;
      
      final request = AcpRequest(
        id: const Uuid().v4(),
        method: 'cancel',
        params: {
          'session_id': task.sessionId,
        },
      );
      
      await ref.read(connectionManagerNotifierProvider.notifier).send(request);
    } catch (e) {
      // 恢复原状态
      state = {...state, taskId: task};
      rethrow;
    }
  }
  
  /// 清除已完成/失败的任务
  void clearCompleted() {
    state = Map.fromEntries(
      state.entries.where((e) => e.value.isRunning || e.value.status == TaskStatus.pending),
    );
  }
  
  TaskStatus _parseStatus(String? status) {
    return switch (status) {
      'completed' => TaskStatus.completed,
      'failed' => TaskStatus.failed,
      'cancelled' => TaskStatus.cancelled,
      'running' => TaskStatus.running,
      _ => TaskStatus.pending,
    };
  }
}

/// 当前活跃任务
@riverpod
List<Task> activeTasks(ActiveTasksRef ref) {
  final tasks = ref.watch(taskProgressProvider);
  return tasks.values
      .where((t) => t.status == TaskStatus.running || t.status == TaskStatus.pending)
      .toList();
}
```

---

## 5. Widget 设计

### 5.1 AgentCard

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  🤖  Main Agent                              [默认]     │
│      代码助手 · 文件操作 · 终端                         │
│      🟢 在线                                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

```dart
// lib/features/agents/presentation/widgets/agent_card.dart

class AgentCard extends StatelessWidget {
  final Agent agent;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onSetDefault;
  
  const AgentCard({
    required this.agent,
    this.isSelected = false,
    this.onTap,
    this.onSetDefault,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.activeBlue.withOpacity(0.1)
              : CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CupertinoColors.activeBlue
                : CupertinoColors.separator,
            width: isSelected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // 图标
            _buildIcon(context),
            const SizedBox(width: 12),
            
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        agent.name,
                        style: AppTextStyles.headline3,
                      ),
                      if (agent.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '默认',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agent.capabilities.take(3).join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildStatusRow(context),
                ],
              ),
            ),
            
            // 状态指示器
            AgentStatusIndicator(status: agent.status),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(12),
      ),
      child: agent.iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(agent.iconUrl!),
            )
          : const Icon(
              CupertinoIcons.robot,
              size: 24,
              color: CupertinoColors.systemGrey,
            ),
    );
  }
  
  Widget _buildStatusRow(BuildContext context) {
    return Row(
      children: [
        _StatusDot(status: agent.status),
        const SizedBox(width: 4),
        Text(
          _getStatusText(),
          style: TextStyle(
            fontSize: 12,
            color: _getStatusColor(),
          ),
        ),
      ],
    );
  }
  
  String _getStatusText() {
    return switch (agent.status) {
      AgentStatus.online => '在线',
      AgentStatus.offline => '离线',
      AgentStatus.busy => '忙碌',
      AgentStatus.error => '错误',
    };
  }
  
  Color _getStatusColor() {
    return switch (agent.status) {
      AgentStatus.online => CupertinoColors.activeGreen,
      AgentStatus.offline => CupertinoColors.systemGrey,
      AgentStatus.busy => CupertinoColors.systemOrange,
      AgentStatus.error => CupertinoColors.systemRed,
    };
  }
}
```

### 5.2 AgentStatusIndicator

```dart
// lib/features/agents/presentation/widgets/agent_status_indicator.dart

class AgentStatusIndicator extends StatelessWidget {
  final AgentStatus status;
  final double size;
  
  const AgentStatusIndicator({
    required this.status,
    this.size = 10,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
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
      AgentStatus.online => CupertinoColors.activeGreen,
      AgentStatus.offline => CupertinoColors.systemGrey,
      AgentStatus.busy => CupertinoColors.systemOrange,
      AgentStatus.error => CupertinoColors.systemRed,
    };
  }
}
```

### 5.3 TaskProgressBar

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  📋 执行任务中...                                       │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │   │
│  └─────────────────────────────────────────────────┘   │
│  正在: 搜索文件...                          [取消]      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

```dart
// lib/features/agents/presentation/widgets/task_progress_bar.dart

class TaskProgressBar extends ConsumerWidget {
  final Task task;
  
  const TaskProgressBar({required this.task});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.clock,
                size: 14,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 6),
              Text(
                _getTitleText(),
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.progress,
              backgroundColor: CupertinoColors.systemGrey4,
              valueColor: AlwaysStoppedAnimation(_getProgressColor()),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Text(
                task.name,
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              if (task.canCancel)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _cancelTask(ref),
                  child: Text(
                    '取消',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _getTitleText() {
    return switch (task.status) {
      TaskStatus.pending => '等待执行...',
      TaskStatus.running => '执行中...',
      TaskStatus.completed => '已完成',
      TaskStatus.failed => '执行失败',
      TaskStatus.cancelled => '已取消',
    };
  }
  
  Color _getProgressColor() {
    return switch (task.status) {
      TaskStatus.pending => CupertinoColors.systemGrey,
      TaskStatus.running => CupertinoColors.activeBlue,
      TaskStatus.completed => CupertinoColors.activeGreen,
      TaskStatus.failed => CupertinoColors.systemRed,
      TaskStatus.cancelled => CupertinoColors.systemOrange,
    };
  }
  
  void _cancelTask(WidgetRef ref) {
    ref.read(taskProgressProvider.notifier).cancelTask(task.id);
  }
}
```

### 5.4 AgentSelectScreen

```
┌─────────────────────────────────────────────────────────┐
│ ◀  选择 Agent                                  [刷新]   │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🔍 搜索 Agent...                                │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  可用 Agent                                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🤖 Main Agent                      🟢  [默认]  │   │
│  │    代码助手 · 文件操作                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🤖 Research Agent                  🟡          │   │
│  │    网络搜索 · 文档分析                          │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │ 🤖 DevOps Agent                    ⚪          │   │
│  │    部署 · 监控 · CI/CD                         │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 6. ACP 方法

### 6.1 Agent 相关方法

| 方法 | 说明 | 参数 |
|------|------|------|
| `listAgents` | 获取 Agent 列表 | 无 |
| `getAgent` | 获取 Agent 详情 | `agent_id` |
| `cancel` | 取消当前任务 | `session_id` |

### 6.2 Agent 列表请求

```dart
/// 创建获取 Agent 列表请求
AcpRequest createListAgentsRequest() {
  return AcpRequest(
    id: const Uuid().v4(),
    method: 'listAgents',
    params: {},
  );
}
```

### 6.3 取消任务请求

```dart
/// 创建取消任务请求
AcpRequest createCancelRequest(String sessionId) {
  return AcpRequest(
    id: const Uuid().v4(),
    method: 'cancel',
    params: {
      'session_id': sessionId,
    },
  );
}
```

---

## 7. 测试用例

### 7.1 Provider 测试

```dart
void main() {
  group('AgentListProvider', () {
    late ProviderContainer container;
    late MockAgentRepository mockRepo;
    late MockAgentService mockService;
    
    setUp(() {
      mockRepo = MockAgentRepository();
      mockService = MockAgentService();
      container = ProviderContainer(
        overrides: [
          agentRepositoryProvider.overrideWithValue(mockRepo),
          agentServiceProvider.overrideWithValue(mockService),
        ],
      );
      registerFallbackValue(
        Agent(id: 'fallback', name: 'fallback', createdAt: DateTime.now()),
      );
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('应加载缓存的 Agent 列表', () async {
      // arrange
      final agents = [
        Agent(id: '1', name: 'Agent 1', createdAt: DateTime.now()),
        Agent(id: '2', name: 'Agent 2', createdAt: DateTime.now()),
      ];
      when(() => mockRepo.getCachedAgents())
          .thenAnswer((_) async => agents);
      
      // act
      final result = await container.read(agentListProvider.future);
      
      // assert
      expect(result.length, equals(2));
      expect(result[0].name, equals('Agent 1'));
    });
    
    test('refresh 应更新 Agent 列表', () async {
      // arrange
      final agents = [
        Agent(id: '1', name: 'Agent 1', createdAt: DateTime.now()),
      ];
      when(() => mockRepo.getCachedAgents())
          .thenAnswer((_) async => []);
      when(() => mockRepo.cacheAgents(any()))
          .thenAnswer((_) async {});
      when(() => mockService.getAgents(any()))
          .thenAnswer((_) async => agents);
      
      // 初始化
      await container.read(agentListProvider.future);
      
      // act
      await container.read(agentListProvider.notifier).refresh();
      
      // assert
      final result = container.read(agentListProvider).valueOrNull;
      expect(result?.length, equals(1));
    });
    
    test('search 应过滤 Agent 列表', () async {
      // arrange
      final agents = [
        Agent(id: '1', name: 'Code Agent', createdAt: DateTime.now()),
        Agent(id: '2', name: 'Research Agent', createdAt: DateTime.now()),
      ];
      when(() => mockRepo.getCachedAgents())
          .thenAnswer((_) async => agents);
      
      // act
      await container.read(agentListProvider.future);
      final result = container.read(agentListProvider.notifier).search('code');
      
      // assert
      expect(result.length, equals(1));
      expect(result[0].name, equals('Code Agent'));
    });
  });
  
  group('SelectedAgentProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('select 应更新选中的 Agent', () async {
      // act
      container.read(selectedAgentIdProvider.notifier).select('agent-1');
      
      // assert
      expect(container.read(selectedAgentIdProvider), equals('agent-1'));
    });
    
    test('clear 应清除选中的 Agent', () async {
      // arrange
      container.read(selectedAgentIdProvider.notifier).select('agent-1');
      
      // act
      container.read(selectedAgentIdProvider.notifier).clear();
      
      // assert
      expect(container.read(selectedAgentIdProvider), isNull);
    });
  });
  
  group('TaskProgressProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为空 Map', () {
      // act
      final state = container.read(taskProgressProvider);
      
      // assert
      expect(state, isEmpty);
    });
    
    test('clearCompleted 应清除已完成任务', () {
      // arrange
      container.read(taskProgressProvider.notifier).state = {
        'task-1': Task(
          id: 'task-1',
          sessionId: 's1',
          agentId: 'a1',
          name: 'Task 1',
          status: TaskStatus.completed,
          createdAt: DateTime.now(),
        ),
        'task-2': Task(
          id: 'task-2',
          sessionId: 's1',
          agentId: 'a1',
          name: 'Task 2',
          status: TaskStatus.running,
          createdAt: DateTime.now(),
        ),
      };
      
      // act
      container.read(taskProgressProvider.notifier).clearCompleted();
      
      // assert
      final state = container.read(taskProgressProvider);
      expect(state.length, equals(1));
      expect(state.containsKey('task-2'), isTrue);
    });
  });
}
```

### 7.2 Widget 测试

```dart
void main() {
  group('AgentCard', () {
    testWidgets('应显示 Agent 名称和状态', (tester) async {
      // arrange
      final agent = Agent(
        id: 'test',
        name: 'Test Agent',
        status: AgentStatus.online,
        capabilities: ['Code', 'Deploy'],
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: AgentCard(agent: agent),
        ),
      ));
      
      // assert
      expect(find.text('Test Agent'), findsOneWidget);
      expect(find.text('在线'), findsOneWidget);
    });
    
    testWidgets('点击应触发 onTap 回调', (tester) async {
      // arrange
      var tapped = false;
      final agent = Agent(
        id: 'test',
        name: 'Test',
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: AgentCard(
            agent: agent,
            onTap: () => tapped = true,
          ),
        ),
      ));
      
      await tester.tap(find.byType(AgentCard));
      
      // assert
      expect(tapped, isTrue);
    });
    
    testWidgets('默认 Agent 应显示默认标签', (tester) async {
      // arrange
      final agent = Agent(
        id: 'test',
        name: 'Test',
        isDefault: true,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: AgentCard(agent: agent),
        ),
      ));
      
      // assert
      expect(find.text('默认'), findsOneWidget);
    });
  });
  
  group('TaskProgressBar', () {
    testWidgets('应显示任务进度', (tester) async {
      // arrange
      final task = Task(
        id: 'task-1',
        sessionId: 's1',
        agentId: 'a1',
        name: 'Test Task',
        status: TaskStatus.running,
        progress: 0.5,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(CupertinoApp(
        home: CupertinoPageScaffold(
          child: TaskProgressBar(task: task),
        ),
      ));
      
      // assert
      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('执行中...'), findsOneWidget);
    });
    
    testWidgets('运行中任务应显示取消按钮', (tester) async {
      // arrange
      final task = Task(
        id: 'task-1',
        sessionId: 's1',
        agentId: 'a1',
        name: 'Test Task',
        status: TaskStatus.running,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(ProviderScope(
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: TaskProgressBar(task: task),
          ),
        ),
      ));
      
      // assert
      expect(find.text('取消'), findsOneWidget);
    });
    
    testWidgets('已完成任务不应显示取消按钮', (tester) async {
      // arrange
      final task = Task(
        id: 'task-1',
        sessionId: 's1',
        agentId: 'a1',
        name: 'Test Task',
        status: TaskStatus.completed,
        createdAt: DateTime.now(),
      );
      
      // act
      await tester.pumpWidget(ProviderScope(
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: TaskProgressBar(task: task),
          ),
        ),
      ));
      
      // assert
      expect(find.text('取消'), findsNothing);
    });
  });
}
```

---

## 8. 附录

### 8.1 Provider 速查表

| Provider | 类型 | 用途 |
|----------|------|------|
| `agentListProvider` | AsyncNotifier | Agent 列表 |
| `selectedAgentIdProvider` | StateNotifier | 选中的 Agent ID |
| `selectedAgentProvider` | Provider | 选中的 Agent 配置 |
| `taskProgressProvider` | StateNotifier | 任务进度映射 |
| `activeTasksProvider` | Provider | 当前活跃任务列表 |

### 8.2 Agent 状态说明

| 状态 | 颜色 | 说明 |
|------|------|------|
| online | 🟢 绿色 | Agent 在线可用 |
| offline | ⚪ 灰色 | Agent 离线 |
| busy | 🟡 橙色 | Agent 忙碌 |
| error | 🔴 红色 | Agent 出错 |

### 8.3 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**