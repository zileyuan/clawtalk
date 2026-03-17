import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_text_styles.dart';

/// Widget for displaying streaming text with typing animation effect
class StreamingText extends StatefulWidget {
  /// Creates a streaming text widget
  const StreamingText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 30),
    this.onComplete,
    this.isStreaming = false,
  });

  /// The full text to display
  final String text;

  /// Text style to apply
  final TextStyle? style;

  /// Speed of typing animation
  final Duration typingSpeed;

  /// Callback when animation completes
  final VoidCallback? onComplete;

  /// Whether streaming is active
  final bool isStreaming;

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);

    if (widget.isStreaming) {
      _startStreamingAnimation();
    } else {
      _displayedText = widget.text;
    }
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      if (widget.isStreaming) {
        _updateStreamingText();
      } else {
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
      }
    }

    if (widget.isStreaming != oldWidget.isStreaming) {
      if (widget.isStreaming) {
        _startStreamingAnimation();
      } else {
        _stopStreamingAnimation();
        _displayedText = widget.text;
        _currentIndex = widget.text.length;
      }
    }
  }

  void _startStreamingAnimation() {
    _typingTimer?.cancel();
    _currentIndex = 0;
    _displayedText = '';

    _typingTimer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  void _updateStreamingText() {
    if (_currentIndex < widget.text.length) {
      // Continue from current position
      _typingTimer?.cancel();
      _startStreamingAnimation();
    }
  }

  void _stopStreamingAnimation() {
    _typingTimer?.cancel();
    _typingTimer = null;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textStyle =
        widget.style ??
        AppTextStyles.messageAssistant.copyWith(
          color: isDark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label,
        );

    return AnimatedBuilder(
      animation: _cursorController,
      builder: (context, child) {
        return RichText(
          text: TextSpan(
            style: textStyle,
            children: [
              TextSpan(text: _displayedText),
              if (widget.isStreaming && _currentIndex < widget.text.length)
                WidgetSpan(
                  child: Opacity(
                    opacity: _cursorController.value,
                    child: Container(
                      width: 2,
                      height: textStyle.fontSize ?? 16,
                      color: textStyle.color,
                      margin: const EdgeInsets.only(left: 1),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Simpler version for displaying streaming content without animation
class StreamingTextDisplay extends StatelessWidget {
  /// Creates a simple streaming text display
  const StreamingTextDisplay({
    super.key,
    required this.text,
    this.style,
    this.showCursor = true,
  });

  /// The text to display
  final String text;

  /// Text style
  final TextStyle? style;

  /// Whether to show the cursor
  final bool showCursor;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final textStyle =
        style ??
        AppTextStyles.messageAssistant.copyWith(
          color: isDark
              ? CupertinoColors.label.darkColor
              : CupertinoColors.label,
        );

    return Text(text, style: textStyle);
  }
}

/// Widget that displays text with a blinking cursor at the end
class StreamingCursor extends StatefulWidget {
  /// Creates a streaming cursor
  const StreamingCursor({
    super.key,
    this.color,
    this.width = 2,
    this.height,
    this.blinkDuration = const Duration(milliseconds: 530),
  });

  /// Cursor color
  final Color? color;

  /// Cursor width
  final double width;

  /// Cursor height (defaults to text height)
  final double? height;

  /// Blink animation duration
  final Duration blinkDuration;

  @override
  State<StreamingCursor> createState() => _StreamingCursorState();
}

class _StreamingCursorState extends State<StreamingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.blinkDuration,
    )..repeat(reverse: true);
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
        (isDark ? CupertinoColors.label.darkColor : CupertinoColors.label);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value,
          child: Container(
            width: widget.width,
            height: widget.height ?? 16,
            color: color,
          ),
        );
      },
    );
  }
}
