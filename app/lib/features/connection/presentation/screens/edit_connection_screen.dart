import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/connection_config.dart';
import '../providers/connection_form_provider.dart';
import '../providers/connection_list_provider.dart';
import '../providers/connection_status_provider.dart';
import '../widgets/connection_form.dart';

/// Screen for editing an existing connection
class EditConnectionScreen extends ConsumerStatefulWidget {
  final ConnectionConfig connection;

  const EditConnectionScreen({super.key, required this.connection});

  @override
  ConsumerState<EditConnectionScreen> createState() =>
      _EditConnectionScreenState();
}

class _EditConnectionScreenState extends ConsumerState<EditConnectionScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize form with existing connection data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(connectionFormProvider.notifier)
          .initializeWithConnection(widget.connection);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(connectionFormProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Edit Connection'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _onCancel(context, ref),
          child: const Text('Cancel'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: formState.isValid && !formState.isSubmitting
              ? () => _onSave(context, ref)
              : null,
          child: formState.isSubmitting
              ? const CupertinoActivityIndicator(radius: 10)
              : const Text('Save'),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              // Connection ID display
              CupertinoFormSection.insetGrouped(
                header: const Text('CONNECTION ID'),
                children: [
                  CupertinoFormRow(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Text(
                        widget.connection.id,
                        style: AppTextStyles.code.copyWith(
                          color: CupertinoColors.secondaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Form section
              const ConnectionFormWithAuth(),

              // Delete button
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoButton(
                  color: CupertinoColors.destructiveRed.withOpacity(0.1),
                  onPressed: () => _confirmDelete(context, ref),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        CupertinoIcons.trash,
                        size: 16,
                        color: CupertinoColors.destructiveRed,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delete Connection',
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCancel(BuildContext context, WidgetRef ref) {
    ref.read(connectionFormProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    final config = await ref
        .read(connectionFormProvider.notifier)
        .submitEdit(widget.connection.id);

    if (config != null) {
      await ref.read(connectionListProvider.notifier).updateConnection(config);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Delete Connection'),
        content: Text(
          'Are you sure you want to delete "${widget.connection.name}"? This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              // Disconnect if connected
              ref
                  .read(connectionStatusProvider.notifier)
                  .disconnect(widget.connection.id);

              // Delete from list
              await ref
                  .read(connectionListProvider.notifier)
                  .deleteConnection(widget.connection.id);

              // Remove status tracking
              ref
                  .read(connectionStatusProvider.notifier)
                  .removeStatus(widget.connection.id);

              if (context.mounted) {
                Navigator.of(context).pop(); // Close edit screen
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
