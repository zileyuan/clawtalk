import 'package:flutter/cupertino.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static CupertinoThemeData get cupertinoTheme => const CupertinoThemeData(
    primaryColor: AppColors.primary,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.secondaryBackground,
    textTheme: CupertinoTextThemeData(
      textStyle: AppTextStyles.body,
      navLargeTitleTextStyle: AppTextStyles.headline1,
      navTitleTextStyle: AppTextStyles.headline3,
    ),
  );

  static CupertinoThemeData get darkTheme => const CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    primaryContrastingColor: CupertinoColors.black,
    scaffoldBackgroundColor: CupertinoColors.black,
    barBackgroundColor: CupertinoColors.black,
    textTheme: CupertinoTextThemeData(
      textStyle: AppTextStyles.body,
      navLargeTitleTextStyle: AppTextStyles.headline1,
      navTitleTextStyle: AppTextStyles.headline3,
    ),
  );
}
