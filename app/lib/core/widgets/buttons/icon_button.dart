import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../themes/app_colors.dart';

/// Cupertino-styled icon button with consistent styling.
///
/// Follows iOS Human Interface Guidelines for touch targets
/// and visual feedback.
class AppIconButton extends StatelessWidget {
  /// Creates an icon button.
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44.0,
    this.iconSize = 24.0,
    this.color,
    this.iconColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.tooltip,
    this.isDestructive = false,
    this.isFilled = false,
  });

  /// Creates a small icon button.
  const AppIconButton.small({
    super.key,
    required this.icon,
    required this.onPressed,
    this.iconSize = 20.0,
    this.color,
    this.iconColor,
    this.tooltip,
    this.isDestructive = false,
    this.isFilled = false,
  }) : size = 36.0,
       borderRadius = const BorderRadius.all(Radius.circular(8.0));

  /// Creates a filled icon button.
  const AppIconButton.filled({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44.0,
    this.iconSize = 24.0,
    this.iconColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.tooltip,
    this.isDestructive = false,
  }) : color = AppColors.primary,
       isFilled = true;

  /// The icon widget to display.
  final Widget icon;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// The overall size of the button (width and height).
  final double size;

  /// The size of the icon itself.
  final double iconSize;

  /// Background color of the button. If null, transparent.
  final Color? color;

  /// Color of the icon. If null, uses theme default.
  final Color? iconColor;

  /// Border radius for the button.
  final BorderRadius borderRadius;

  /// Tooltip text for accessibility.
  final String? tooltip;

  /// Whether this is a destructive action (red color).
  final bool isDestructive;

  /// Whether the button has a filled background.
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color? effectiveColor = color;
    Color effectiveIconColor =
        iconColor ??
        (isDestructive
            ? AppColors.error
            : isFilled
            ? CupertinoColors.white
            : AppColors.primary);

    if (isDestructive && isFilled) {
      effectiveColor = AppColors.error;
      effectiveIconColor = CupertinoColors.white;
    }

    final button = CupertinoButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      minSize: size,
      borderRadius: borderRadius,
      color: effectiveColor,
      pressedOpacity: 0.6,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: IconTheme(
          data: IconThemeData(size: iconSize, color: effectiveIconColor),
          child: icon,
        ),
      ),
    );

    if (tooltip != null) {
      return Semantics(
        button: true,
        label: tooltip,
        child: Tooltip(message: tooltip!, child: button),
      );
    }

    return button;
  }
}

/// A group of icon buttons displayed horizontally.
class AppIconButtonGroup extends StatelessWidget {
  /// Creates a group of icon buttons.
  const AppIconButtonGroup({
    super.key,
    required this.children,
    this.spacing = 8.0,
    this.alignment = MainAxisAlignment.start,
  });

  /// The icon buttons to display.
  final List<Widget> children;

  /// Spacing between buttons.
  final double spacing;

  /// Horizontal alignment of the group.
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// An icon button specifically designed for navigation bar usage.
class AppNavIconButton extends StatelessWidget {
  /// Creates a navigation icon button.
  const AppNavIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  /// The icon to display (typically CupertinoIcons.*).
  final IconData icon;

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Tooltip for accessibility.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return AppIconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      size: 36,
      iconSize: 22,
      tooltip: tooltip,
      color: CupertinoColors.tertiarySystemFill,
      iconColor: isDark ? CupertinoColors.white : AppColors.primary,
    );
  }
}
