import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Styled Cupertino button with consistent theming.
///
/// Wraps [CupertinoButton] with default styling that follows
/// iOS Human Interface Guidelines.
class AppCupertinoButton extends StatelessWidget {
  /// Creates a Cupertino-styled button.
  const AppCupertinoButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.color,
    this.disabledColor,
    this.minSize = 44.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.alignment = Alignment.center,
    this.isDestructive = false,
    this.isSecondary = false,
    this.isLarge = false,
  });

  /// Creates a filled primary button.
  const AppCupertinoButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.minSize = 44.0,
    this.isDestructive = false,
    this.isLarge = false,
  }) : color = AppColors.primary,
       disabledColor = CupertinoColors.quaternarySystemFill,
       borderRadius = const BorderRadius.all(Radius.circular(8.0)),
       alignment = Alignment.center,
       isSecondary = false;

  /// Creates a secondary/outlined style button.
  const AppCupertinoButton.secondary({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding,
    this.minSize = 44.0,
    this.isLarge = false,
  }) : color = null,
       disabledColor = CupertinoColors.systemGrey5,
       borderRadius = const BorderRadius.all(Radius.circular(8.0)),
       alignment = Alignment.center,
       isDestructive = false,
       isSecondary = true;

  /// The callback that is called when the button is tapped.
  final VoidCallback? onPressed;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The amount of space to surround the child inside the bounds of the button.
  final EdgeInsetsGeometry? padding;

  /// The color of the button's background.
  final Color? color;

  /// The color of the button's background when the button is disabled.
  final Color? disabledColor;

  /// The minimum size of the button.
  final double minSize;

  /// The radius of the button's corners when it has a background color.
  final BorderRadius borderRadius;

  /// The alignment of the button's child.
  final AlignmentGeometry alignment;

  /// Whether this is a destructive action (red color).
  final bool isDestructive;

  /// Whether this is a secondary button style.
  final bool isSecondary;

  /// Whether this is a large button (taller).
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    Color? effectiveColor = color;
    if (isDestructive) {
      effectiveColor = AppColors.error;
    } else if (isSecondary) {
      effectiveColor = null; // No fill for secondary
    }

    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: isLarge ? 24.0 : 16.0,
          vertical: isLarge ? 16.0 : 12.0,
        );

    Widget button = CupertinoButton(
      onPressed: onPressed,
      padding: effectivePadding,
      color: effectiveColor,
      disabledColor: disabledColor ?? CupertinoColors.systemGrey4,
      minSize: isLarge ? 50.0 : minSize,
      borderRadius: borderRadius,
      alignment: alignment,
      pressedOpacity: 0.7,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: isSecondary
              ? AppColors.primary
              : (effectiveColor != null ? CupertinoColors.white : null),
          fontSize: isLarge ? 17 : 15,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );

    // Wrap secondary buttons in a border
    if (isSecondary) {
      button = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? CupertinoColors.systemGrey.withOpacity(0.5)
                : CupertinoColors.systemGrey4,
            width: 1,
          ),
          borderRadius: borderRadius,
        ),
        child: button,
      );
    }

    return button;
  }
}

/// A smaller, compact button for inline actions.
class AppCupertinoButtonSmall extends StatelessWidget {
  /// Creates a small Cupertino button.
  const AppCupertinoButtonSmall({
    super.key,
    required this.onPressed,
    required this.child,
    this.isDestructive = false,
  });

  /// The callback when pressed.
  final VoidCallback? onPressed;

  /// The button's child widget.
  final Widget child;

  /// Whether this is a destructive action.
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 28,
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.primary,
        ),
        child: child,
      ),
    );
  }
}
