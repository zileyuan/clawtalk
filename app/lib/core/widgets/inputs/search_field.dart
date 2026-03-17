import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Search field with clear button and consistent iOS styling.
///
/// Designed for use in navigation bars or as a standalone search input.
class AppSearchField extends StatefulWidget {
  /// Creates a search field.
  const AppSearchField({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.showClearButton = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  /// Text controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String placeholder;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when clear button is tapped.
  final VoidCallback? onClear;

  /// Whether to autofocus.
  final bool autofocus;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether to show the clear button.
  final bool showClearButton;

  /// Padding around the field.
  final EdgeInsetsGeometry padding;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: widget.padding,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.systemGrey5.darkColor
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(10),
          border: _isFocused
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.search,
              size: 18,
              color: isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                focusNode: _focusNode,
                placeholder: widget.placeholder,
                placeholderStyle: TextStyle(
                  color: isDark
                      ? CupertinoColors.placeholderText.darkColor
                      : CupertinoColors.placeholderText,
                  fontSize: 16,
                ),
                style: TextStyle(
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  fontSize: 16,
                ),
                decoration: null,
                padding: const EdgeInsets.symmetric(vertical: 8),
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                autofocus: widget.autofocus,
                enabled: widget.enabled,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                clearButtonMode: widget.showClearButton
                    ? OverlayVisibilityMode.editing
                    : OverlayVisibilityMode.never,
              ),
            ),
            if (_controller.text.isNotEmpty && widget.showClearButton) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: _clear,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.xmark,
                    size: 12,
                    color: isDark
                        ? CupertinoColors.black
                        : CupertinoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else ...[
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

/// A search bar for use in navigation areas.
class AppSearchBar extends StatelessWidget {
  /// Creates a search bar.
  const AppSearchBar({
    super.key,
    this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
    this.showCancelButton = true,
    this.autofocus = false,
  });

  /// Text controller.
  final TextEditingController? controller;

  /// Placeholder text.
  final String placeholder;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when cancel is tapped.
  final VoidCallback? onCancel;

  /// Whether to show cancel button.
  final bool showCancelButton;

  /// Whether to autofocus.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark
          ? CupertinoColors.systemBackground.darkColor
          : CupertinoColors.systemBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: AppSearchField(
                controller: controller,
                placeholder: placeholder,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                autofocus: autofocus,
                padding: EdgeInsets.zero,
              ),
            ),
            if (showCancelButton) ...[
              const SizedBox(width: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
