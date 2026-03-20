import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import 'package:clawtalk/core/providers/connection_provider.dart';
import 'package:clawtalk/gateway/protocol/gateway_request.dart';
import '../../domain/entities/session.dart';

/// Provider for session management
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref),
);

/// Provider for the list of sessions
final sessionsListProvider = Provider<List<Session>>((ref) {
  return ref.watch(sessionProvider).sessions;
});

/// Provider for the currently active session
final activeSessionProvider = Provider<Session?>((ref) {
  return ref.watch(sessionProvider).activeSession;
});

/// Provider for session loading state
final isSessionsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(sessionProvider).isLoading;
});

/// State class for session management
class SessionState {
  final List<Session> sessions;
  final Session? activeSession;
  final bool isLoading;
  final String? error;

  const SessionState({
    this.sessions = const [],
    this.activeSession,
    this.isLoading = false,
    this.error,
  });

  SessionState copyWith({
    List<Session>? sessions,
    Session? activeSession,
    bool? isLoading,
    String? error,
  }) {
    return SessionState(
      sessions: sessions ?? this.sessions,
      activeSession: activeSession ?? this.activeSession,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get sessions sorted by creation time (newest first)
  List<Session> get sortedSessions {
    final sorted = List<Session>.from(sessions);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Get only active sessions
  List<Session> get activeSessions {
    return sessions.where((s) => s.status == SessionStatus.active).toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionState &&
        other.sessions == sessions &&
        other.activeSession == activeSession &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(sessions, activeSession, isLoading, error);
  }
}

/// Notifier for managing sessions
class SessionNotifier extends StateNotifier<SessionState> {
  final Ref _ref;
  final _uuid = const Uuid();
  final Logger _logger = Logger();

  SessionNotifier(this._ref) : super(const SessionState());

  /// Load all sessions from Gateway
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);
    _logger.i('[SESSION] Loading sessions...');

    try {
      final connectionManager = _ref.read(connectionManagerProvider);
      _logger.i(
        '[SESSION] Connection state: isConnected=${connectionManager.isConnected}',
      );

      if (!connectionManager.isConnected) {
        _logger.w('[SESSION] Not connected to Gateway');
        state = state.copyWith(sessions: [], isLoading: false);
        return;
      }

      final client = _ref.read(connectionManagerProvider.notifier).client;
      final request = GatewayRequestFactory.sessionsList();
      _logger.i('[SESSION] Sending request: ${request.toJson()}');

      final response = await client.sendRequest(request);
      _logger.i(
        '[SESSION] Response: ok=${response.ok}, payload=${response.payload}',
      );

      if (response.ok && response.payload != null) {
        final sessionsJson =
            response.payload!['sessions'] as List? ??
            response.payload!['data'] as List? ??
            [];
        final sessions = sessionsJson
            .map(
              (json) => Session.fromGatewayJson(json as Map<String, dynamic>),
            )
            .toList();
        state = state.copyWith(sessions: sessions, isLoading: false);
        _logger.i('[SESSION] Loaded ${sessions.length} sessions from Gateway');
      } else {
        _logger.w('[SESSION] Response not OK or no payload');
        state = state.copyWith(sessions: [], isLoading: false);
      }
    } catch (e, stackTrace) {
      _logger.e('[SESSION] Failed to load sessions: $e');
      _logger.e('[SESSION] StackTrace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sessions: $e',
      );
    }
  }

  /// Create a new session
  /// Note: Gateway doesn't have explicit session creation.
  /// Sessions are created implicitly via chat.send.
  /// This method creates a local session for UI purposes.
  Future<Session?> createSession({
    required String agentId,
    required String connectionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Generate a session key for Gateway
      // Format: agent:<agentId>:main for direct agent sessions
      final sessionKey = 'agent:$agentId:main';

      final session = Session(
        id: sessionKey,
        agentId: agentId,
        connectionId: connectionId,
        status: SessionStatus.active,
        createdAt: DateTime.now(),
      );

      // Add to local state
      // The session will be activated when first chat.send is called
      state = state.copyWith(
        sessions: [...state.sessions, session],
        activeSession: session,
        isLoading: false,
      );

      _logger.i('Created local session: $sessionKey');
      return session;
    } catch (e) {
      _logger.e('Failed to create session: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create session: $e',
      );
      return null;
    }
  }

  /// Set the active session
  void setActiveSession(Session? session) {
    state = state.copyWith(activeSession: session);
  }

  /// Select a session by ID
  void selectSession(String sessionId) {
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    setActiveSession(session);
  }

  /// End a session
  Future<void> endSession(String sessionId) async {
    try {
      // Find the session to get its key
      final session = state.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );

      // Try to reset session on Gateway using sessionKey
      final connectionManager = _ref.read(connectionManagerProvider);
      if (connectionManager.isConnected && session.key.isNotEmpty) {
        try {
          final client = _ref.read(connectionManagerProvider.notifier).client;
          final request = GatewayRequestFactory.sessionsReset(
            sessionKey: session.key,
          );
          await client.sendRequest(request);
          _logger.i('Reset session on Gateway: ${session.key}');
        } catch (e) {
          _logger.w('Failed to reset session on Gateway: $e');
        }
      }

      final updatedSessions = state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(
            status: SessionStatus.ended,
            endedAt: DateTime.now(),
          );
        }
        return s;
      }).toList();

      state = state.copyWith(
        sessions: updatedSessions,
        activeSession: state.activeSession?.id == sessionId
            ? null
            : state.activeSession,
      );
    } catch (e) {
      _logger.e('Failed to end session: $e');
      state = state.copyWith(error: 'Failed to end session: $e');
    }
  }

  /// Pause a session
  Future<void> pauseSession(String sessionId) async {
    try {
      final updatedSessions = state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(status: SessionStatus.paused);
        }
        return s;
      }).toList();

      // TODO: Replace with actual API call
      // await api.pauseSession(sessionId);

      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause session: $e');
    }
  }

  /// Resume a session
  Future<void> resumeSession(String sessionId) async {
    try {
      final updatedSessions = state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(status: SessionStatus.active);
        }
        return s;
      }).toList();

      // TODO: Replace with actual API call
      // await api.resumeSession(sessionId);

      state = state.copyWith(sessions: updatedSessions);
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume session: $e');
    }
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    try {
      // Find the session to get its key
      final session = state.sessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );

      // Try to delete session on Gateway using sessionKey
      final connectionManager = _ref.read(connectionManagerProvider);
      if (connectionManager.isConnected && session.key.isNotEmpty) {
        try {
          final client = _ref.read(connectionManagerProvider.notifier).client;
          final request = GatewayRequestFactory.sessionsDelete(
            sessionKey: session.key,
          );
          await client.sendRequest(request);
          _logger.i('Deleted session on Gateway: ${session.key}');
        } catch (e) {
          _logger.w('Failed to delete session on Gateway: $e');
          // Continue with local deletion even if Gateway fails
        }
      }

      final updatedSessions = state.sessions
          .where((s) => s.id != sessionId)
          .toList();

      state = state.copyWith(
        sessions: updatedSessions,
        activeSession: state.activeSession?.id == sessionId
            ? null
            : state.activeSession,
      );
    } catch (e) {
      _logger.e('Failed to delete session: $e');
      state = state.copyWith(error: 'Failed to delete session: $e');
    }
  }

  /// Update session
  void updateSession(Session updatedSession) {
    final updatedSessions = state.sessions.map((s) {
      return s.id == updatedSession.id ? updatedSession : s;
    }).toList();

    state = state.copyWith(
      sessions: updatedSessions,
      activeSession: state.activeSession?.id == updatedSession.id
          ? updatedSession
          : state.activeSession,
    );
  }

  /// Clear active session
  void clearActiveSession() {
    state = state.copyWith(activeSession: null);
  }

  /// Refresh sessions
  Future<void> refresh() async {
    await loadSessions();
  }

  /// Set error state
  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
