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
  Widget build(BuildContext context) {
    final formState = ref.watch(connectionFormProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Edit Connection',
          style: TextStyle(color: CupertinoColors.label.resolveFrom(context)),
        ),
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
              ConnectionFormWithAuth(initialConnection: widget.connection),

              // Test connection button
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: formState.isValid
                      ? () => _testConnection(context, ref)
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.bolt_fill,
                        size: 16,
                        color: formState.isValid
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Test Connection',
                        style: TextStyle(
                          color: formState.isValid
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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

  Future<void> _testConnection(BuildContext context, WidgetRef ref) async {
    // Get the current form values
    final formData = ref.read(connectionFormProvider);

    // Show testing indicator
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        content: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Testing connection...'),
            ],
          ),
        ),
      ),
    );

    // Create a temporary connection config from form data
    final tempConfig = ConnectionConfig(
      id: 'test-${DateTime.now().millisecondsSinceEpoch}',
      name: formData.name,
      host: formData.host,
      port: int.tryParse(formData.port) ?? widget.connection.port,
      token: formData.token,
      password: formData.password,
      useTLS: formData.useTLS,
      createdAt: DateTime.now(),
    );

    try {
      // Try to connect
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(tempConfig);

      // Disconnect after test
      ref.read(connectionStatusProvider.notifier).disconnect(tempConfig.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Test'),
            content: const Text('Successfully connected to the server!'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Test Failed'),
            content: Text(
              e.toString().length > 200
                  ? '${e.toString().substring(0, 200)}...'
                  : e.toString(),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
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
