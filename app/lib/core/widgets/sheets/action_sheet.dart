import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Action sheet item model.
class ActionSheetItem {
  /// Creates an action sheet item.
  const ActionSheetItem({
    required this.label,
    this.icon,
    this.isDestructive = false,
    this.isDefault = false,
    this.enabled = true,
    this.onPressed,
  });

  /// The label text for the action.
  final String label;

  /// Optional icon to display.
  final IconData? icon;

  /// Whether this action is destructive (red color).
  final bool isDestructive;

  /// Whether this is the default action (bold).
  final bool isDefault;

  /// Whether the action is enabled.
  final bool enabled;

  /// Callback when the action is pressed.
  final VoidCallback? onPressed;
}

/// Cupertino action sheet wrapper with consistent styling.
///
/// Provides a simplified API for creating action sheets with
/// actions, cancel button, and title/message support.
class AppActionSheet extends StatelessWidget {
  /// Creates an action sheet.
  const AppActionSheet({
    super.key,
    this.title,
    this.message,
    required this.actions,
    this.cancelLabel = 'Cancel',
    this.onCancel,
  });

  /// Optional title for the action sheet.
  final Widget? title;

  /// Optional message/description.
  final Widget? message;

  /// List of action items.
  final List<ActionSheetItem> actions;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Callback when cancel is pressed.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return CupertinoActionSheet(
      title: title,
      message: message,
      actions: actions.map((item) {
        return CupertinoActionSheetAction(
          onPressed: item.enabled
              ? () {
                  Navigator.of(context).pop();
                  item.onPressed?.call();
                }
              : () {},
          isDefaultAction: item.isDefault,
          isDestructiveAction: item.isDestructive,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(item.label),
            ],
          ),
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () {
          Navigator.of(context).pop();
          onCancel?.call();
        },
        child: Text(cancelLabel),
      ),
    );
  }
}

/// Shows an action sheet.
Future<void> showAppActionSheet({
  required BuildContext context,
  Widget? title,
  Widget? message,
  required List<ActionSheetItem> actions,
  String cancelLabel = 'Cancel',
  VoidCallback? onCancel,
}) {
  return showCupertinoModalPopup(
    context: context,
    builder: (context) => AppActionSheet(
      title: title,
      message: message,
      actions: actions,
      cancelLabel: cancelLabel,
      onCancel: onCancel,
    ),
  );
}

/// Shows a connection options action sheet.
Future<void> showConnectionActions({
  required BuildContext context,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
  VoidCallback? onConnect,
  VoidCallback? onDisconnect,
  bool isConnected = false,
}) {
  final actions = <ActionSheetItem>[
    if (!isConnected && onConnect != null)
      ActionSheetItem(
        label: 'Connect',
        icon: CupertinoIcons.link,
        isDefault: true,
        onPressed: onConnect,
      ),
    if (isConnected && onDisconnect != null)
      ActionSheetItem(
        label: 'Disconnect',
        icon: CupertinoIcons.link_slash,
        onPressed: onDisconnect,
      ),
    ActionSheetItem(
      label: 'Edit',
      icon: CupertinoIcons.pencil,
      onPressed: onEdit,
    ),
    ActionSheetItem(
      label: 'Delete',
      icon: CupertinoIcons.delete,
      isDestructive: true,
      onPressed: onDelete,
    ),
  ];

  return showAppActionSheet(context: context, actions: actions);
}

/// Shows a share action sheet.
Future<void> showShareActionSheet({
  required BuildContext context,
  required VoidCallback onCopy,
  VoidCallback? onShare,
  VoidCallback? onExport,
}) {
  final actions = <ActionSheetItem>[
    ActionSheetItem(
      label: 'Copy',
      icon: CupertinoIcons.doc_on_clipboard,
      onPressed: onCopy,
    ),
    if (onShare != null)
      ActionSheetItem(
        label: 'Share',
        icon: CupertinoIcons.share,
        onPressed: onShare,
      ),
    if (onExport != null)
      ActionSheetItem(
        label: 'Export',
        icon: CupertinoIcons.arrow_up_doc,
        onPressed: onExport,
      ),
  ];

  return showAppActionSheet(
    context: context,
    title: const Text('Share'),
    actions: actions,
  );
}

/// Shows a sort/filter action sheet.
Future<void> showSortActionSheet({
  required BuildContext context,
  required List<String> options,
  required int selectedIndex,
  required ValueChanged<int> onSelect,
  String title = 'Sort By',
}) {
  final actions = options.asMap().entries.map((entry) {
    return ActionSheetItem(
      label: entry.value,
      isDefault: entry.key == selectedIndex,
      onPressed: () => onSelect(entry.key),
    );
  }).toList();

  return showAppActionSheet(
    context: context,
    title: Text(title),
    actions: actions,
  );
}
