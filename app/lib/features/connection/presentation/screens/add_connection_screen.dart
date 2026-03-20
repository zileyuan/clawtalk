import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/connection_config.dart';
import '../providers/connection_form_provider.dart';
import '../providers/connection_list_provider.dart';
import '../providers/connection_status_provider.dart';
import '../widgets/connection_form.dart';

/// Screen for adding a new connection
class AddConnectionScreen extends ConsumerWidget {
  const AddConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(connectionFormProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'New Connection',
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
              // Form section
              const ConnectionFormWithAuth(),

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

              // Help text
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Enter the details of your OpenClaw Gateway server. The host can be an IP address or domain name.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: CupertinoColors.tertiaryLabel,
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
    final config = await ref.read(connectionFormProvider.notifier).submit();

    if (config != null) {
      await ref.read(connectionListProvider.notifier).addConnection(config);

      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _testConnection(BuildContext context, WidgetRef ref) async {
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
      port: int.tryParse(formData.port) ?? 18789,
      token: formData.token,
      password: formData.password,
      useTLS: formData.useTLS,
      createdAt: DateTime.now(),
    );

    try {
      // Try to connect with timeout
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(tempConfig)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Connection timed out after 10 seconds');
            },
          );

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
    } on TimeoutException catch (e) {
      // Disconnect on timeout
      ref.read(connectionStatusProvider.notifier).disconnect(tempConfig.id);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Test Failed'),
            content: Text(e.message ?? 'Connection timed out'),
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
      // Disconnect on error
      ref.read(connectionStatusProvider.notifier).disconnect(tempConfig.id);

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
}
