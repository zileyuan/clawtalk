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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(connectionListProvider.notifier).loadConnections();
      ref.read(connectionStatusProvider.notifier).startMonitoring();

      // Create and save the test connection (but don't auto-connect)
      await _createTestConnection(autoConnect: false);
    });
  }

  /// Create test connection and save it
  Future<void> _createTestConnection({bool autoConnect = true}) async {
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    print('[DEBUG] ========== Creating Test Connection ==========');

    // Check if connection already exists
    final state = ref.read(connectionListProvider);
    // Use 192.168.88.84 - gateway now listens on all interfaces
    final existing = state.connections
        .where((c) => c.host == '192.168.88.84')
        .firstOrNull;

    ConnectionConfig connection;
    if (existing == null) {
      // Create new connection with gateway token
      connection = ConnectionConfig(
        id: 'test-gateway-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Gateway (LAN)',
        host: '192.168.88.84',
        port: 18789,
        token: '3796df06a7b5801caba54f35669281841ce2c3d9bfa1e6ce',
        createdAt: DateTime.now(),
      );

      print('[DEBUG] Saving connection: ${connection.host}:${connection.port}');
      await ref.read(connectionListProvider.notifier).addConnection(connection);
      print('[DEBUG] Connection saved!');
    } else {
      connection = existing;
      print('[DEBUG] Connection already exists: ${connection.id}');
    }

    // Only auto-connect if requested
    if (!autoConnect) {
      print('[DEBUG] Auto-connect disabled, user can click Connect button');
      return;
    }

    // Now try to connect
    print('[DEBUG] ========== Attempting Connection ==========');
    print('[DEBUG] Connecting to ${connection.host}:${connection.port}...');
    print('[DEBUG] Token: ${connection.token ?? "null"}');

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
      print('[DEBUG] ========== ✅ CONNECTED SUCCESSFULLY! ==========');
    } catch (e) {
      print('[DEBUG] ========== ❌ CONNECTION FAILED: $e ==========');

      // Check if this is a pairing required error
      if (mounted) {
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('pairing required') ||
            errorString.contains('not_paired')) {
          _showPairingRequiredDialog();
        }
      }
    }
  }

  /// Show dialog when device pairing is required
  void _showPairingRequiredDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Device Pairing Required'),
        content: const Text(
          'A pairing request has been sent to the Gateway.\n\n'
          'Please ask the OpenClaw administrator to approve this device:\n\n'
          '• Run: openclaw devices list\n'
          '• Run: openclaw devices approve --latest\n\n'
          'After approval, try connecting again.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Auto-test Gateway connection for debugging
  Future<void> _autoTestGatewayConnection() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    print('[DEBUG] ========== Auto-testing Gateway Connection ==========');

    // User's test connection - using localhost since 192.168.88.84 is not reachable
    final connection = ConnectionConfig(
      id: 'test-gateway',
      name: 'Test Gateway',
      host: '127.0.0.1',
      port: 18789,
      token: '3796df06a7b5801caba54f35669281841ce2c3d9bfa1e6ce',
      createdAt: DateTime.now(),
    );

    print('[DEBUG] Connecting to ${connection.host}:${connection.port}...');
    print('[DEBUG] Token: ${connection.token}');

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
      print('[DEBUG] ========== ✅ CONNECTED SUCCESSFULLY! ==========');
    } catch (e) {
      print('[DEBUG] ========== ❌ CONNECTION FAILED: $e ==========');
    }
  }

  /// Debug: Auto-connect to localhost Gateway
  Future<void> _debugAutoConnect() async {
    await Future.delayed(const Duration(seconds: 1));

    // Check if Gateway is running on localhost
    final connection = ConnectionConfig(
      id: 'localhost-debug',
      name: 'Local Gateway',
      host: '127.0.0.1',
      port: 18789,
      createdAt: DateTime.now(),
    );

    print('[DEBUG] Attempting to connect to localhost:18789...');

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
      print('[DEBUG] Connected successfully!');
    } catch (e) {
      print('[DEBUG] Connection failed: $e');
    }
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
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: () => _quickConnectLocalhost(context),
            child: const Text('Test Gateway Connection (localhost:18789)'),
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

  /// Quick connect to localhost Gateway for debugging
  Future<void> _quickConnectLocalhost(BuildContext context) async {
    print('[DEBUG] ========== Testing Gateway Connection ==========');

    // Create a temporary connection config for localhost
    final connection = ConnectionConfig(
      id: 'localhost-debug',
      name: 'Local Gateway',
      host: '127.0.0.1',
      port: 18789,
      createdAt: DateTime.now(),
    );

    print('[DEBUG] Connecting to ${connection.host}:${connection.port}...');

    try {
      await ref
          .read(connectionStatusProvider.notifier)
          .connectToConnection(connection);
      print('[DEBUG] ========== CONNECTED SUCCESSFULLY! ==========');

      if (mounted) {
        showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('✅ Connected!'),
            content: const Text(
              'Successfully connected to OpenClaw Gateway!\n\nGateway Protocol handshake completed.',
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
      print('[DEBUG] ========== CONNECTION FAILED: $e ==========');

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
}
