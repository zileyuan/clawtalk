import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../themes/app_colors.dart';

/// Styled Cupertino text field with validation support.
///
/// Wraps [CupertinoTextField] with consistent theming and adds
/// validation error display capabilities.
class AppCupertinoTextField extends StatelessWidget {
  /// Creates a styled Cupertino text field.
  const AppCupertinoTextField({
    super.key,
    this.controller,
    this.placeholder,
    this.validator,
    this.errorText,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.clearButtonMode = OverlayVisibilityMode.editing,
    this.padding = const EdgeInsets.all(12),
  });

  /// Creates a text field for passwords.
  const AppCupertinoTextField.password({
    super.key,
    this.controller,
    this.placeholder = 'Password',
    this.validator,
    this.errorText,
    this.prefix,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(12),
  }) : suffix = null,
       keyboardType = TextInputType.visiblePassword,
       obscureText = true,
       maxLines = 1,
       minLines = null,
       maxLength = null,
       onTap = null,
       autocorrect = false,
       enableSuggestions = false,
       textCapitalization = TextCapitalization.none,
       inputFormatters = null,
       clearButtonMode = OverlayVisibilityMode.never;

  /// Creates a multiline text field.
  const AppCupertinoTextField.multiline({
    super.key,
    this.controller,
    this.placeholder,
    this.validator,
    this.errorText,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.enabled = true,
    this.minLines = 3,
    this.maxLines = 5,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.padding = const EdgeInsets.all(12),
  }) : keyboardType = TextInputType.multiline,
       textInputAction = TextInputAction.newline,
       obscureText = false,
       onTap = null,
       autocorrect = true,
       enableSuggestions = true,
       textCapitalization = TextCapitalization.sentences,
       inputFormatters = null,
       clearButtonMode = OverlayVisibilityMode.never;

  /// The text editing controller.
  final TextEditingController? controller;

  /// Placeholder text shown when field is empty.
  final String? placeholder;

  /// Validation function.
  final String? Function(String?)? validator;

  /// Error text to display (overrides validator).
  final String? errorText;

  /// Widget to show before the text (e.g., icon).
  final Widget? prefix;

  /// Widget to show after the text (e.g., icon button).
  final Widget? suffix;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Focus node for controlling focus.
  final FocusNode? focusNode;

  /// Whether to obscure text (for passwords).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Maximum number of lines.
  final int maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Maximum character length.
  final int? maxLength;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Callback when submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when tapped.
  final VoidCallback? onTap;

  /// Whether to autofocus.
  final bool autofocus;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Whether to show suggestions.
  final bool enableSuggestions;

  /// Text capitalization behavior.
  final TextCapitalization textCapitalization;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// When to show the clear button.
  final OverlayVisibilityMode clearButtonMode;

  /// Padding inside the text field.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final hasError = errorText != null || validator != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          prefix: prefix != null
              ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix)
              : null,
          suffix: suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix,
                )
              : null,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          focusNode: focusNode,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          onTap: onTap,
          autofocus: autofocus,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          clearButtonMode: clearButtonMode,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            border: Border.all(
              color: hasError
                  ? AppColors.error.withOpacity(0.5)
                  : isDark
                  ? CupertinoColors.systemGrey.withOpacity(0.3)
                  : CupertinoColors.systemGrey4,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
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
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

/// A form field version with built-in validation support.
class AppCupertinoTextFormField extends FormField<String> {
  /// Creates a form field version.
  AppCupertinoTextFormField({
    super.key,
    super.onSaved,
    super.validator,
    super.initialValue,
    super.autovalidateMode,
    this.controller,
    String? placeholder,
    Widget? prefix,
    Widget? suffix,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    FocusNode? focusNode,
    bool obscureText = false,
    bool enabled = true,
    int maxLines = 1,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    bool autofocus = false,
    bool autocorrect = true,
    bool enableSuggestions = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    OverlayVisibilityMode clearButtonMode = OverlayVisibilityMode.editing,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) : super(
         builder: (FormFieldState<String> field) {
           final state = field as _AppCupertinoTextFormFieldState;

           return AppCupertinoTextField(
             controller: state._effectiveController,
             placeholder: placeholder,
             errorText: field.errorText,
             prefix: prefix,
             suffix: suffix,
             keyboardType: keyboardType,
             textInputAction: textInputAction,
             focusNode: focusNode,
             obscureText: obscureText,
             enabled: enabled,
             maxLines: maxLines,
             minLines: minLines,
             maxLength: maxLength,
             onChanged: (value) {
               field.didChange(value);
               onChanged?.call(value);
             },
             onSubmitted: onSubmitted,
             onTap: onTap,
             autofocus: autofocus,
             autocorrect: autocorrect,
             enableSuggestions: enableSuggestions,
             textCapitalization: textCapitalization,
             inputFormatters: inputFormatters,
             clearButtonMode: clearButtonMode,
             padding: padding,
           );
         },
       );

  /// Controller for the text field.
  final TextEditingController? controller;

  @override
  FormFieldState<String> createState() => _AppCupertinoTextFormFieldState();
}

class _AppCupertinoTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;

  TextEditingController? get _effectiveController =>
      widget.controller ?? _controller;

  @override
  AppCupertinoTextFormField get widget =>
      super.widget as AppCupertinoTextFormField;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController(text: widget.initialValue);
    } else {
      widget.controller!.text = widget.initialValue ?? '';
    }
    _effectiveController!.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _effectiveController!.removeListener(_handleControllerChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppCupertinoTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      widget.controller?.addListener(_handleControllerChanged);

      if (oldWidget.controller != null && widget.controller == null) {
        _controller = TextEditingController.fromValue(
          oldWidget.controller!.value,
        );
      }

      if (widget.controller != null) {
        setValue(widget.controller!.text);
      } else if (_controller != null) {
        setValue(_controller!.text);
      } else {
        setValue('');
      }
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    if (_effectiveController!.text != value) {
      _effectiveController!.text = value ?? '';
    }
  }

  @override
  void reset() {
    super.reset();
    _effectiveController!.text = widget.initialValue ?? '';
  }

  void _handleControllerChanged() {
    if (_effectiveController!.text != value) {
      didChange(_effectiveController!.text);
    }
  }
}
