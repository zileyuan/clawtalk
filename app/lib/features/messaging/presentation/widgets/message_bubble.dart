import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/message.dart';

/// Message bubble widget with Cupertino-style design
class MessageBubble extends StatelessWidget {
  /// Creates a message bubble
  const MessageBubble({
    super.key,
    required this.message,
    this.showTimestamp = true,
    this.showStatus = true,
    this.onTap,
    this.onLongPress,
  });

  /// The message to display
  final Message message;

  /// Whether to show the timestamp
  final bool showTimestamp;

  /// Whether to show the status indicator
  final bool showStatus;

  /// Callback when the bubble is tapped
  final VoidCallback? onTap;

  /// Callback when the bubble is long pressed
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) _buildAvatar(isDark),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: isSystem
                        ? const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          )
                        : const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                    decoration: _buildBubbleDecoration(
                      context,
                      isUser,
                      isSystem,
                      isDark,
                    ),
                    child: _buildContent(context, isUser, isSystem),
                  ),
                  if (showTimestamp || showStatus) ...[
                    const SizedBox(height: 4),
                    _buildMetadata(context, isUser),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUser) _buildAvatar(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    switch (message.role) {
      case MessageRole.user:
        iconData = CupertinoIcons.person_fill;
        backgroundColor = AppColors.userMessage;
        iconColor = CupertinoColors.white;
      case MessageRole.assistant:
        iconData = CupertinoIcons.gear_solid;
        backgroundColor = isDark
            ? CupertinoColors.systemGrey
            : AppColors.assistantMessage;
        iconColor = isDark ? CupertinoColors.white : CupertinoColors.white;
      case MessageRole.system:
        iconData = CupertinoIcons.info_circle_fill;
        backgroundColor = AppColors.systemMessage;
        iconColor = AppColors.secondaryText;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }

  BoxDecoration _buildBubbleDecoration(
    BuildContext context,
    bool isUser,
    bool isSystem,
    bool isDark,
  ) {
    if (isSystem) {
      return BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : AppColors.systemMessage,
        borderRadius: BorderRadius.circular(12),
      );
    }

    if (isUser) {
      return BoxDecoration(
        color: AppColors.userMessage,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(4),
        ),
      );
    }

    // Assistant bubble
    return BoxDecoration(
      color: isDark
          ? CupertinoColors.systemGrey6.darkColor
          : CupertinoColors.systemGrey6.color,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(20),
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isUser, bool isSystem) {
    if (message.content.isEmpty) {
      return Text(
        'Empty message',
        style: AppTextStyles.bodySmall.copyWith(
          color: isUser
              ? CupertinoColors.white.withOpacity(0.6)
              : AppColors.tertiaryText,
        ),
      );
    }

    // Build content blocks
    final contentWidgets = <Widget>[];

    for (final block in message.content) {
      contentWidgets.add(_buildContentBlock(context, block, isUser, isSystem));
    }

    if (contentWidgets.length == 1) {
      return contentWidgets.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: contentWidgets,
    );
  }

  Widget _buildContentBlock(
    BuildContext context,
    ContentBlock block,
    bool isUser,
    bool isSystem,
  ) {
    final textColor = isUser
        ? CupertinoColors.white
        : (isSystem ? AppColors.secondaryText : AppColors.text);

    switch (block.type) {
      case ContentBlockType.text:
        // Assistant messages should render as markdown
        if (!isUser && !isSystem) {
          return _buildMarkdownBlock(block.content, textColor);
        }
        return _buildTextBlock(block.content, textColor);

      case ContentBlockType.markdown:
        return _buildMarkdownBlock(block.content, textColor);

      case ContentBlockType.code:
        return _buildCodeBlock(block.content, isUser);

      case ContentBlockType.image:
        return _buildImageBlock(block);

      case ContentBlockType.thinking:
        return _buildThinkingBlock(block.content);

      case ContentBlockType.toolUse:
      case ContentBlockType.toolResult:
        return _buildToolBlock(block);
    }
  }

  Widget _buildTextBlock(String text, Color textColor) {
    return SelectableText(
      text,
      style: AppTextStyles.messageUser.copyWith(color: textColor),
    );
  }

  Widget _buildMarkdownBlock(String markdown, Color textColor) {
    return MarkdownBody(
      data: markdown,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: AppTextStyles.messageAssistant.copyWith(color: textColor),
        h1: AppTextStyles.headline1.copyWith(color: textColor),
        h2: AppTextStyles.headline2.copyWith(color: textColor),
        h3: AppTextStyles.headline3.copyWith(color: textColor),
        code: AppTextStyles.code.copyWith(
          color: textColor,
          backgroundColor: CupertinoColors.systemGrey5,
        ),
        codeblockDecoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: AppTextStyles.body.copyWith(color: textColor),
        listBullet: AppTextStyles.body.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildCodeBlock(String code, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? CupertinoColors.black.withOpacity(0.3)
            : CupertinoColors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        code,
        style: AppTextStyles.code.copyWith(
          color: CupertinoColors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildImageBlock(ContentBlock block) {
    // For now, show a placeholder - would load actual image in production
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.photo, color: AppColors.secondaryText, size: 20),
          const SizedBox(width: 8),
          Text(
            'Image',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingBlock(String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.info.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.lightbulb_fill, color: AppColors.info, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              content,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.info,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBlock(ContentBlock block) {
    final isToolUse = block.type == ContentBlockType.toolUse;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isToolUse
            ? AppColors.warning.withOpacity(0.1)
            : AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isToolUse
              ? AppColors.warning.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isToolUse
                ? CupertinoIcons.wrench_fill
                : CupertinoIcons.checkmark_circle_fill,
            color: isToolUse ? AppColors.warning : AppColors.success,
            size: 14,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              block.content,
              style: AppTextStyles.caption.copyWith(
                color: isToolUse ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, bool isUser) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final timeString = DateFormat('h:mm a').format(message.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimestamp)
          Text(
            timeString,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey,
            ),
          ),
        if (showTimestamp && showStatus && isUser) ...[
          const SizedBox(width: 4),
          _buildStatusIndicator(context, isDark),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, bool isDark) {
    IconData iconData;
    Color color;

    switch (message.status) {
      case MessageStatus.pending:
        iconData = CupertinoIcons.clock;
        color = AppColors.warning;
      case MessageStatus.sent:
        iconData = CupertinoIcons.checkmark;
        color = isDark
            ? CupertinoColors.systemGrey.darkColor
            : CupertinoColors.systemGrey;
      case MessageStatus.delivered:
        iconData = CupertinoIcons.checkmark_circle_fill;
        color = AppColors.success;
      case MessageStatus.error:
        iconData = CupertinoIcons.exclamationmark_circle_fill;
        color = AppColors.error;
    }

    return Icon(iconData, size: 10, color: color);
  }
}
