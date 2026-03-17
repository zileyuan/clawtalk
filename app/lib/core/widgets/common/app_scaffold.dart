import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Base scaffold with consistent structure for the app.
///
/// Wraps [CupertinoPageScaffold] with common functionality like
/// navigation bars, safe areas, and keyboard handling.
class AppScaffold extends StatelessWidget {
  /// Creates an app scaffold.
  const AppScaffold({
    super.key,
    this.navigationBar,
    required this.child,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding,
  });

  /// Creates a scaffold with a large title navigation bar.
  const AppScaffold.withLargeTitle({
    super.key,
    required String title,
    Widget? leading,
    Widget? trailing,
    Widget? bottom,
    required this.child,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : navigationBar = CupertinoSliverNavigationBar(
         largeTitle: Text(title),
         leading: leading,
         trailing: trailing,
         bottom: bottom,
         border: null,
       );

  /// Creates a scaffold with a standard navigation bar.
  const AppScaffold.withNavigationBar({
    super.key,
    required String title,
    Widget? leading,
    Widget? trailing,
    bool automaticallyImplyLeading = true,
    Widget? bottom,
    required this.child,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.padding,
  }) : navigationBar = CupertinoNavigationBar(
         middle: Text(title),
         leading: leading,
         trailing: trailing,
         automaticallyImplyLeading: automaticallyImplyLeading,
         bottom: bottom,
         border: null,
       );

  /// The navigation bar to display at the top.
  final ObstructingPreferredSizeWidget? navigationBar;

  /// The main content of the scaffold.
  final Widget child;

  /// Background color of the scaffold.
  final Color? backgroundColor;

  /// Whether to resize when keyboard appears.
  final bool resizeToAvoidBottomInset;

  /// Padding around the child.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return CupertinoPageScaffold(
      navigationBar: navigationBar,
      backgroundColor:
          backgroundColor ??
          (isDark ? CupertinoColors.black : CupertinoColors.systemBackground),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      child: SafeArea(child: content),
    );
  }
}

/// A scrollable scaffold with pull-to-refresh support.
class AppScrollableScaffold extends StatelessWidget {
  /// Creates a scrollable scaffold.
  const AppScrollableScaffold({
    super.key,
    required this.slivers,
    this.onRefresh,
    this.navigationBar,
    this.backgroundColor,
    this.padding,
    this.physics = const BouncingScrollPhysics(),
  });

  /// The slivers to display in the scroll view.
  final List<Widget> slivers;

  /// Callback for pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// The navigation bar.
  final ObstructingPreferredSizeWidget? navigationBar;

  /// Background color.
  final Color? backgroundColor;

  /// Padding for the content.
  final EdgeInsetsGeometry? padding;

  /// Scroll physics.
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    Widget content = CustomScrollView(
      physics: physics,
      slivers: [
        if (padding != null)
          SliverPadding(
            padding: padding!,
            sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
          )
        else
          ...slivers,
      ],
    );

    if (onRefresh != null) {
      content = CustomScrollView(
        physics: physics,
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          if (padding != null)
            SliverPadding(
              padding: padding!,
              sliver: SliverList(delegate: SliverChildListDelegate(slivers)),
            )
          else
            ...slivers,
        ],
      );
    }

    return CupertinoPageScaffold(
      navigationBar: navigationBar,
      backgroundColor:
          backgroundColor ??
          (isDark ? CupertinoColors.black : CupertinoColors.systemBackground),
      child: SafeArea(child: content),
    );
  }
}

/// A scaffold with a tab bar.
class AppTabScaffold extends StatelessWidget {
  /// Creates a tab scaffold.
  const AppTabScaffold({
    super.key,
    required this.tabBar,
    required this.tabBuilder,
    this.currentIndex = 0,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  });

  /// The tab bar.
  final CupertinoTabBar tabBar;

  /// Builder for tab content.
  final Widget Function(BuildContext context, int index) tabBuilder;

  /// Current selected tab index.
  final int currentIndex;

  /// Background color.
  final Color? backgroundColor;

  /// Whether to resize when keyboard appears.
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoTabScaffold(
      tabBar: tabBar,
      backgroundColor:
          backgroundColor ??
          (isDark ? CupertinoColors.black : CupertinoColors.systemBackground),
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      tabBuilder: tabBuilder,
    );
  }
}

/// Extension to create SliverList easily.
extension SliverListExtension on List<Widget> {
  /// Convert list to sliver list.
  SliverList toSliverList() {
    return SliverList(delegate: SliverChildListDelegate(this));
  }
}
