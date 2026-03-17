import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';

/// About screen with app information
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('About'),
        previousPageTitle: 'Settings',
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 40),

            // App Icon
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_2_fill,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Name
            Center(
              child: Text(
                'ClawTalk',
                style: CupertinoTheme.of(
                  context,
                ).textTheme.navLargeTitleTextStyle,
              ),
            ),

            const SizedBox(height: 4),

            // Version
            Center(
              child: Text(
                'Version 1.0.0 (Build 1)',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // App Description
            CupertinoListSection.insetGrouped(
              header: Text(
                'About'.toUpperCase(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'ClawTalk is an open-source cross-platform client for AI-powered conversations. '
                    'Connect to various AI agents and engage in meaningful dialogue.',
                    style: CupertinoTheme.of(
                      context,
                    ).textTheme.textStyle.copyWith(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Links Section
            CupertinoListSection.insetGrouped(
              header: Text(
                'Links'.toUpperCase(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              children: [
                _buildLinkTile(
                  context,
                  icon: CupertinoIcons.globe,
                  title: 'Website',
                  subtitle: 'clawtalk.app',
                ),
                _buildLinkTile(
                  context,
                  icon: CupertinoIcons.doc_text,
                  title: 'Documentation',
                  subtitle: 'docs.clawtalk.app',
                ),
                _buildLinkTile(
                  context,
                  icon: CupertinoIcons.rocket,
                  title: 'GitHub',
                  subtitle: 'github.com/clawtalk',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Legal Section
            CupertinoListSection.insetGrouped(
              header: Text(
                'Legal'.toUpperCase(),
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              children: [
                CupertinoListTile(
                  title: const Text('Privacy Policy'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                CupertinoListTile(
                  title: const Text('Terms of Service'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                CupertinoListTile(
                  title: const Text('Open Source Licenses'),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Copyright
            Center(
              child: Text(
                '© 2024 ClawTalk. All rights reserved.',
                style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
                  fontSize: 13,
                  color: CupertinoColors.tertiaryLabel,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return CupertinoListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const CupertinoListTileChevron(),
      onTap: () {
        _showComingSoon(context);
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Coming Soon'),
        content: const Text('This feature is not yet available.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
