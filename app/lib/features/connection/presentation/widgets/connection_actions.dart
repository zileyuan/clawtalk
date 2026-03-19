import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/connection_status.dart';
import '../providers/connection_list_provider.dart';
import '../providers/connection_status_provider.dart';

/// Action buttons for connection management (Connect/Disconnect/Reconnect)
class ConnectionActions extends ConsumerWidget {
  final String connectionId;
  final ConnectionStatus status;

  const ConnectionActions({
    super.key,
    required this.connectionId,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress =
        status == ConnectionStatus.connecting ||
        status == ConnectionStatus.disconnecting;

    if (isInProgress) {
      return const CupertinoActivityIndicator(radius: 10);
    }

    switch (status) {
      case ConnectionStatus.connected:
        return _buildDisconnectButton(context, ref);
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return _buildConnectButton(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildConnectButton(BuildContext context, WidgetRef ref) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () => _handleConnect(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.activeBlue,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.link, size: 14, color: CupertinoColors.white),
            SizedBox(width: 4),
            Text(
              'Connect',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle connection with error handling
  Future<void> _handleConnect(BuildContext context, WidgetRef ref) async {
    // Get the connection config
    final connections = ref.read(connectionListProvider).connections;
    final connection = connections
        .where((c) => c.id == connectionId)
        .firstOrNull;

    if (connection == null) {
      _showErrorDialog(context, 'Connection not found');
      return;
    }

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
    } catch (e) {
      // Check if this is a pairing required error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('pairing required') ||
          errorString.contains('not_paired')) {
        _showPairingRequiredDialog(context);
      } else {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Show dialog when device pairing is required
  void _showPairingRequiredDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Device Pairing Required'),
        content: const Text(
          'A pairing request has been sent to the Gateway.\n\n'
          'Please ask the OpenClaw administrator to approve this device:\n\n'
          '• Run: openclaw devices list\n'
          '• Run: openclaw devices approve --latest\n\n'
          'After approval, try connecting again.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connection Failed'),
        content: Text(
          message.length > 200 ? '${message.substring(0, 200)}...' : message,
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton(BuildContext context, WidgetRef ref) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: () {
        _showDisconnectOptions(context, ref);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark,
              size: 14,
              color: CupertinoColors.systemGreen,
            ),
            SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                color: CupertinoColors.systemGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDisconnectOptions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Connection Actions'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(connectionStatusProvider.notifier)
                  .disconnect(connectionId);
            },
            child: const Text('Disconnect'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(connectionStatusProvider.notifier)
                  .reconnect(connectionId);
            },
            child: const Text('Reconnect'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}

/// Compact action button for use in lists
class ConnectionActionButton extends ConsumerWidget {
  final String connectionId;
  final ConnectionStatus status;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const ConnectionActionButton({
    super.key,
    required this.connectionId,
    required this.status,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInProgress =
        status == ConnectionStatus.connecting ||
        status == ConnectionStatus.disconnecting;

    if (isInProgress) {
      return const CupertinoActivityIndicator(radius: 10);
    }

    if (status == ConnectionStatus.connected) {
      return CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed:
            onDisconnect ??
            () => ref
                .read(connectionStatusProvider.notifier)
                .disconnect(connectionId),
        child: Icon(
          CupertinoIcons.xmark_circle_fill,
          color: CupertinoColors.systemRed.withOpacity(0.8),
          size: 26,
        ),
      );
    }

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onConnect ?? () => _handleConnect(context, ref),
      child: Icon(
        CupertinoIcons.arrow_right_circle_fill,
        color: CupertinoColors.activeBlue,
        size: 26,
      ),
    );
  }

  /// Handle connection with error handling
  Future<void> _handleConnect(BuildContext context, WidgetRef ref) async {
    // Get the connection config
    final connections = ref.read(connectionListProvider).connections;
    final connection = connections
        .where((c) => c.id == connectionId)
        .firstOrNull;

    if (connection == null) {
      _showErrorDialog(context, 'Connection not found');
      return;
    }

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
    } catch (e) {
      // Check if this is a pairing required error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('pairing required') ||
          errorString.contains('not_paired')) {
        _showPairingRequiredDialog(context);
      } else {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Show dialog when device pairing is required
  void _showPairingRequiredDialog(BuildContext context) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Device Pairing Required'),
        content: const Text(
          'A pairing request has been sent to the Gateway.\n\n'
          'Please ask the OpenClaw administrator to approve this device:\n\n'
          '• Run: openclaw devices list\n'
          '• Run: openclaw devices approve --latest\n\n'
          'After approval, try connecting again.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connection Failed'),
        content: Text(
          message.length > 200 ? '${message.substring(0, 200)}...' : message,
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Reconnect button with animation
class ReconnectButton extends ConsumerStatefulWidget {
  final String connectionId;
  final bool isReconnecting;

  const ReconnectButton({
    super.key,
    required this.connectionId,
    this.isReconnecting = false,
  });

  @override
  ConsumerState<ReconnectButton> createState() => _ReconnectButtonState();
}

class _ReconnectButtonState extends ConsumerState<ReconnectButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(_animationController);

    if (widget.isReconnecting) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ReconnectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReconnecting && !oldWidget.isReconnecting) {
      _animationController.repeat();
    } else if (!widget.isReconnecting && oldWidget.isReconnecting) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      onPressed: widget.isReconnecting
          ? null
          : () => ref
                .read(connectionStatusProvider.notifier)
                .reconnect(widget.connectionId),
      child: AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Icon(
              CupertinoIcons.arrow_clockwise,
              color: widget.isReconnecting
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.activeBlue,
              size: 22,
            ),
          );
        },
      ),
    );
  }
}
