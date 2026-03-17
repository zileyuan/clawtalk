import 'package:flutter/cupertino.dart';

class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = CupertinoColors.systemBlue;
  static const Color secondary = CupertinoColors.systemGrey;
  static const Color accent = CupertinoColors.activeBlue;

  // Background colors
  static const Color background = CupertinoColors.systemBackground;
  static const Color secondaryBackground =
      CupertinoColors.secondarySystemBackground;
  static const Color tertiaryBackground =
      CupertinoColors.tertiarySystemBackground;

  // Text colors
  static const Color text = CupertinoColors.label;
  static const Color secondaryText = CupertinoColors.secondaryLabel;
  static const Color tertiaryText = CupertinoColors.tertiaryLabel;

  // Status colors
  static const Color success = CupertinoColors.systemGreen;
  static const Color warning = CupertinoColors.systemYellow;
  static const Color error = CupertinoColors.systemRed;
  static const Color info = CupertinoColors.systemBlue;

  // Connection status colors
  static const Color connected = CupertinoColors.systemGreen;
  static const Color connecting = CupertinoColors.systemYellow;
  static const Color disconnected = CupertinoColors.systemGrey;
  static const Color errorStatus = CupertinoColors.systemRed;

  // Message colors
  static const Color userMessage = CupertinoColors.activeBlue;
  static const Color assistantMessage = CupertinoColors.systemGrey;
  static const Color systemMessage = CupertinoColors.tertiarySystemBackground;
}
