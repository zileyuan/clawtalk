# ClawTalk 输入模块设计

**版本**: 1.0.0  
**创建日期**: 2026-03-16  
**作者**: 架构师  
**关联文档**: [PRD](../product-requirements.md), [TAD](../technical-architecture.md), [状态管理](./03-state-management.md)

---

## 目录

1. [概述](#1-概述)
2. [架构设计](#2-架构设计)
3. [文字输入设计](#3-文字输入设计)
4. [图片输入设计](#4-图片输入设计)
5. [语音输入设计](#5-语音输入设计)
6. [连接复制功能](#6-连接复制功能)
7. [平台适配](#7-平台适配)
8. [测试用例](#8-测试用例)
9. [附录](#9-附录)

---

## 1. 概述

### 1.1 目的

本文档定义 ClawTalk 客户端输入模块的详细设计，包括：
- 文字输入组件设计
- 图片输入流程设计
- 语音输入流程设计
- 多平台权限处理
- 输入验证与限制

### 1.2 模块职责

| 职责 | 说明 |
|------|------|
| 文字输入 | 文本编辑、验证、长度限制 |
| 图片输入 | 相机拍摄、相册选择、拖放上传、压缩处理 |
| 语音输入 | 录音、预览、播放、波形显示 |
| 输入组合 | 支持文字+图片+语音组合发送 |
| 平台适配 | 处理各平台权限和特性差异 |

### 1.3 输入限制

| 输入类型 | 限制 |
|----------|------|
| 文字 | 最大 10000 字符 |
| 图片 | 最大 10MB/张，最多 5 张 |
| 语音 | 最大 60 秒，最大 10MB |
| 文件 | 最大 10MB |

### 1.4 模块结构

```
lib/features/input/
├── data/
│   └── services/
│       ├── image_processing_service.dart
│       └── audio_recording_service.dart
├── domain/
│   ├── entities/
│   │   └── input_content.dart
│   └── validators/
│       ├── text_validator.dart
│       ├── image_validator.dart
│       └── audio_validator.dart
├── providers/
│   ├── text_input_provider.dart
│   ├── image_input_provider.dart
│   ├── voice_input_provider.dart
│   └── combined_input_provider.dart
└── presentation/
    ├── widgets/
    │   ├── text_input_field.dart
    │   ├── image_picker_button.dart
    │   ├── image_preview_grid.dart
    │   ├── voice_record_button.dart
    │   ├── voice_waveform.dart
    │   └── input_toolbar.dart
    └── pages/
        └── image_crop_page.dart
```

---

## 2. 架构设计

### 2.1 层次架构

```
┌─────────────────────────────────────────────────────────────┐
│                   输入模块架构                                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Presentation Layer                      │   │
│  │  TextInputField, ImagePickerButton, VoiceRecordBtn  │   │
│  │  ImagePreviewGrid, VoiceWaveform, InputToolbar      │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ ref.read/watch              │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Provider Layer                          │   │
│  │  TextInputProvider, ImageInputProvider              │   │
│  │  VoiceInputProvider, CombinedInputProvider          │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ 调用                        │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Domain Layer                            │   │
│  │  Validators: TextValidator, ImageValidator, etc.    │   │
│  │  Services: ImageProcessing, AudioRecording          │   │
│  └───────────────────────────┬─────────────────────────┘   │
│                              │ 实现                        │
│                              ▼                              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Platform Layer                          │   │
│  │  image_picker, camera, record, audioplayers         │   │
│  │  desktop_drop, pasteboard (桌面端)                   │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 输入状态组合

```
┌─────────────────────────────────────────────────────────────┐
│                   输入状态组合                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  CombinedInputState                                         │
│  ├── text: String                                           │
│  ├── images: List<ImageContent>                             │
│  ├── audio: AudioContent?                                   │
│  └── validation: InputValidation                            │
│                                                             │
│  发送条件:                                                   │
│  - text.isNotEmpty || images.isNotEmpty || audio != null   │
│  - 所有验证通过                                              │
│                                                             │
│  验证规则:                                                   │
│  ├── text.length <= 10000                                   │
│  ├── images.length <= 5                                     │
│  ├── images.every((i) => i.size <= 10MB)                   │
│  └── audio.duration <= 60s && audio.size <= 10MB           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 文字输入设计

### 3.1 Provider 设计

```dart
// lib/features/input/providers/text_input_provider.dart

@riverpod
class TextInput extends _$TextInput {
  @override
  TextInputState build() => TextInputState.empty();
  
  /// 更新文本
  void updateText(String text) {
    state = state.copyWith(text: text);
    _validate();
  }
  
  /// 更新选择区域
  void updateSelection(TextSelection selection) {
    state = state.copyWith(selection: selection);
  }
  
  /// 在光标处插入文本
  void insertAtCursor(String insert) {
    final current = state.text;
    final selection = state.selection;
    
    if (selection != null && selection.start >= 0) {
      final newText = current.replaceRange(
        selection.start,
        selection.end,
        insert,
      );
      state = state.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + insert.length,
        ),
      );
    } else {
      state = state.copyWith(text: current + insert);
    }
    
    _validate();
  }
  
  /// 清除文本
  void clear() {
    state = TextInputState.empty();
  }
  
  /// 从剪贴板粘贴
  Future<void> pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      insertAtCursor(data!.text!);
    }
  }
  
  /// 撤销
  void undo() {
    if (state.canUndo) {
      state = state.history.previous;
    }
  }
  
  /// 重做
  void redo() {
    if (state.canRedo) {
      state = state.history.next;
    }
  }
  
  /// 验证
  void _validate() {
    final errors = <InputValidationError>[];
    
    if (state.text.length > state.maxLength) {
      errors.add(InputValidationError.textTooLong(
        actual: state.text.length,
        max: state.maxLength,
      ));
    }
    
    state = state.copyWith(validationErrors: errors);
  }
}

/// 文字输入状态
class TextInputState {
  final String text;
  final TextSelection? selection;
  final int maxLength;
  final List<InputValidationError> validationErrors;
  final InputHistory history;
  
  const TextInputState({
    required this.text,
    this.selection,
    this.maxLength = 10000,
    this.validationErrors = const [],
    required this.history,
  });
  
  static TextInputState empty() => TextInputState(
    text: '',
    maxLength: 10000,
    history: InputHistory.empty(),
  );
  
  int get length => text.length;
  int get remaining => maxLength - length;
  bool get isOverLimit => length > maxLength;
  bool get isEmpty => text.isEmpty;
  bool get isNotEmpty => text.isNotEmpty;
  bool get isValid => validationErrors.isEmpty;
  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;
  
  TextInputState copyWith({
    String? text,
    TextSelection? selection,
    int? maxLength,
    List<InputValidationError>? validationErrors,
    InputHistory? history,
  }) {
    final newText = text ?? this.text;
    final newHistory = history ?? this.history.push(newText);
    
    return TextInputState(
      text: newText,
      selection: selection ?? this.selection,
      maxLength: maxLength ?? this.maxLength,
      validationErrors: validationErrors ?? this.validationErrors,
      history: newHistory,
    );
  }
}

/// 输入历史 (用于撤销/重做)
class InputHistory {
  final List<String> _undoStack;
  final List<String> _redoStack;
  final int maxSize;
  
  const InputHistory({
    required List<String> undoStack,
    required List<String> redoStack,
    this.maxSize = 50,
  }) : _undoStack = undoStack, _redoStack = redoStack;
  
  static InputHistory empty() => InputHistory(
    undoStack: [''],
    redoStack: [],
  );
  
  bool get canUndo => _undoStack.length > 1;
  bool get canRedo => _redoStack.isNotEmpty;
  
  InputHistory push(String text) {
    final newUndoStack = [..._undoStack, text];
    if (newUndoStack.length > maxSize) {
      newUndoStack.removeAt(0);
    }
    return InputHistory(
      undoStack: newUndoStack,
      redoStack: [],
    );
  }
  
  InputHistory get previous {
    if (!canUndo) return this;
    
    final current = _undoStack.last;
    final newUndoStack = _undoStack.sublist(0, _undoStack.length - 1);
    final newRedoStack = [..._redoStack, current];
    
    return InputHistory(
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
  }
  
  InputHistory get next {
    if (!canRedo) return this;
    
    final current = _redoStack.last;
    final newRedoStack = _redoStack.sublist(0, _redoStack.length - 1);
    final newUndoStack = [..._undoStack, current];
    
    return InputHistory(
      undoStack: newUndoStack,
      redoStack: newRedoStack,
    );
  }
  
  String get current => _undoStack.last;
}
```

### 3.2 RTL 支持设计

根据 PRD 4.1.2 要求，输入模块需要支持从右到左 (RTL) 语言，如阿拉伯语和希伯来语。

#### 3.2.1 TextDirection 检测

```dart
// lib/features/input/utils/text_direction_detector.dart

class TextDirectionDetector {
  /// 检测文本方向
  static TextDirection detectDirection(String text) {
    if (text.isEmpty) {
      // 默认使用 LTR
      return TextDirection.ltr;
    }

    // 检查是否包含 RTL 字符
    final rtlRegex = RegExp(
      r'[\u0591-\u07FF\uFB1D-\uFDFF\uFE70-\uFEFF]'
    );

    // 如果文本以 RTL 字符开头，使用 RTL 方向
    final firstChar = text.trimLeft().substring(0, 1);
    if (rtlRegex.hasMatch(firstChar)) {
      return TextDirection.rtl;
    }

    return TextDirection.ltr;
  }

  /// 根据方向获取 TextAlign
  static TextAlign getTextAlign(TextDirection direction) {
    return direction == TextDirection.rtl
        ? TextAlign.right
        : TextAlign.left;
  }
}
```

#### 3.2.2 RTL 感知 TextField

```dart
// lib/features/input/presentation/widgets/rtl_text_field.dart

class RtlTextField extends ConsumerStatefulWidget {
  final String sessionId;
  final int maxLines;
  final int maxLength;
  final ValueChanged<String>? onSubmitted;
  final TextDirection? initialDirection;

  const RtlTextField({
    super.key,
    required this.sessionId,
    this.maxLines = 5,
    this.maxLength = 10000,
    this.onSubmitted,
    this.initialDirection,
  });

  @override
  ConsumerState<RtlTextField> createState() => _RtlTextFieldState();
}

class _RtlTextFieldState extends ConsumerState<RtlTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  TextDirection _textDirection = TextDirection.ltr;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _textDirection = widget.initialDirection ?? TextDirection.ltr;

    // 监听文本变化以自动切换方向
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final newDirection = TextDirectionDetector.detectDirection(
      _controller.text,
    );

    if (newDirection != _textDirection) {
      setState(() {
        _textDirection = newDirection;
      });
    }

    // 更新 Provider
    ref.read(textInputProvider.notifier).updateText(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textInputProvider);

    return Directionality(
      textDirection: _textDirection,
      child: CupertinoTextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        textAlign: TextDirectionDetector.getTextAlign(_textDirection),
        placeholder: _getLocalizedPlaceholder(context),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        onChanged: (text) {
          ref.read(draftProvider(widget.sessionId).notifier)
              .updateText(text);
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }

  String _getLocalizedPlaceholder(BuildContext context) {
    // 根据当前方向返回相应的占位符
    return _textDirection == TextDirection.rtl
        ? '...اكتب رسالة'
        : S.of(context).typeMessage;
  }
}
```

#### 3.2.3 RTL 配置 Provider

```dart
// lib/features/input/providers/text_input_provider.dart

extension TextInputRtlExtension on TextInput {
  /// 设置文本方向
  void setTextDirection(TextDirection direction) {
    state = state.copyWith(textDirection: direction);
  }

  /// 根据内容自动设置方向
  void autoDetectDirection() {
    final direction = TextDirectionDetector.detectDirection(state.text);
    state = state.copyWith(textDirection: direction);
  }
}

// TextInputState 扩展
class TextInputState {
  // ... 现有字段 ...
  final TextDirection textDirection;

  const TextInputState({
    // ... 现有参数 ...
    this.textDirection = TextDirection.ltr,
  });

  // RTL 相关 getter
  bool get isRtl => textDirection == TextDirection.rtl;
  TextAlign get textAlign => TextDirectionDetector.getTextAlign(textDirection);
}
```

---

### 3.3 Widget 设计

```dart
// lib/features/input/presentation/widgets/text_input_field.dart

class TextInputField extends ConsumerStatefulWidget {
  final String sessionId;
  final int maxLines;
  final int maxLength;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFocus;
  
  const TextInputField({
    super.key,
    required this.sessionId,
    this.maxLines = 5,
    this.maxLength = 10000,
    this.onSubmitted,
    this.onFocus,
  });
  
  @override
  ConsumerState<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends ConsumerState<TextInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    
    // 恢复草稿
    _restoreDraft();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocus?.call();
    }
  }
  
  Future<void> _restoreDraft() async {
    final draft = ref.read(draftProvider(widget.sessionId));
    if (draft.text.isNotEmpty) {
      _controller.text = draft.text;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textInputProvider);
    
    return Column(
      children: [
        // 输入框
        CupertinoTextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          placeholder: S.of(context).typeMessage,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
          ),
          onChanged: (text) {
            ref.read(textInputProvider.notifier).updateText(text);
            ref.read(draftProvider(widget.sessionId).notifier).updateText(text);
          },
          onSubmitted: (text) {
            widget.onSubmitted?.call(text);
          },
        ),
        
        // 字符计数
        if (state.length > widget.maxLength * 0.8)
          _buildCharCounter(context, state),
        
        // 验证错误
        if (!state.isValid)
          _buildValidationError(context, state),
      ],
    );
  }
  
  Widget _buildCharCounter(BuildContext context, TextInputState state) {
    final isOverLimit = state.isOverLimit;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${state.length}/${state.maxLength}',
            style: TextStyle(
              fontSize: 12,
              color: isOverLimit
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildValidationError(BuildContext context, TextInputState state) {
    final error = state.validationErrors.first;
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 14,
            color: CupertinoColors.systemRed,
          ),
          const SizedBox(width: 4),
          Text(
            error.message,
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemRed,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. 图片输入设计

### 4.1 Provider 设计

```dart
// lib/features/input/providers/image_input_provider.dart

@riverpod
class ImageInput extends _$ImageInput {
  @override
  List<ImageContent> build() => [];
  
  /// 从相册选择
  Future<void> pickFromGallery() async {
    if (state.length >= 5) {
      _showLimitError('最多选择 5 张图片');
      return;
    }
    
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    for (final image in images) {
      if (state.length >= 5) break;
      
      final result = await _processImage(image);
      if (result != null) {
        state = [...state, result];
      }
    }
  }
  
  /// 拍照
  Future<void> captureFromCamera() async {
    if (state.length >= 5) {
      _showLimitError('最多选择 5 张图片');
      return;
    }
    
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    
    if (image != null) {
      final result = await _processImage(image);
      if (result != null) {
        state = [...state, result];
      }
    }
  }
  
  /// 从文件路径添加 (桌面端拖放)
  Future<void> addFromPath(String path) async {
    if (state.length >= 5) {
      _showLimitError('最多选择 5 张图片');
      return;
    }
    
    final file = File(path);
    if (!await file.exists()) return;
    
    final bytes = await file.readAsBytes();
    final mimeType = _getMimeType(path);
    
    if (mimeType == null || !mimeType.startsWith('image/')) {
      _showError('不支持的文件类型');
      return;
    }
    
    if (bytes.length > 10 * 1024 * 1024) {
      _showError('图片大小超过 10MB 限制');
      return;
    }
    
    state = [...state, ImageContent(
      mimeType: mimeType,
      data: base64Encode(bytes),
      size: bytes.length,
    )];
  }
  
  /// 从剪贴板粘贴 (桌面端)
  Future<void> pasteFromClipboard() async {
    if (state.length >= 5) {
      _showLimitError('最多选择 5 张图片');
      return;
    }
    
    // 使用 pasteboard 插件获取剪贴板图片
    final pasteboard = Pasteboard();
    final imageBytes = await pasteboard.image;
    
    if (imageBytes != null) {
      if (imageBytes.length > 10 * 1024 * 1024) {
        _showError('图片大小超过 10MB 限制');
        return;
      }
      
      state = [...state, ImageContent(
        mimeType: 'image/png',
        data: base64Encode(imageBytes),
        size: imageBytes.length,
      )];
    }
  }
  
  /// 移除图片
  void removeAt(int index) {
    state = [...state]..removeAt(index);
  }
  
  /// 清除所有图片
  void clear() {
    state = [];
  }
  
  /// 处理图片
  Future<ImageContent?> _processImage(XFile image) async {
    final bytes = await image.readAsBytes();
    
    // 检查大小
    if (bytes.length > 10 * 1024 * 1024) {
      _showError('图片 ${image.name} 超过 10MB 限制');
      return null;
    }
    
    // 获取图片尺寸
    final decodedImage = await decodeImageFromList(bytes);
    
    return ImageContent(
      mimeType: image.mimeType ?? 'image/jpeg',
      data: base64Encode(bytes),
      width: decodedImage.width,
      height: decodedImage.height,
      size: bytes.length,
    );
  }
  
  /// 获取 MIME 类型
  String? _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'heic' || 'heif' => 'image/heic',
      _ => null,
    };
  }
  
  void _showError(String message) {
    // 通过 snackbar 或其他方式显示错误
  }
  
  void _showLimitError(String message) {
    // 显示限制错误
  }
}
```

### 4.2 图片处理服务

```dart
// lib/features/input/data/services/image_processing_service.dart

class ImageProcessingService {
  /// 压缩图片
  Future<Uint8List> compress(
    Uint8List data, {
    int maxSizeMB = 10,
    int quality = 85,
  }) async {
    // 如果已经小于限制，直接返回
    if (data.length <= maxSizeMB * 1024 * 1024) {
      return data;
    }
    
    // 使用 flutter_image_compress 压缩
    final compressed = await FlutterImageCompress.compressWithList(
      data,
      minHeight: 1920,
      minWidth: 1920,
      quality: quality,
    );
    
    // 如果仍然过大，降低质量继续压缩
    if (compressed.length > maxSizeMB * 1024 * 1024 && quality > 10) {
      return compress(data, maxSizeMB: maxSizeMB, quality: quality - 10);
    }
    
    return compressed;
  }
  
  /// 移除 EXIF 数据 (隐私保护)
  Future<Uint8List> stripExif(Uint8List data) async {
    // 使用 image 包处理
    final image = img.decodeImage(data);
    if (image == null) return data;
    
    // 重新编码以移除 EXIF
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }
  
  /// 生成缩略图
  Future<Uint8List> generateThumbnail(
    Uint8List data, {
    int maxSize = 200,
  }) async {
    final image = img.decodeImage(data);
    if (image == null) return data;
    
    // 计算缩放比例
    final ratio = maxSize / max(image.width, image.height);
    if (ratio >= 1) return data;
    
    final thumbnail = img.copyResize(
      image,
      width: (image.width * ratio).round(),
      height: (image.height * ratio).round(),
    );
    
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
  }
  
  /// 转换为 Base64
  String toBase64(Uint8List data) {
    return base64Encode(data);
  }
  
  /// 从 Base64 解码
  Uint8List fromBase64(String base64) {
    return base64Decode(base64);
  }
}
```

### 4.4 EXIF 隐私处理详细设计

#### 处理的 EXIF 数据类型

| 数据类型 | 处理方式 | 说明 |
|----------|----------|------|
| GPS 坐标 | **必须移除** | 防止位置泄露 |
| 拍摄设备 | 必须移除 | 防止设备指纹 |
| 拍摄时间 | 可选移除 | 用户可选择 |
| 图像尺寸 | 保留 | 非敏感信息 |
| 方向信息 | 保留 | 显示必需 |

#### 用户偏好设置

```dart
/// EXIF 处理选项
class ExifProcessingOptions {
  /// 是否移除 GPS 数据
  final bool removeGps;

  /// 是否移除拍摄时间
  final bool removeDateTime;

  /// 是否移除设备信息
  final bool removeDeviceModel;

  const ExifProcessingOptions({
    this.removeGps = true,
    this.removeDateTime = false,
    this.removeDeviceModel = true,
  });

  static const defaults = ExifProcessingOptions();
}
```

#### 处理流程

```
┌─────────────────────────────────────────────────────────────┐
│                    EXIF 隐私处理流程                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  原始图片                                                    │
│      │                                                      │
│      ▼                                                      │
│  ┌─────────────────┐                                        │
│  │ 1. 解析 EXIF    │                                        │
│  │    数据         │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ 2. 应用用户偏好  │                                        │
│  │    配置          │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ 3. 移除敏感字段  │                                        │
│  │    (GPS/设备)    │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  ┌─────────────────┐                                        │
│  │ 4. 重新编码      │                                        │
│  │    (保持质量)    │                                        │
│  └────────┬────────┘                                        │
│           │                                                 │
│           ▼                                                 │
│  处理后图片 (已移除敏感 EXIF)                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 实现细节

```dart
/// EXIF 隐私处理实现
Future<Uint8List> stripExif(
  Uint8List data, {
  ExifProcessingOptions options = ExifProcessingOptions.defaults,
}) async {
  // 使用 image 包处理
  final image = img.decodeImage(data);
  if (image == null) return data;

  // 移除 GPS 数据 (必须)
  if (options.removeGps) {
    image.exif.gps = null;
  }

  // 移除设备信息 (必须)
  if (options.removeDeviceModel) {
    image.exif.imageIfd.make = null;
    image.exif.imageIfd.model = null;
    image.exif.exifIfd.lensModel = null;
  }

  // 移除拍摄时间 (可选)
  if (options.removeDateTime) {
    image.exif.imageIfd.dateTime = null;
    image.exif.exifIfd.dateTimeOriginal = null;
    image.exif.exifIfd.dateTimeDigitized = null;
  }

  // 重新编码以应用更改
  // JPEG 使用原质量，PNG 无损
  if (data.length > 10 && data[0] == 0xFF && data[1] == 0xD8) {
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  } else {
    return Uint8List.fromList(img.encodePng(image));
  }
}
```

#### 平台特定考虑

| 平台 | 考虑事项 |
|------|----------|
| iOS | HEIC 格式需要先转换为 JPEG/PNG 再处理 |
| Android | 部分设备 EXIF 字段名不同 |
| macOS/Windows | 支持所有常见格式 |

#### 测试用例

```dart
test('stripExif 应移除 GPS 数据', () async {
  // arrange
  final imageWithGps = await loadTestImage('with_gps.jpg');
  final service = ImageProcessingService();

  // act
  final result = await service.stripExif(imageWithGps);

  // assert
  final exif = img.decodeImage(result)!.exif;
  expect(exif.gps, isNull);
});

test('stripExif 应保留图像质量', () async {
  // arrange
  final original = await loadTestImage('sample.jpg');
  final service = ImageProcessingService();

  // act
  final processed = await service.stripExif(original);

  // assert
  // 尺寸应保持一致
  final originalImage = img.decodeImage(original)!;
  final processedImage = img.decodeImage(processed)!;
  expect(originalImage.width, equals(processedImage.width));
  expect(originalImage.height, equals(processedImage.height));
});
```

### 4.3 Widget 设计

```dart
// lib/features/input/presentation/widgets/image_preview_grid.dart

class ImagePreviewGrid extends ConsumerWidget {
  final String sessionId;
  final int maxImages;
  
  const ImagePreviewGrid({
    super.key,
    required this.sessionId,
    this.maxImages = 5,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(imageInputProvider);
    
    if (images.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _buildImageItem(context, ref, images[index], index);
        },
      ),
    );
  }
  
  Widget _buildImageItem(
    BuildContext context,
    WidgetRef ref,
    ImageContent image,
    int index,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // 图片预览
          GestureDetector(
            onTap: () => _showImagePreview(context, image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(image.data),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 删除按钮
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                ref.read(imageInputProvider.notifier).removeAt(index);
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 12,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
          
          // 文件大小
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                _formatSize(image.size ?? 0),
                style: const TextStyle(
                  fontSize: 10,
                  color: CupertinoColors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showImagePreview(BuildContext context, ImageContent image) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ImagePreviewPage(image: image),
      ),
    );
  }
  
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

---

## 5. 语音输入设计

### 5.1 Provider 设计

```dart
// lib/features/input/providers/voice_input_provider.dart

@riverpod
class VoiceInput extends _$VoiceInput {
  AudioRecorder? _recorder;
  AudioPlayer? _player;
  Timer? _durationTimer;
  StreamSubscription? _amplitudeSubscription;
  
  @override
  VoiceInputState build() => VoiceInputState.idle();
  
  /// 开始录音
  Future<void> startRecording() async {
    if (state.status != RecordingStatus.idle) return;
    
    _recorder = AudioRecorder();
    
    // 检查权限
    final hasPermission = await _recorder!.hasPermission();
    if (!hasPermission) {
      state = VoiceInputState.error('麦克风权限未授权');
      return;
    }
    
    // 更新状态
    state = VoiceInputState.recording(
      startTime: DateTime.now(),
      duration: Duration.zero,
      amplitudes: [],
    );
    
    // 开始录音
    final path = await _getRecordingPath();
    await _recorder!.start(
      RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: path,
    );
    
    // 监听振幅
    _amplitudeSubscription = _recorder!.onAmplitude().listen((amp) {
      final current = state;
      if (current.status == RecordingStatus.recording) {
        state = current.copyWith(
          amplitudes: [...current.amplitudes, amp.current],
        );
      }
    });
    
    // 更新时长
    _startDurationTimer();
  }
  
  /// 停止录音
  Future<void> stopRecording() async {
    if (state.status != RecordingStatus.recording) return;
    
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    
    final path = await _recorder!.stop();
    await _recorder!.dispose();
    _recorder = null;
    
    if (path != null) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      // 检查大小
      if (bytes.length > 10 * 1024 * 1024) {
        state = VoiceInputState.error('录音文件超过 10MB');
        return;
      }
      
      // 检查时长
      if (state.duration!.inSeconds >= 60) {
        state = VoiceInputState.error('录音超过 60 秒');
        return;
      }
      
      // 更新状态为预览
      state = VoiceInputState.preview(
        path: path,
        duration: state.duration!,
        data: base64Encode(bytes),
        amplitudes: state.amplitudes,
      );
    } else {
      state = VoiceInputState.idle();
    }
  }
  
  /// 取消录音
  Future<void> cancelRecording() async {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    
    await _recorder?.stop();
    await _recorder?.dispose();
    _recorder = null;
    
    state = VoiceInputState.idle();
  }
  
  /// 播放预览
  Future<void> playPreview() async {
    if (state.status != RecordingStatus.preview) return;
    
    _player = AudioPlayer();
    
    state = state.copyWith(isPlaying: true);
    
    await _player!.play(DeviceFileSource(state.path!));
    
    _player!.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false);
    });
  }
  
  /// 停止播放
  Future<void> stopPlaying() async {
    await _player?.stop();
    await _player?.dispose();
    _player = null;
    
    state = state.copyWith(isPlaying: false);
  }
  
  /// 确认并清除
  void confirmAndClear() {
    state = VoiceInputState.idle();
  }
  
  /// 清除
  void clear() {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder?.dispose();
    _player?.dispose();
    
    state = VoiceInputState.idle();
  }
  
  /// 开始时长计时器
  void _startDurationTimer() {
    bool warningShown = false;
    
    _durationTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) async {
        final current = state;
        if (current.status != RecordingStatus.recording) {
          timer.cancel();
          return;
        }
        
        final elapsed = DateTime.now().difference(current.startTime!);
        
        // 50 秒时显示警告 (PRD 4.3.3)
        if (elapsed.inSeconds >= 50 && !warningShown) {
          warningShown = true;
          _show50SecondWarning();
        }
        
        // 60 秒自动停止
        if (elapsed.inSeconds >= 60) {
          timer.cancel();
          await stopRecording();
          return;
        }
        
        state = current.copyWith(duration: elapsed);
      },
    );
  }
  
  /// 显示 50 秒警告 (PRD 4.3.3)
  void _show50SecondWarning() {
    // 发送事件到 UI 层显示警告
    state = state.copyWith(
      showWarning: true,
      warningMessage: '录音即将达到 60 秒上限，是否继续？',
    );
  }
  
  /// 用户选择继续录音
  void continueRecording() {
    state = state.copyWith(showWarning: false);
  }
  
  /// 用户选择停止录音
  Future<void> stopAtWarning() async {
    state = state.copyWith(showWarning: false);
    await stopRecording();
  }
  
  /// 获取录音路径
  Future<String> _getRecordingPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }
}

/// 录音状态枚举
enum RecordingStatus {
  idle,
  recording,
  preview,
  error,
}

/// 语音输入状态
class VoiceInputState {
  final RecordingStatus status;
  final DateTime? startTime;
  final Duration? duration;
  final String? path;
  final String? data;
  final List<double>? amplitudes;
  final bool isPlaying;
  final String? error;
  // 50 秒警告相关字段 (PRD 4.3.3)
  final bool showWarning;
  final String? warningMessage;
  
  const VoiceInputState._({
    required this.status,
    this.startTime,
    this.duration,
    this.path,
    this.data,
    this.amplitudes,
    this.isPlaying = false,
    this.error,
    this.showWarning = false,
    this.warningMessage,
  });
  
  static VoiceInputState idle() => const VoiceInputState._(
    status: RecordingStatus.idle,
  );
  
  static VoiceInputState recording({
    required DateTime startTime,
    required Duration duration,
    required List<double> amplitudes,
    bool showWarning = false,
    String? warningMessage,
  }) => VoiceInputState._(
    status: RecordingStatus.recording,
    startTime: startTime,
    duration: duration,
    amplitudes: amplitudes,
    showWarning: showWarning,
    warningMessage: warningMessage,
  );
  
  static VoiceInputState preview({
    required String path,
    required Duration duration,
    required String data,
    required List<double> amplitudes,
  }) => VoiceInputState._(
    status: RecordingStatus.preview,
    path: path,
    duration: duration,
    data: data,
    amplitudes: amplitudes,
  );
  
  static VoiceInputState error(String error) => VoiceInputState._(
    status: RecordingStatus.error,
    error: error,
  );
  
  VoiceInputState copyWith({
    RecordingStatus? status,
    DateTime? startTime,
    Duration? duration,
    String? path,
    String? data,
    List<double>? amplitudes,
    bool? isPlaying,
    String? error,
    bool? showWarning,
    String? warningMessage,
  }) => VoiceInputState._(
    status: status ?? this.status,
    startTime: startTime ?? this.startTime,
    duration: duration ?? this.duration,
    path: path ?? this.path,
    data: data ?? this.data,
    amplitudes: amplitudes ?? this.amplitudes,
    isPlaying: isPlaying ?? this.isPlaying,
    error: error ?? this.error,
    showWarning: showWarning ?? this.showWarning,
    warningMessage: warningMessage ?? this.warningMessage,
  );
  
  bool get isRecording => status == RecordingStatus.recording;
  bool get isPreview => status == RecordingStatus.preview;
  bool get hasError => status == RecordingStatus.error;
  bool get canSend => isPreview && data != null;
  
  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration!.inMinutes;
    final seconds = duration!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
```

### 5.2 波形显示组件

```dart
// lib/features/input/presentation/widgets/voice_waveform.dart

class VoiceWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final double width;
  final double height;
  final Color color;
  final bool animate;
  
  const VoiceWaveform({
    super.key,
    required this.amplitudes,
    this.width = 200,
    this.height = 40,
    this.color = CupertinoColors.activeBlue,
    this.animate = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: WaveformPainter(
          amplitudes: amplitudes,
          color: color,
          animate: animate,
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final bool animate;
  
  WaveformPainter({
    required this.amplitudes,
    required this.color,
    required this.animate,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final barWidth = size.width / amplitudes.length;
    final centerY = size.height / 2;
    
    for (var i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i].clamp(0.0, 1.0);
      final barHeight = amplitude * size.height * 0.8;
      
      final x = i * barWidth + barWidth / 2;
      final y1 = centerY - barHeight / 2;
      final y2 = centerY + barHeight / 2;
      
      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return amplitudes != oldDelegate.amplitudes || 
           animate != oldDelegate.animate;
  }
}
```

### 5.3 录音按钮组件

```dart
// lib/features/input/presentation/widgets/voice_record_button.dart

class VoiceRecordButton extends ConsumerWidget {
  final String sessionId;
  
  const VoiceRecordButton({
    super.key,
    required this.sessionId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceInputProvider);
    
    return GestureDetector(
      onLongPressStart: (_) => _startRecording(ref),
      onLongPressEnd: (_) => _stopRecording(ref),
      onLongPressCancel: () => _cancelRecording(ref),
      child: _buildButton(context, ref, state),
    );
  }
  
  Widget _buildButton(
    BuildContext context,
    WidgetRef ref,
    VoiceInputState state,
  ) {
    if (state.isRecording) {
      return _buildRecordingButton(context, ref, state);
    }
    
    if (state.isPreview) {
      return _buildPreviewButton(context, ref, state);
    }
    
    if (state.hasError) {
      return _buildErrorButton(context, ref, state);
    }
    
    return _buildIdleButton(context);
  }
  
  Widget _buildIdleButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        CupertinoIcons.mic,
        color: CupertinoColors.activeBlue,
      ),
    );
  }
  
  Widget _buildRecordingButton(
    BuildContext context,
    WidgetRef ref,
    VoiceInputState state,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 波形
        VoiceWaveform(
          amplitudes: state.amplitudes ?? [],
          width: 150,
          height: 40,
        ),
        
        const SizedBox(height: 8),
        
        // 时长
        Text(
          state.formattedDuration,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 按钮
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.mic_fill,
            color: CupertinoColors.white,
            size: 28,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewButton(
    BuildContext context,
    WidgetRef ref,
    VoiceInputState state,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 播放按钮
        GestureDetector(
          onTap: () => _togglePlayPreview(ref, state),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isPlaying ? CupertinoIcons.stop : CupertinoIcons.play,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // 时长
        Text(
          state.formattedDuration,
          style: const TextStyle(fontSize: 14),
        ),
        
        const SizedBox(width: 8),
        
        // 取消按钮
        GestureDetector(
          onTap: () => ref.read(voiceInputProvider.notifier).clear(),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.xmark,
              color: CupertinoColors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorButton(
    BuildContext context,
    WidgetRef ref,
    VoiceInputState state,
  ) {
    return GestureDetector(
      onTap: () => ref.read(voiceInputProvider.notifier).clear(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              color: CupertinoColors.systemRed,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              state.error ?? '错误',
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _startRecording(WidgetRef ref) {
    ref.read(voiceInputProvider.notifier).startRecording();
  }
  
  void _stopRecording(WidgetRef ref) {
    ref.read(voiceInputProvider.notifier).stopRecording();
  }
  
  void _cancelRecording(WidgetRef ref) {
    ref.read(voiceInputProvider.notifier).cancelRecording();
  }
  
  void _togglePlayPreview(WidgetRef ref, VoiceInputState state) {
    if (state.isPlaying) {
      ref.read(voiceInputProvider.notifier).stopPlaying();
    } else {
      ref.read(voiceInputProvider.notifier).playPreview();
    }
  }
}
```

### 5.4 50 秒警告 UI 组件

根据 PRD 4.3.3 要求，在录音达到 50 秒时显示警告提示。

```dart
// lib/features/input/presentation/widgets/voice_warning_dialog.dart

class VoiceWarningDialog extends ConsumerWidget {
  const VoiceWarningDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceInputProvider);

    if (!state.showWarning) {
      return const SizedBox.shrink();
    }

    return CupertinoAlertDialog(
      title: const Text('录音即将结束'),
      content: Text(
        state.warningMessage ?? '录音即将达到 60 秒上限',
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('停止'),
          onPressed: () {
            ref.read(voiceInputProvider.notifier).stopAtWarning();
          },
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('继续'),
          onPressed: () {
            ref.read(voiceInputProvider.notifier).continueRecording();
          },
        ),
      ],
    );
  }
}

// 在录音按钮组件中集成警告显示
class VoiceRecordButton extends ConsumerWidget {
  // ... 现有代码 ...

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceInputProvider);

    // 显示警告对话框
    if (state.showWarning) {
      showCupertinoDialog(
        context: context,
        builder: (context) => const VoiceWarningDialog(),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(ref),
      onLongPressEnd: (_) => _stopRecording(ref),
      onLongPressCancel: () => _cancelRecording(ref),
      child: _buildButton(context, ref, state),
    );
  }
}
```

---

## 6. 连接复制功能 (PRD 5.1.1)

### 6.1 概述

根据 PRD 5.1.1 要求，需要实现连接复制功能。用户可以复制现有连接的配置，创建一个新的连接，同时清除敏感数据（token、密码等）。

### 6.2 Provider 设计

```dart
// lib/features/connection/providers/connection_list_provider.dart

@riverpod
class ConnectionList extends _$ConnectionList {
  @override
  List<Connection> build() => [];

  /// 复制连接 (PRD 5.1.1)
  /// 
  /// 复制指定连接的配置，创建新连接，清除敏感数据
  Connection copyConnection(String sourceId) {
    // 查找源连接
    final source = state.firstWhere(
      (c) => c.id == sourceId,
      orElse: () => throw ConnectionNotFoundException(sourceId),
    );

    // 生成新 ID
    final newId = _generateConnectionId();

    // 创建复制，清除敏感数据
    final copied = source.copyWith(
      id: newId,
      name: '${source.name} (复制)',
      // 清除敏感数据
      token: null,
      password: null,
      apiKey: null,
      secret: null,
      // 重置状态 - 连接状态由 ConnectionManager 管理
      lastConnectedAt: null,
      // 保留其他配置
      url: source.url,
      port: source.port,
      protocol: source.protocol,
      settings: source.settings,
      // 记录复制来源
      copiedFrom: sourceId,
      createdAt: DateTime.now(),
    );

    // 添加到列表
    state = [...state, copied];

    return copied;
  }

  /// 复制连接并立即编辑
  Future<Connection?> copyAndEdit(String sourceId) async {
    final copied = copyConnection(sourceId);
    
    // 导航到编辑页面，让用户填写敏感信息
    final result = await _navigateToEditPage(copied.id);
    
    return result;
  }

  /// 批量复制连接
  List<Connection> copyMultipleConnections(List<String> sourceIds) {
    final copied = <Connection>[];
    
    for (final sourceId in sourceIds) {
      try {
        final connection = copyConnection(sourceId);
        copied.add(connection);
      } catch (e) {
        // 记录错误但继续处理其他连接
        _logCopyError(sourceId, e);
      }
    }
    
    return copied;
  }

  String _generateConnectionId() {
    return 'conn_${DateTime.now().millisecondsSinceEpoch}_${_randomString(6)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  void _logCopyError(String sourceId, Object error) {
    // 记录复制错误日志
  }

  Future<Connection?> _navigateToEditPage(String connectionId) async {
    // 导航到编辑页面的实现
    return null;
  }
}
```

### 6.3 Connection 实体扩展

```dart
// lib/features/connection/domain/entities/connection.dart

class Connection {
  final String id;
  final String name;
  final String? url;
  final int? port;
  final ConnectionProtocol protocol;
  
  // 敏感数据（复制时会被清除）
  final String? token;
  final String? password;
  final String? apiKey;
  final String? secret;
  
  // 配置设置
  final ConnectionSettings settings;
  
  // 状态
  final bool isConnected;
  final DateTime? lastConnectedAt;
  
  // 元数据
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? copiedFrom; // 记录复制来源 (PRD 5.1.1)

  const Connection({
    required this.id,
    required this.name,
    this.url,
    this.port,
    required this.protocol,
    this.token,
    this.password,
    this.apiKey,
    this.secret,
    required this.settings,
    this.isConnected = false,
    this.lastConnectedAt,
    required this.createdAt,
    this.updatedAt,
    this.copiedFrom,
  });

  Connection copyWith({
    String? id,
    String? name,
    String? url,
    int? port,
    ConnectionProtocol? protocol,
    String? token,
    String? password,
    String? apiKey,
    String? secret,
    ConnectionSettings? settings,
    bool? isConnected,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? copiedFrom,
  }) {
    return Connection(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      token: token ?? this.token,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      secret: secret ?? this.secret,
      settings: settings ?? this.settings,
      isConnected: isConnected ?? this.isConnected,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      copiedFrom: copiedFrom ?? this.copiedFrom,
    );
  }

  /// 检查是否包含敏感数据
  bool get hasSensitiveData {
    return token != null ||
           password != null ||
           apiKey != null ||
           secret != null;
  }

  /// 清除敏感数据后的副本
  Connection clearedSensitiveData() {
    return copyWith(
      token: null,
      password: null,
      apiKey: null,
      secret: null,
    );
  }
}
```

### 6.4 UI 组件

```dart
// lib/features/connection/presentation/widgets/connection_list_item.dart

class ConnectionListItem extends ConsumerWidget {
  final Connection connection;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ConnectionListItem({
    super.key,
    required this.connection,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoContextMenu(
      actions: [
        // 复制连接 (PRD 5.1.1)
        CupertinoContextMenuAction(
          child: const Text('复制'),
          onPressed: () {
            _copyConnection(context, ref);
          },
        ),
        CupertinoContextMenuAction(
          child: const Text('编辑'),
          onPressed: () {
            onEdit?.call();
          },
        ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          child: const Text('删除'),
          onPressed: () {
            onDelete?.call();
          },
        ),
      ],
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 连接状态指示器
          _buildStatusIndicator(),
          
          const SizedBox(width: 12),
          
          // 连接信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (connection.url != null)
                  Text(
                    connection.url!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                // 显示复制来源标记
                if (connection.copiedFrom != null)
                  _buildCopiedBadge(),
              ],
            ),
          ),
          
          // 敏感数据警告
          if (!connection.hasSensitiveData && !connection.isConnected)
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: CupertinoColors.systemOrange,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: connection.isConnected
            ? CupertinoColors.systemGreen
            : CupertinoColors.systemGrey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCopiedBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '已复制',
        style: TextStyle(
          fontSize: 10,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  void _copyConnection(BuildContext context, WidgetRef ref) {
    try {
      final copied = ref.read(connectionListProvider.notifier)
          .copyConnection(connection.id);
      
      // 显示成功提示
      _showSuccessSnackBar(context, '已复制连接: ${copied.name}');
      
      // 提示用户配置敏感信息
      _showSensitiveDataDialog(context, ref, copied.id);
    } catch (e) {
      _showErrorSnackBar(context, '复制失败: $e');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    // 显示成功提示的实现
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    // 显示错误提示的实现
  }

  void _showSensitiveDataDialog(BuildContext context, WidgetRef ref, String connectionId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('需要配置'),
        content: const Text(
          '复制的连接需要重新配置敏感信息（Token、密码等）才能使用。'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('稍后'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('立即配置'),
            onPressed: () {
              Navigator.of(context).pop();
              // 导航到编辑页面
              onEdit?.call();
            },
          ),
        ],
      ),
    );
  }
}
```

### 6.5 安全考虑

```dart
// lib/features/connection/utils/connection_security.dart

class ConnectionSecurity {
  /// 敏感字段列表
  static const List<String> sensitiveFields = [
    'token',
    'password',
    'apiKey',
    'secret',
    'privateKey',
    'credential',
  ];

  /// 检查字段是否为敏感字段
  static bool isSensitiveField(String fieldName) {
    return sensitiveFields.contains(fieldName.toLowerCase());
  }

  /// 清除对象中的敏感数据
  static Map<String, dynamic> stripSensitiveData(
    Map<String, dynamic> data,
  ) {
    final result = Map<String, dynamic>.from(data);
    
    for (final field in sensitiveFields) {
      if (result.containsKey(field)) {
        result.remove(field);
      }
    }
    
    return result;
  }

  /// 验证连接是否可发送消息
  /// 
  /// 如果缺少敏感数据，返回 false
  static bool canSendMessages(Connection connection) {
    // 检查必要的敏感数据是否存在
    switch (connection.protocol) {
      case ConnectionProtocol.webSocket:
        return connection.token != null || connection.password != null;
      case ConnectionProtocol.http:
        return connection.apiKey != null;
      case ConnectionProtocol.grpc:
        return connection.token != null;
      default:
        return false;
    }
  }
}
```

---

## 7. 平台适配

### 7.1 权限处理

```dart
// lib/features/input/data/services/permission_service.dart

class PermissionService {
  /// 请求相机权限
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  /// 请求麦克风权限
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// 请求相册权限
  Future<bool> requestPhotoLibraryPermission() async {
    PermissionStatus status;
    
    if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else if (Platform.isAndroid) {
      // Android 13+ 使用 photos 权限
      // Android 12 及以下使用 storage 权限
      if (await _isAndroid13OrHigher()) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }
    } else {
      // 桌面端无需权限
      return true;
    }
    
    return status.isGranted;
  }
  
  /// 检查相机权限
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }
  
  /// 检查麦克风权限
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  /// 检查相册权限
  Future<bool> checkPhotoLibraryPermission() async {
    if (Platform.isIOS) {
      final status = await Permission.photos.status;
      return status.isGranted;
    } else if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.status;
        return status.isGranted;
      } else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    }
    return true;
  }
  
  /// 打开权限设置
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 33;
  }
}
```

### 7.2 平台特性处理

```dart
// lib/features/input/data/services/platform_input_service.dart

class PlatformInputService {
  /// 是否支持相机
  bool get hasCamera {
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      // 桌面端可能有外接摄像头
      return true;
    }
    return true;
  }
  
  /// 是否支持拖放
  bool get supportsDragAndDrop {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }
  
  /// 是否支持剪贴板图片
  bool get supportsClipboardImage {
    return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }
  
  /// 处理拖放文件
  Future<List<String>> handleDroppedFiles(DropDoneEvent event) async {
    final paths = <String>[];
    
    for (final file in event.files) {
      final path = file.path;
      final extension = path.split('.').last.toLowerCase();
      
      // 检查是否是支持的图片格式
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(extension)) {
        paths.add(path);
      }
    }
    
    return paths;
  }
}
```

---

## 8. 测试用例

### 8.1 Provider 测试

```dart
void main() {
  group('TextInputProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为空', () {
      final state = container.read(textInputProvider);
      expect(state.isEmpty, isTrue);
      expect(state.isValid, isTrue);
    });
    
    test('updateText 应更新文本', () {
      container.read(textInputProvider.notifier).updateText('Hello');
      
      final state = container.read(textInputProvider);
      expect(state.text, equals('Hello'));
      expect(state.length, equals(5));
    });
    
    test('超过最大长度应验证失败', () {
      final longText = 'a' * 10001;
      container.read(textInputProvider.notifier).updateText(longText);
      
      final state = container.read(textInputProvider);
      expect(state.isValid, isFalse);
      expect(state.isOverLimit, isTrue);
    });
    
    test('insertAtCursor 应在光标处插入', () {
      container.read(textInputProvider.notifier).updateText('Hello World');
      container.read(textInputProvider.notifier).updateSelection(
        const TextSelection(baseOffset: 6, extentOffset: 11),
      );
      
      container.read(textInputProvider.notifier).insertAtCursor('Flutter');
      
      final state = container.read(textInputProvider);
      expect(state.text, equals('Hello Flutter'));
    });
    
    test('clear 应清除文本', () {
      container.read(textInputProvider.notifier).updateText('Hello');
      container.read(textInputProvider.notifier).clear();
      
      final state = container.read(textInputProvider);
      expect(state.isEmpty, isTrue);
    });
  });
  
  group('ImageInputProvider', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为空列表', () {
      final images = container.read(imageInputProvider);
      expect(images.isEmpty, isTrue);
    });
    
    test('removeAt 应移除指定索引的图片', () {
      // 手动添加测试图片
      container.read(imageInputProvider.notifier).state = [
        ImageContent(mimeType: 'image/png', data: 'a'),
        ImageContent(mimeType: 'image/png', data: 'b'),
      ];
      
      container.read(imageInputProvider.notifier).removeAt(0);
      
      final images = container.read(imageInputProvider);
      expect(images.length, equals(1));
    });
    
    test('clear 应清除所有图片', () {
      container.read(imageInputProvider.notifier).state = [
        ImageContent(mimeType: 'image/png', data: 'a'),
      ];
      
      container.read(imageInputProvider.notifier).clear();
      
      final images = container.read(imageInputProvider);
      expect(images.isEmpty, isTrue);
    });
  });
  
  group('VoiceInputProvider', () {
    late ProviderContainer container;
    late MockAudioRecorder mockRecorder;
    
    setUp(() {
      mockRecorder = MockAudioRecorder();
      container = ProviderContainer();
    });
    
    tearDown(() {
      container.dispose();
    });
    
    test('初始状态应为 idle', () {
      final state = container.read(voiceInputProvider);
      expect(state.status, equals(RecordingStatus.idle));
    });
    
    test('cancelRecording 应恢复到 idle 状态', () async {
      // 模拟开始录音
      when(() => mockRecorder.hasPermission())
          .thenAnswer((_) async => true);
      when(() => mockRecorder.start(any(), path: any(named: 'path')))
          .thenAnswer((_) async => 'test.m4a');
      
      await container.read(voiceInputProvider.notifier).startRecording();
      
      // 取消
      await container.read(voiceInputProvider.notifier).cancelRecording();
      
      final state = container.read(voiceInputProvider);
      expect(state.status, equals(RecordingStatus.idle));
    });
    
    test('clear 应清除所有状态', () {
      container.read(voiceInputProvider.notifier).clear();
      
      final state = container.read(voiceInputProvider);
      expect(state.status, equals(RecordingStatus.idle));
    });
  });
}
```

### 8.2 Widget 测试

```dart
void main() {
  group('TextInputField', () {
    testWidgets('应显示占位符', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: TextInputField(sessionId: 'test'),
        ),
      );
      
      expect(find.text('Type a message...'), findsOneWidget);
    });
    
    testWidgets('字符计数应在接近限制时显示', (tester) async {
      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: CupertinoApp(
            home: Scaffold(
              body: TextInputField(sessionId: 'test', maxLength: 10),
            ),
          ),
        ),
      );
      
      // 输入 9 个字符 (90%)
      await tester.enterText(find.byType(CupertinoTextField), '123456789');
      await tester.pump();
      
      expect(find.text('9/10'), findsOneWidget);
      
      container.dispose();
    });
  });
  
  group('ImagePreviewGrid', () {
    testWidgets('空列表不应显示', (tester) async {
      final container = ProviderContainer();
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: CupertinoApp(
            home: Scaffold(
              body: ImagePreviewGrid(sessionId: 'test'),
            ),
          ),
        ),
      );
      
      expect(find.byType(SizedBox), findsOneWidget);
      
      container.dispose();
    });
  });
}
```

---

## 9. 附录

### 9.1 输入验证错误类型

```dart
sealed class InputValidationError {
  String get message;
}

class TextTooLongError extends InputValidationError {
  final int actual;
  final int max;
  
  TextTooLongError({required this.actual, required this.max});
  
  @override
  String get message => '文本长度超出限制 ($actual/$max)';
}

class ImageSizeExceededError extends InputValidationError {
  final String fileName;
  final int size;
  
  ImageSizeExceededError({required this.fileName, required this.size});
  
  @override
  String get message => '$fileName 大小超过 10MB 限制';
}

class ImageCountExceededError extends InputValidationError {
  final int count;
  
  ImageCountExceededError({required this.count});
  
  @override
  String get message => '最多选择 5 张图片';
}

class AudioDurationExceededError extends InputValidationError {
  final int seconds;
  
  AudioDurationExceededError({required this.seconds});
  
  @override
  String get message => '录音时长超过 60 秒限制';
}

class AudioSizeExceededError extends InputValidationError {
  final int size;
  
  AudioSizeExceededError({required this.size});
  
  @override
  String get message => '录音文件大小超过 10MB 限制';
}
```

### 9.2 支持的图片格式

| 格式 | MIME 类型 | 最大尺寸 |
|------|-----------|----------|
| JPEG | image/jpeg | 10MB |
| PNG | image/png | 10MB |
| GIF | image/gif | 10MB |
| WebP | image/webp | 10MB |
| HEIC | image/heic | 10MB |

### 9.3 支持的音频格式

| 格式 | MIME 类型 | 最大时长 | 最大尺寸 |
|------|-----------|----------|----------|
| AAC | audio/aac | 60s | 10MB |
| M4A | audio/mp4 | 60s | 10MB |

### 9.4 变更历史

| 版本 | 日期 | 变更内容 | 作者 |
|------|------|----------|------|
| 1.0.0 | 2026-03-16 | 初始版本 | 架构师 |

---

**文档结束**