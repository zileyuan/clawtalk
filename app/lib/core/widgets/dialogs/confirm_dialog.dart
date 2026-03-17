import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Cupertino-styled confirmation dialog.
///
/// Provides a standard confirm/cancel dialog with customizable
/// actions and styling following iOS HIG.
class AppConfirmDialog extends StatelessWidget {
  /// Creates a confirmation dialog.
  const AppConfirmDialog({
    super.key,
    this.title,
    this.content,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.isDestructive = false,
    this.onConfirm,
    this.onCancel,
  });

  /// Creates a destructive confirmation dialog (e.g., delete).
  const AppConfirmDialog.destructive({
    super.key,
    this.title,
    this.content,
    this.confirmText = 'Delete',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
  }) : isDestructive = true;

  /// The title of the dialog.
  final Widget? title;

  /// The content of the dialog.
  final Widget? content;

  /// Text for the confirm button.
  final String confirmText;

  /// Text for the cancel button.
  final String cancelText;

  /// Whether the confirm action is destructive.
  final bool isDestructive;

  /// Callback when confirmed.
  final VoidCallback? onConfirm;

  /// Callback when cancelled.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content != null
          ? Padding(padding: const EdgeInsets.only(top: 8.0), child: content)
          : null,
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(false);
            onCancel?.call();
          },
          isDefaultAction: !isDestructive,
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm?.call();
          },
          isDestructiveAction: isDestructive,
          isDefaultAction: isDestructive,
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// Shows a confirmation dialog and returns true if confirmed, false if cancelled.
Future<bool> showConfirmDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
  bool barrierDismissible = true,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppConfirmDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    ),
  );

  return result ?? false;
}

/// Shows a destructive confirmation dialog.
Future<bool> showDestructiveDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
  bool barrierDismissible = true,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AppConfirmDialog.destructive(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );

  return result ?? false;
}

/// Shows a delete confirmation dialog.
Future<bool> showDeleteConfirmDialog({
  required BuildContext context,
  required String itemName,
  String confirmText = 'Delete',
  String cancelText = 'Cancel',
}) {
  return showDestructiveDialog(
    context: context,
    title: const Text('Delete?'),
    content: Text('Are you sure you want to delete "$itemName"?'),
    confirmText: confirmText,
    cancelText: cancelText,
    barrierDismissible: true,
  );
}

/// Shows a discard changes confirmation dialog.
Future<bool> showDiscardChangesDialog({
  required BuildContext context,
  String confirmText = 'Discard',
  String cancelText = 'Cancel',
}) {
  return showDestructiveDialog(
    context: context,
    title: const Text('Discard Changes?'),
    content: const Text(
      'You have unsaved changes. Are you sure you want to discard them?',
    ),
    confirmText: confirmText,
    cancelText: cancelText,
    barrierDismissible: true,
  );
}

/// Shows a logout confirmation dialog.
Future<bool> showLogoutConfirmDialog({
  required BuildContext context,
  String confirmText = 'Log Out',
  String cancelText = 'Cancel',
}) {
  return showDestructiveDialog(
    context: context,
    title: const Text('Log Out?'),
    content: const Text('Are you sure you want to log out?'),
    confirmText: confirmText,
    cancelText: cancelText,
    barrierDismissible: true,
  );
}
