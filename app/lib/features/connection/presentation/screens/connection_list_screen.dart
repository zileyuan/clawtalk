import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_text_styles.dart';
import '../../domain/entities/connection_config.dart';
import '../../../messaging/presentation/screens/session_list_screen.dart';
import '../providers/connection_list_provider.dart';
import '../providers/connection_status_provider.dart';
import '../widgets/connection_card.dart';
import 'add_connection_screen.dart';

/// Main screen showing all saved connections
class ConnectionListScreen extends ConsumerStatefulWidget {
  const ConnectionListScreen({super.key});

  @override
  ConsumerState<ConnectionListScreen> createState() =>
      _ConnectionListScreenState();
}

class _ConnectionListScreenState extends ConsumerState<ConnectionListScreen> {
  @override
  void initState() {
    super.initState();
    // Load connections when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(connectionListProvider.notifier).loadConnections();
      ref.read(connectionStatusProvider.notifier).startMonitoring();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(connectionListProvider.notifier).loadConnections();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionListProvider);
    final hasConnections = ref.watch(hasConnectionsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Connections'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _navigateToAdd(context),
          child: const Icon(CupertinoIcons.add),
        ),
      ),
      child: SafeArea(
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.connections.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (state.error != null && state.connections.isEmpty) {
              return _buildErrorState(state.error!);
            }

            if (!hasConnections) {
              return _buildEmptyState();
            }

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _onRefresh),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final connection = state.connections[index];
                      return ConnectionCard(
                        connection: connection,
                        onTap: () => _onConnectionTap(connection.id),
                      );
                    }, childCount: state.connections.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.link,
            size: 64,
            color: CupertinoColors.systemGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Connections',
            style: AppTextStyles.headline2.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first OpenClaw Gateway\nconnection to get started',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: CupertinoColors.tertiaryLabel,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: () => _navigateToAdd(context),
            child: const Text('Add Connection'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 48,
            color: CupertinoColors.systemRed.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load',
            style: AppTextStyles.headline3.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            onPressed: _onRefresh,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const AddConnectionScreen()),
    );
  }

  void _onConnectionTap(String connectionId) {
    // Get the connection config
    final state = ref.read(connectionListProvider);
    final connection = state.connections
        .where((c) => c.id == connectionId)
        .firstOrNull;

    if (connection == null) return;

    // Show action sheet with connection options
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(connection.name),
        message: Text('${connection.host}:${connection.port}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _connectToGateway(connection);
            },
            child: const Text('Connect'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat(connectionId);
            },
            child: const Text('Open Chat'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _connectToGateway(ConnectionConfig connection) async {
    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connected'),
            content: Text(
              'Successfully connected to ${connection.host}:${connection.port}',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Connection Failed'),
            content: Text(e.toString()),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  void _navigateToChat(String connectionId) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SessionListScreen(connectionId: connectionId),
      ),
    );
  }
}
