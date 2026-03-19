import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Custom Cupertino navigation bar with consistent styling.
///
/// Provides convenience constructors for common navigation bar
/// configurations following iOS HIG.
class AppNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  /// Creates a custom navigation bar.
  const AppNavigationBar({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.previousPageTitle,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyMiddle = true,
    this.border,
    this.backgroundColor,
    this.padding,
    this.brightness,
    this.transitionBetweenRoutes = true,
  });

  /// Creates a navigation bar with a title.
  AppNavigationBar.title({
    super.key,
    required String title,
    this.leading,
    this.trailing,
    this.previousPageTitle,
    this.automaticallyImplyLeading = true,
    this.border,
    this.backgroundColor,
    this.padding,
    this.brightness,
    this.transitionBetweenRoutes = true,
  }) : middle = Text(title),
       automaticallyImplyMiddle = false;

  /// Creates a transparent navigation bar.
  const AppNavigationBar.transparent({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.previousPageTitle,
    this.automaticallyImplyLeading = true,
    this.automaticallyImplyMiddle = true,
    this.padding,
    this.brightness,
    this.transitionBetweenRoutes = true,
  }) : border = null,
       backgroundColor = CupertinoColors.transparent;

  /// Creates a navigation bar for modal presentation.
  AppNavigationBar.modal({
    super.key,
    String? title,
    Widget? leading,
    required Widget doneButton,
    this.backgroundColor,
  }) : leading = leading ?? const CupertinoNavigationBarBackButton(),
       middle = title != null ? Text(title) : null,
       trailing = doneButton,
       previousPageTitle = null,
       automaticallyImplyLeading = false,
       automaticallyImplyMiddle = true,
       border = const Border(
         bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
       ),
       padding = const EdgeInsetsDirectional.only(end: 8),
       brightness = null,
       transitionBetweenRoutes = false;

  /// Widget to place at the start of the navigation bar.
  final Widget? leading;

  /// Widget to place in the middle of the navigation bar.
  final Widget? middle;

  /// Widget to place at the end of the navigation bar.
  final Widget? trailing;

  /// The title of the previous page for the back button.
  final String? previousPageTitle;

  /// Whether to automatically show a back button.
  final bool automaticallyImplyLeading;

  /// Whether to automatically determine the middle widget.
  final bool automaticallyImplyMiddle;

  /// Border below the navigation bar.
  final Border? border;

  /// Background color.
  final Color? backgroundColor;

  /// Horizontal padding.
  final EdgeInsetsDirectional? padding;

  /// Brightness override.
  final Brightness? brightness;

  /// Whether to transition between routes.
  final bool transitionBetweenRoutes;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kMinInteractiveDimensionCupertino);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      leading: leading,
      middle: middle,
      trailing: trailing,
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      automaticallyImplyMiddle: automaticallyImplyMiddle,
      border:
          border ??
          const Border(
            bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
          ),
      backgroundColor:
          backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
      padding: padding,
      brightness: brightness,
      transitionBetweenRoutes: transitionBetweenRoutes,
    );
  }
}

/// Large title navigation bar.
class AppLargeTitleNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  /// Creates a large title navigation bar.
  const AppLargeTitleNavigationBar({
    super.key,
    required this.largeTitle,
    this.leading,
    this.trailing,
    this.previousPageTitle,
    this.automaticallyImplyLeading = true,
    this.border,
    this.backgroundColor,
    this.brightness,
    this.transitionBetweenRoutes = true,
    this.alwaysShowMiddle = false,
    this.bottom,
  });

  /// The large title widget (typically Text).
  final Widget largeTitle;

  /// Widget to place at the start.
  final Widget? leading;

  /// Widget to place at the end.
  final Widget? trailing;

  /// Previous page title for back button.
  final String? previousPageTitle;

  /// Whether to automatically show back button.
  final bool automaticallyImplyLeading;

  /// Border below the navigation bar.
  final Border? border;

  /// Background color.
  final Color? backgroundColor;

  /// Brightness override.
  final Brightness? brightness;

  /// Whether to transition between routes.
  final bool transitionBetweenRoutes;

  /// Whether to always show the middle widget.
  final bool alwaysShowMiddle;

  /// Widget to show at the bottom.
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize {
    return const Size.fromHeight(
      kMinInteractiveDimensionCupertino + 52, // Large title area
    );
  }

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverNavigationBar(
      largeTitle: largeTitle,
      leading: leading,
      trailing: trailing,
      previousPageTitle: previousPageTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      border: border,
      backgroundColor: backgroundColor,
      brightness: brightness,
      transitionBetweenRoutes: transitionBetweenRoutes,
      alwaysShowMiddle: alwaysShowMiddle,
      bottom: bottom,
    );
  }
}

/// A done button for modal navigation bars.
class DoneButton extends StatelessWidget {
  /// Creates a done button.
  const DoneButton({
    super.key,
    this.onPressed,
    this.label = 'Done',
    this.enabled = true,
  });

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Button label.
  final String label;

  /// Whether the button is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: enabled ? onPressed : null,
      child: Text(
        label,
        style: TextStyle(
          color: enabled ? AppColors.primary : CupertinoColors.systemGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A cancel button for modal navigation bars.
class CancelButton extends StatelessWidget {
  /// Creates a cancel button.
  const CancelButton({super.key, this.onPressed, this.label = 'Cancel'});

  /// Callback when pressed.
  final VoidCallback? onPressed;

  /// Button label.
  final String label;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: AppColors.primary)),
    );
  }
}
