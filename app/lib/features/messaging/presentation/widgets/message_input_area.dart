import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../providers/chat_provider.dart';

/// Input area with text input, image picker, voice recorder, and send button
class MessageInputArea extends ConsumerStatefulWidget {
  /// Creates a message input area
  const MessageInputArea({
    super.key,
    this.onSend,
    this.onImagePick,
    this.onVoiceRecord,
    this.enabled = true,
    this.hintText = 'Message',
  });

  /// Callback when a message is sent
  final void Function(String text)? onSend;

  /// Callback when image picker is tapped
  final VoidCallback? onImagePick;

  /// Callback when voice recorder is tapped
  final VoidCallback? onVoiceRecord;

  /// Whether the input is enabled
  final bool enabled;

  /// Hint text for the input field
  final String hintText;

  @override
  ConsumerState<MessageInputArea> createState() => _MessageInputAreaState();
}

class _MessageInputAreaState extends ConsumerState<MessageInputArea> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = _textController.text.trim().isNotEmpty;
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Clear the input immediately for better UX
    _textController.clear();

    // Call the onSend callback
    widget.onSend?.call(text);

    // Also update the chat provider
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  void _handleImagePick() {
    widget.onImagePick?.call();
  }

  void _handleVoiceRecord() {
    widget.onVoiceRecord?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final isSending = ref.watch(isSendingProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemBackground.darkColor
            : CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: isDark
                ? CupertinoColors.systemGrey6.darkColor
                : CupertinoColors.systemGrey6,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image picker button
            _buildActionButton(
              icon: CupertinoIcons.camera_fill,
              onPressed: widget.enabled ? _handleImagePick : null,
              isDark: isDark,
            ),
            const SizedBox(width: 8),

            // Voice recorder button
            _buildActionButton(
              icon: CupertinoIcons.mic_fill,
              onPressed: widget.enabled ? _handleVoiceRecord : null,
              isDark: isDark,
            ),
            const SizedBox(width: 8),

            // Text input field
            Expanded(child: _buildTextField(isDark)),
            const SizedBox(width: 8),

            // Send button
            _buildSendButton(isSending, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: const EdgeInsets.all(8),
      minSize: 36,
      onPressed: onPressed,
      child: Icon(
        icon,
        size: 24,
        color: onPressed != null
            ? AppColors.primary
            : (isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey),
      ),
    );
  }

  Widget _buildTextField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: CupertinoTextField(
        controller: _textController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        placeholder: widget.hintText,
        placeholderStyle: AppTextStyles.body.copyWith(
          color: isDark
              ? CupertinoColors.placeholderText.darkColor
              : CupertinoColors.placeholderText,
        ),
        style: AppTextStyles.body.copyWith(
          color:
              isDark ? CupertinoColors.label.darkColor : CupertinoColors.label,
        ),
        decoration: null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minLines: 1,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        onSubmitted: (_) => _handleSend(),
        prefix: null,
        suffix: null,
      ),
    );
  }

  Widget _buildSendButton(bool isSending, bool isDark) {
    final canSend = _isComposing && widget.enabled && !isSending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 36,
        onPressed: canSend ? _handleSend : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: canSend ? AppColors.userMessage : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: isSending
              ? const CupertinoActivityIndicator(radius: 10)
              : Icon(
                  CupertinoIcons.arrow_up,
                  size: 20,
                  color: canSend
                      ? CupertinoColors.white
                      : (isDark
                          ? CupertinoColors.systemGrey.darkColor
                          : CupertinoColors.systemGrey),
                ),
        ),
      ),
    );
  }
}

/// Compact input area for embedded use
class CompactMessageInput extends StatelessWidget {
  /// Creates a compact message input
  const CompactMessageInput({
    super.key,
    this.onSend,
    this.hintText = 'Message',
  });

  /// Callback when a message is sent
  final void Function(String text)? onSend;

  /// Hint text for the input field
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? CupertinoColors.systemGrey6.darkColor
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.body.copyWith(
                  color: isDark
                      ? CupertinoColors.placeholderText.darkColor
                      : CupertinoColors.placeholderText,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: AppTextStyles.body,
              onSubmitted: onSend,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: () {
              // Handle send
            },
            child: Icon(
              CupertinoIcons.arrow_up_circle_fill,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
