import 'package:flutter/cupertino.dart';

extension ContextExtensions on BuildContext {
  CupertinoThemeData get theme => CupertinoTheme.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isSmallScreen => screenWidth < 600;
  bool get isMediumScreen => screenWidth >= 600 && screenWidth < 900;
  bool get isLargeScreen => screenWidth >= 900;

  void showSnackBar(String message) {
    showCupertinoSnackBar(content: Text(message));
  }

  void showCupertinoSnackBar({
    required Widget content,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(this);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: padding.bottom + 16,
        left: 16,
        right: 16,
        child: CupertinoPopupSurface(
          child: CupertinoTheme(
            data: theme,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: content,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, entry.remove);
  }
}
