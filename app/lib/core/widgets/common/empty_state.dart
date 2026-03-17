import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';
import '../buttons/cupertino_button.dart';

/// Empty state placeholder widget.
///
/// Displays when there is no content to show, with an icon,
/// title, optional message, and optional action button.
class AppEmptyState extends StatelessWidget {
  /// Creates an empty state widget.
  const AppEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  });

  /// Creates an empty state with a search icon.
  const AppEmptyState.search({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  }) : icon = CupertinoIcons.search;

  /// Creates an empty state with a connections icon.
  const AppEmptyState.connections({
    super.key,
    this.title = 'No Connections',
    this.message = 'Add a connection to get started',
    this.actionLabel = 'Add Connection',
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  }) : icon = CupertinoIcons.link;

  /// Creates an empty state with a messages icon.
  const AppEmptyState.messages({
    super.key,
    this.title = 'No Messages',
    this.message = 'Start a conversation',
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.iconColor,
  }) : icon = CupertinoIcons.bubble_left;

  /// Creates an empty state with an error icon.
  const AppEmptyState.error({
    super.key,
    this.title = 'Something Went Wrong',
    this.message,
    this.actionLabel = 'Try Again',
    this.onAction,
    this.iconSize = 64,
  }) : icon = CupertinoIcons.exclamationmark_triangle,
       iconColor = AppColors.error;

  /// The icon to display (CupertinoIcons.*).
  final IconData? icon;

  /// The title text.
  final String? title;

  /// Optional message text.
  final String? message;

  /// Optional action button label.
  final String? actionLabel;

  /// Callback for action button.
  final VoidCallback? onAction;

  /// Size of the icon.
  final double iconSize;

  /// Color of the icon.
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final defaultIconColor = isDark
        ? CupertinoColors.systemGrey.darkColor
        : CupertinoColors.systemGrey;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(iconSize / 2),
                ),
                child: Icon(
                  icon,
                  size: iconSize * 0.5,
                  color: iconColor ?? AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark
                      ? CupertinoColors.systemGrey.darkColor
                      : CupertinoColors.systemGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              AppCupertinoButton.filled(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget that shows different states: loading, empty, error, or content.
class AppStateWidget extends StatelessWidget {
  /// Creates a state widget.
  const AppStateWidget({
    super.key,
    required this.state,
    required this.child,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
  });

  /// The current state.
  final AppContentState state;

  /// The content widget to display when state is content.
  final Widget child;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Custom empty widget.
  final Widget? emptyWidget;

  /// Custom error widget.
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppContentState.loading:
        return loadingWidget ??
            const Center(child: CupertinoActivityIndicator(radius: 14));
      case AppContentState.empty:
        return emptyWidget ??
            const AppEmptyState(
              icon: CupertinoIcons.doc_text,
              title: 'No Content',
            );
      case AppContentState.error:
        return errorWidget ??
            AppEmptyState.error(message: 'An error occurred', onAction: () {});
      case AppContentState.content:
        return child;
    }
  }
}

/// Possible content states.
enum AppContentState {
  /// Loading content.
  loading,

  /// Empty content.
  empty,

  /// Error loading content.
  error,

  /// Content available.
  content,
}
