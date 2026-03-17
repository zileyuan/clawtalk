import 'package:flutter/cupertino.dart';

/// Reusable settings tile widget
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool? value;
  final ValueChanged<bool>? onChanged;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  }) : value = null,
       onChanged = null;

  /// Constructor for switch tile
  const SettingsTile.switchTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  }) : trailing = null,
       onTap = null,
       titleColor = null;

  bool get isSwitchTile => value != null;

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
      title: Text(title, style: TextStyle(color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: isSwitchTile
          ? CupertinoSwitch(value: value!, onChanged: onChanged)
          : trailing ?? const CupertinoListTileChevron(),
      onTap: isSwitchTile ? () => onChanged?.call(!value!) : onTap,
    );
  }
}

/// Simple settings tile without icon
class SettingsTileSimple extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTileSimple({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const CupertinoListTileChevron(),
      onTap: onTap,
    );
  }
}

/// Settings section header
class SettingsSectionHeader extends StatelessWidget {
  final String title;

  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: 8.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}

/// Settings section footer
class SettingsSectionFooter extends StatelessWidget {
  final String text;

  const SettingsSectionFooter({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 16.0,
      ),
      child: Text(
        text,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 13,
          color: CupertinoColors.tertiaryLabel,
        ),
      ),
    );
  }
}
