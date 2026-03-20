import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/connection_config.dart';
import '../../domain/entities/connection_status.dart';
import '../providers/connection_list_provider.dart';
import '../providers/connection_status_provider.dart';
import '../screens/edit_connection_screen.dart';
import 'connection_actions.dart';
import 'connection_status_indicator.dart';

/// Card widget displaying connection information with actions
class ConnectionCard extends ConsumerWidget {
  final ConnectionConfig connection;
  final VoidCallback? onTap;

  const ConnectionCard({super.key, required this.connection, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusInfo = ref.watch(connectionStatusByIdProvider(connection.id));
    final status = statusInfo?.status ?? ConnectionStatus.disconnected;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              ConnectionStatusIndicator(status: status),
              const SizedBox(width: 12),
              // Connection info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.name,
                      style: AppTextStyles.headline3.copyWith(
                        color: CupertinoColors.label,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.globe,
                          size: 14,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${connection.host}:${connection.port}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: CupertinoColors.secondaryLabel,
                            fontFamily: 'SF Mono',
                          ),
                        ),
                        if (connection.useTLS) ...[
                          const SizedBox(width: 8),
                          Icon(
                            CupertinoIcons.lock_fill,
                            size: 12,
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // More options button (... menu)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                onPressed: () => _showEditOptions(context, ref),
                child: Icon(
                  CupertinoIcons.ellipsis,
                  size: 20,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              // Connect/Disconnect button
              ConnectionActions(connectionId: connection.id, status: status),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditOptions(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(connection.name),
        message: Text('${connection.host}:${connection.port}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEdit(context);
            },
            child: const Text('Edit Connection'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _duplicateConnection(ref);
            },
            child: const Text('Duplicate'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
            _confirmDelete(context, ref);
          },
          child: const Text('Delete'),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => EditConnectionScreen(connection: connection),
      ),
    );
  }

  void _duplicateConnection(WidgetRef ref) {
    final notifier = ref.read(connectionListProvider.notifier);
    final duplicated = ConnectionConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${connection.name} (Copy)',
      host: connection.host,
      port: connection.port,
      token: connection.token,
      password: connection.password,
      useTLS: connection.useTLS,
      createdAt: DateTime.now(),
    );
    notifier.addConnection(duplicated);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Connection'),
        content: Text(
          'Are you sure you want to delete "${connection.name}"? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(connectionListProvider.notifier)
                  .deleteConnection(connection.id);
              ref
                  .read(connectionStatusProvider.notifier)
                  .removeStatus(connection.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
