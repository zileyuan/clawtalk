import 'package:flutter/cupertino.dart';

import '../../../../core/themes/app_colors.dart';
import '../../domain/entities/agent_capability.dart';

/// Chip widget displaying an agent capability
class AgentCapabilityChip extends StatelessWidget {
  final AgentCapability capability;
  final VoidCallback? onTap;
  final bool isSelected;

  const AgentCapabilityChip({
    super.key,
    required this.capability,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.primary.withAlpha(40),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCapabilityIcon(),
              size: 16,
              color: isSelected ? CupertinoColors.white : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                capability.name,
                style: TextStyle(
                  color: isSelected ? CupertinoColors.white : AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCapabilityIcon() {
    final name = capability.name.toLowerCase();
    if (name.contains('code') || name.contains('program')) {
      return CupertinoIcons.code;
    } else if (name.contains('write') || name.contains('text')) {
      return CupertinoIcons.pencil;
    } else if (name.contains('image') || name.contains('visual')) {
      return CupertinoIcons.photo;
    } else if (name.contains('data') || name.contains('analy')) {
      return CupertinoIcons.chart_bar;
    } else if (name.contains('review')) {
      return CupertinoIcons.eye;
    } else if (name.contains('search')) {
      return CupertinoIcons.search;
    } else if (name.contains('file') || name.contains('document')) {
      return CupertinoIcons.doc;
    } else if (name.contains('generate')) {
      return CupertinoIcons.bolt;
    }
    return CupertinoIcons.star;
  }
}

/// Compact version of the capability chip for use in lists
class AgentCapabilityChipCompact extends StatelessWidget {
  final AgentCapability capability;

  const AgentCapabilityChipCompact({super.key, required this.capability});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemBackground,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        capability.name,
        style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
          fontSize: 12,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }
}
