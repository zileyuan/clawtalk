import 'package:flutter/cupertino.dart';

import '../../domain/entities/connection_status.dart';

/// Animated status indicator showing connection state with a colored dot
class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final double size;
  final bool showLabel;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getStatusColor().withOpacity(0.4),
                blurRadius: _isAnimating() ? 6 : 0,
                spreadRadius: _isAnimating() ? 1 : 0,
              ),
            ],
          ),
          child: _isAnimating() ? _buildPulseAnimation() : null,
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            _getStatusLabel(),
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPulseAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor().withOpacity(0.3 + (value * 0.3)),
          ),
        );
      },
      onEnd: () {
        // Animation loops via rebuild
      },
    );
  }

  bool _isAnimating() {
    return status == ConnectionStatus.connecting ||
        status == ConnectionStatus.disconnecting;
  }

  Color _getStatusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return CupertinoColors.systemGreen;
      case ConnectionStatus.connecting:
        return CupertinoColors.systemYellow;
      case ConnectionStatus.disconnecting:
        return CupertinoColors.systemOrange;
      case ConnectionStatus.error:
        return CupertinoColors.systemRed;
      case ConnectionStatus.disconnected:
        return CupertinoColors.systemGrey;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnecting:
        return 'Disconnecting...';
      case ConnectionStatus.error:
        return 'Error';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
    }
  }
}

/// Compact status dot for use in lists
class ConnectionStatusDot extends StatelessWidget {
  final ConnectionStatus status;
  final double size;

  const ConnectionStatusDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ConnectionStatus.connected:
        return CupertinoColors.systemGreen;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return CupertinoColors.systemYellow;
      case ConnectionStatus.error:
        return CupertinoColors.systemRed;
      case ConnectionStatus.disconnected:
        return CupertinoColors.systemGrey;
    }
  }
}
