import 'package:flutter/cupertino.dart';

import '../../themes/app_colors.dart';

/// Cupertino-style loading indicator with consistent sizing.
///
/// Wraps [CupertinoActivityIndicator] with app-specific defaults.
class AppLoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const AppLoadingIndicator({
    super.key,
    this.size = LoadingIndicatorSize.medium,
    this.color,
    this.animating = true,
  });

  /// Creates a small loading indicator.
  const AppLoadingIndicator.small({
    super.key,
    this.color,
    this.animating = true,
  }) : size = LoadingIndicatorSize.small;

  /// Creates a medium loading indicator.
  const AppLoadingIndicator.medium({
    super.key,
    this.color,
    this.animating = true,
  }) : size = LoadingIndicatorSize.medium;

  /// Creates a large loading indicator.
  const AppLoadingIndicator.large({
    super.key,
    this.color,
    this.animating = true,
  }) : size = LoadingIndicatorSize.large;

  /// Creates an adaptive loading indicator that can be used as a overlay.
  const AppLoadingIndicator.overlay({
    super.key,
    this.color,
    this.animating = true,
  }) : size = LoadingIndicatorSize.large;

  /// The size of the indicator.
  final LoadingIndicatorSize size;

  /// The color of the indicator. If null, uses theme default.
  final Color? color;

  /// Whether the indicator is animating.
  final bool animating;

  double get _radius {
    switch (size) {
      case LoadingIndicatorSize.small:
        return 10;
      case LoadingIndicatorSize.medium:
        return 14;
      case LoadingIndicatorSize.large:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoActivityIndicator(
      radius: _radius,
      color: color,
      animating: animating,
    );
  }
}

/// Loading indicator sizes.
enum LoadingIndicatorSize {
  /// Small size (10px radius).
  small,

  /// Medium size (14px radius).
  medium,

  /// Large size (20px radius).
  large,
}

/// Full-screen loading overlay with a backdrop.
class AppLoadingOverlay extends StatelessWidget {
  /// Creates a loading overlay.
  const AppLoadingOverlay({
    super.key,
    this.message,
    this.dismissible = false,
    this.onDismiss,
  });

  /// Optional message to display below the indicator.
  final String? message;

  /// Whether the overlay can be dismissed by tapping.
  final bool dismissible;

  /// Callback when overlay is dismissed.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: dismissible ? onDismiss : null,
      child: Container(
        color: isDark
            ? CupertinoColors.black.withOpacity(0.7)
            : CupertinoColors.white.withOpacity(0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? CupertinoColors.systemGrey6.darkColor
                  : CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator.large(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A skeleton loading placeholder for content that is loading.
class AppSkeletonLoader extends StatelessWidget {
  /// Creates a skeleton loader.
  const AppSkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  /// Width of the skeleton.
  final double width;

  /// Height of the skeleton.
  final double height;

  /// Border radius of the skeleton.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey5.darkColor
            : CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A shimmer effect wrapper for loading states.
class AppShimmer extends StatefulWidget {
  /// Creates a shimmer effect.
  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  /// The widget to apply shimmer to.
  final Widget child;

  /// Animation duration.
  final Duration duration;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: -1, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                CupertinoColors.white,
                CupertinoColors.white,
                CupertinoColors.systemGrey3,
                CupertinoColors.white,
              ],
              stops: const [0.0, 0.4, 0.5, 1.0],
              transform: _SlideGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform(this.percent);

  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * percent, 0, 0);
  }
}
