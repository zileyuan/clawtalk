import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/session.dart';

/// Provider for session management
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
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
  final _uuid = const Uuid();

  SessionNotifier() : super(const SessionState());

  /// Load all sessions
  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Replace with actual API call
      // final sessions = await api.getSessions();

      // Simulated delay
      await Future.delayed(const Duration(milliseconds: 300));

      // For now, return empty list
      const sessions = <Session>[];

      state = state.copyWith(sessions: sessions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sessions: $e',
      );
    }
  }

  /// Create a new session
  Future<Session?> createSession({
    required String agentId,
    required String connectionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final session = Session(
        id: _uuid.v4(),
        agentId: agentId,
        connectionId: connectionId,
        status: SessionStatus.active,
        createdAt: DateTime.now(),
      );

      // TODO: Replace with actual API call
      // final createdSession = await api.createSession(session);

      // Simulated delay
      await Future.delayed(const Duration(milliseconds: 200));

      state = state.copyWith(
        sessions: [...state.sessions, session],
        activeSession: session,
        isLoading: false,
      );

      return session;
    } catch (e) {
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
      final updatedSessions = state.sessions.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(
            status: SessionStatus.ended,
            endedAt: DateTime.now(),
          );
        }
        return s;
      }).toList();

      // TODO: Replace with actual API call
      // await api.endSession(sessionId);

      state = state.copyWith(
        sessions: updatedSessions,
        activeSession: state.activeSession?.id == sessionId
            ? null
            : state.activeSession,
      );
    } catch (e) {
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
      final updatedSessions = state.sessions
          .where((s) => s.id != sessionId)
          .toList();

      // TODO: Replace with actual API call
      // await api.deleteSession(sessionId);

      state = state.copyWith(
        sessions: updatedSessions,
        activeSession: state.activeSession?.id == sessionId
            ? null
            : state.activeSession,
      );
    } catch (e) {
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
