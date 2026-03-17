import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';

/// Animated typing indicator with three bouncing dots
class TypingIndicator extends StatefulWidget {
  /// Creates a typing indicator
  const TypingIndicator({
    super.key,
    this.size = 8.0,
    this.spacing = 4.0,
    this.color,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  /// Size of each dot
  final double size;

  /// Spacing between dots
  final double spacing;

  /// Color of the dots (defaults to secondary text color)
  final Color? color;

  /// Duration of one complete animation cycle
  final Duration animationDuration;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Create staggered animations for each dot
    _animations = [
      _createAnimation(0.0),
      _createAnimation(0.2),
      _createAnimation(0.4),
    ];

    _controller.repeat();
  }

  Animation<double> _createAnimation(double delay) {
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: -8.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -8.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final color =
        widget.color ??
        (isDark
            ? CupertinoColors.systemGrey.darkColor
            : AppColors.secondaryText);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(_animations[0], color),
        SizedBox(width: widget.spacing),
        _buildDot(_animations[1], color),
        SizedBox(width: widget.spacing),
        _buildDot(_animations[2], color),
      ],
    );
  }

  Widget _buildDot(Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

/// Typing indicator with text label
class TypingIndicatorWithLabel extends StatelessWidget {
  /// Creates a typing indicator with label
  const TypingIndicatorWithLabel({
    super.key,
    this.label = 'Typing',
    this.dotSize = 6.0,
    this.textStyle,
  });

  /// Label text to display
  final String label;

  /// Size of the indicator dots
  final double dotSize;

  /// Text style for the label
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final effectiveTextStyle =
        textStyle ??
        TextStyle(
          fontSize: 12,
          color: isDark
              ? CupertinoColors.secondaryLabel.darkColor
              : CupertinoColors.secondaryLabel,
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TypingIndicator(size: dotSize),
        const SizedBox(width: 8),
        Text(label, style: effectiveTextStyle),
      ],
    );
  }
}

/// Compact typing indicator for inline use
class CompactTypingIndicator extends StatelessWidget {
  /// Creates a compact typing indicator
  const CompactTypingIndicator({super.key, this.size = 6.0, this.color});

  /// Size of each dot
  final double size;

  /// Color of the dots
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return TypingIndicator(size: size, spacing: 3.0, color: color);
  }
}
