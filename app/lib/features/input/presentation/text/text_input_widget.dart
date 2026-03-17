import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../../../core/constants/content_limits.dart';
import 'text_counter.dart';

/// A multi-line text input widget with auto-grow height, character counter,
/// placeholder text, and clear button.
class TextInputWidget extends StatefulWidget {
  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when text is submitted
  final ValueChanged<String>? onSubmitted;

  /// Placeholder text shown when input is empty
  final String placeholder;

  /// Maximum number of characters allowed
  final int? maxLength;

  /// Maximum number of lines before scrolling
  final int maxLines;

  /// Minimum number of lines
  final int minLines;

  /// Whether to show character counter
  final bool showCounter;

  /// Whether to auto-focus the input
  final bool autofocus;

  /// Whether to enable clear button
  final bool showClearButton;

  /// Custom validator function
  final String? Function(String)? validator;

  /// Controller for the text input
  final TextEditingController? controller;

  /// Focus node for controlling focus
  final FocusNode? focusNode;

  /// Whether the input is enabled
  final bool enabled;

  const TextInputWidget({
    super.key,
    this.onChanged,
    this.onSubmitted,
    this.placeholder = 'Type a message...',
    this.maxLength,
    this.maxLines = 6,
    this.minLines = 1,
    this.showCounter = true,
    this.autofocus = false,
    this.showClearButton = true,
    this.validator,
    this.controller,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<TextInputWidget> createState() => _TextInputWidgetState();
}

class _TextInputWidgetState extends State<TextInputWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged() {
    _validate();
    widget.onChanged?.call(_controller.text);
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _validationError = widget.validator!(_controller.text);
      });
    } else {
      setState(() {
        _validationError = null;
      });
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.tertiarySystemBackground.darkColor
                : CupertinoColors.tertiarySystemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _validationError != null
                  ? AppColors.error
                  : _isFocused
                  ? AppColors.accent
                  : CupertinoColors.separator,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Stack(
            children: [
              CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                placeholder: widget.placeholder,
                placeholderStyle: AppTextStyles.body.copyWith(
                  color: CupertinoColors.placeholderText,
                ),
                style: AppTextStyles.body,
                maxLines: widget.maxLines,
                minLines: widget.minLines,
                maxLength: widget.maxLength ?? ContentLimits.maxTextLength,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: widget.onSubmitted,
                padding: const EdgeInsets.all(16),
                decoration: null,
                onTapOutside: (_) => _focusNode.unfocus(),
              ),
              if (widget.showClearButton && _controller.text.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ClearButton(onTap: _clearText),
                ),
            ],
          ),
        ),
        if (widget.showCounter || _validationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
            child: Row(
              children: [
                if (_validationError != null)
                  Expanded(
                    child: Text(
                      _validationError!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (widget.showCounter)
                  TextCounter(
                    currentLength: _controller.text.length,
                    maxLength: widget.maxLength ?? ContentLimits.maxTextLength,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Clear button widget for the text input
class _ClearButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 28,
      onPressed: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: CupertinoColors.systemGrey3,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.clear,
          size: 12,
          color: CupertinoColors.white,
        ),
      ),
    );
  }
}
