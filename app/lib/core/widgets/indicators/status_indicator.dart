import 'package:flutter/cupertino.dart';

import '../../../features/connection/domain/entities/connection_status.dart';
import '../../themes/app_colors.dart';

/// Connection status indicator dot.
///
/// Displays a colored dot representing the current connection status.
/// Includes an animated pulsing effect for connecting/disconnecting states.
class ConnectionStatusIndicator extends StatelessWidget {
  /// Creates a status indicator.
  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showPulse = true,
  });

  /// The connection status to display.
  final ConnectionStatus status;

  /// Size of the indicator dot.
  final double size;

  /// Whether to show pulse animation for transitional states.
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final shouldPulse =
        showPulse &&
        (status == ConnectionStatus.connecting ||
            status == ConnectionStatus.disconnecting);

    if (shouldPulse) {
      return _PulsingIndicator(color: color, size: size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          if (status == ConnectionStatus.connected)
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.connecting:
      case ConnectionStatus.disconnecting:
        return AppColors.connecting;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.error:
        return AppColors.errorStatus;
    }
  }
}

/// Animated pulsing indicator for transitional states.
class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: widget.size * _scaleAnimation.value,
                height: widget.size * _scaleAnimation.value,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(_opacityAnimation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          // Center dot
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Generic status indicator for boolean states.
class StatusIndicator extends StatelessWidget {
  /// Creates a status indicator.
  const StatusIndicator({
    super.key,
    required this.isActive,
    this.activeColor = AppColors.success,
    this.inactiveColor = AppColors.disconnected,
    this.size = 10,
  });

  /// Whether the status is active (true) or inactive (false).
  final bool isActive;

  /// Color when active.
  final Color activeColor;

  /// Color when inactive.
  final Color inactiveColor;

  /// Size of the indicator dot.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isActive ? activeColor : inactiveColor,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

/// A badge indicator showing a count.
class BadgeIndicator extends StatelessWidget {
  /// Creates a badge indicator.
  const BadgeIndicator({
    super.key,
    required this.count,
    this.maxCount = 99,
    this.backgroundColor = AppColors.error,
  });

  /// The count to display.
  final int count;

  /// Maximum count to display before showing "+".
  final int maxCount;

  /// Background color of the badge.
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final displayCount = count > maxCount ? '$maxCount+' : '$count';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        displayCount,
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
