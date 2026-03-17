import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Cupertino-styled alert dialog with consistent theming.
///
/// Wraps [CupertinoAlertDialog] with app-specific styling and
/// convenience constructors for common use cases.
class AppAlertDialog extends StatelessWidget {
  /// Creates an alert dialog.
  const AppAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.scrollable = false,
  });

  /// Creates an alert dialog with a single OK button.
  const AppAlertDialog.info({
    super.key,
    this.title,
    this.content,
    VoidCallback? onOk,
    String okText = 'OK',
    this.scrollable = false,
  }) : actions = [
         CupertinoDialogAction(
           onPressed: onOk ?? () {},
           isDefaultAction: true,
           child: Text(okText),
         ),
       ];

  /// Creates an error alert dialog.
  const AppAlertDialog.error({
    super.key,
    this.title = 'Error',
    required String message,
    VoidCallback? onDismiss,
    String dismissText = 'OK',
    this.scrollable = false,
  }) : content = Text(message),
       actions = [
         CupertinoDialogAction(
           onPressed: onDismiss ?? () {},
           isDestructiveAction: true,
           child: Text(dismissText),
         ),
       ];

  /// Creates a success alert dialog.
  const AppAlertDialog.success({
    super.key,
    this.title = 'Success',
    required String message,
    VoidCallback? onDismiss,
    String dismissText = 'OK',
    this.scrollable = false,
  }) : content = Text(message),
       actions = [
         CupertinoDialogAction(
           onPressed: onDismiss ?? () {},
           isDefaultAction: true,
           child: Text(dismissText),
         ),
       ];

  /// The title of the dialog.
  final Widget? title;

  /// The content of the dialog.
  final Widget? content;

  /// The actions to display.
  final List<CupertinoDialogAction> actions;

  /// Whether the content is scrollable.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: content != null
          ? Padding(padding: const EdgeInsets.only(top: 8.0), child: content)
          : null,
      actions: actions,
    );
  }
}

/// Shows an alert dialog.
Future<void> showAppAlertDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  List<CupertinoDialogAction> actions = const [],
  bool barrierDismissible = true,
}) {
  return showCupertinoDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) =>
        AppAlertDialog(title: title, content: content, actions: actions),
  );
}

/// Shows an info dialog with a single OK button.
Future<void> showInfoDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  String okText = 'OK',
  VoidCallback? onOk,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => AppAlertDialog.info(
      title: title,
      content: content,
      okText: okText,
      onOk: onOk ?? () => Navigator.of(context).pop(),
    ),
  );
}

/// Shows an error dialog.
Future<void> showErrorDialog({
  required BuildContext context,
  String title = 'Error',
  required String message,
  String dismissText = 'OK',
  VoidCallback? onDismiss,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => AppAlertDialog.error(
      title: title,
      message: message,
      dismissText: dismissText,
      onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
    ),
  );
}

/// Shows a success dialog.
Future<void> showSuccessDialog({
  required BuildContext context,
  String title = 'Success',
  required String message,
  String dismissText = 'OK',
  VoidCallback? onDismiss,
}) {
  return showCupertinoDialog(
    context: context,
    builder: (context) => AppAlertDialog.success(
      title: title,
      message: message,
      dismissText: dismissText,
      onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
    ),
  );
}

/// Shows a loading dialog with optional message.
Future<void> showLoadingDialog({
  required BuildContext context,
  String? message,
  bool barrierDismissible = false,
}) {
  return showCupertinoDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => PopScope(
      canPop: barrierDismissible,
      child: CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(radius: 14),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
