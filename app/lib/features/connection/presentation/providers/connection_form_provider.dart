import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/entities/connection_config.dart';

/// Form state for connection add/edit
class ConnectionFormState {
  final String name;
  final String host;
  final String port;
  final String? token;
  final String? password;
  final bool useTLS;
  final bool isSubmitting;
  final bool isValid;
  final Map<String, String?> errors;

  const ConnectionFormState({
    this.name = '',
    this.host = '',
    this.port = '8080',
    this.token,
    this.password,
    this.useTLS = false,
    this.isSubmitting = false,
    this.isValid = false,
    this.errors = const {},
  });

  ConnectionFormState copyWith({
    String? name,
    String? host,
    String? port,
    String? token,
    String? password,
    bool? useTLS,
    bool? isSubmitting,
    bool? isValid,
    Map<String, String?>? errors,
  }) {
    return ConnectionFormState(
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      password: password ?? this.password,
      useTLS: useTLS ?? this.useTLS,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
    );
  }

  /// Get field error if any
  String? getFieldError(String field) => errors[field];

  /// Check if specific field has error
  bool hasFieldError(String field) =>
      errors.containsKey(field) && errors[field] != null;
}

/// Notifier for connection form state management
class ConnectionFormNotifier extends StateNotifier<ConnectionFormState> {
  ConnectionFormNotifier() : super(const ConnectionFormState());

  /// Initialize form with existing connection data (for editing)
  void initializeWithConnection(ConnectionConfig config) {
    state = ConnectionFormState(
      name: config.name,
      host: config.host,
      port: config.port.toString(),
      token: config.token,
      password: config.password,
      useTLS: config.useTLS,
    );
    _validateAll();
  }

  /// Update name field
  void setName(String value) {
    state = state.copyWith(name: value);
    _validateField('name', Validators.connectionName(value));
  }

  /// Update host field
  void setHost(String value) {
    state = state.copyWith(host: value);
    _validateField('host', Validators.host(value));
  }

  /// Update port field
  void setPort(String value) {
    state = state.copyWith(port: value);
    _validateField('port', Validators.port(value));
  }

  /// Update token field
  void setToken(String? value) {
    state = state.copyWith(token: value);
  }

  /// Update password field
  void setPassword(String? value) {
    state = state.copyWith(password: value);
  }

  /// Toggle TLS setting
  void toggleTLS() {
    state = state.copyWith(useTLS: !state.useTLS);
  }

  /// Validate a single field
  void _validateField(String field, String? error) {
    final updatedErrors = Map<String, String?>.from(state.errors);
    if (error != null) {
      updatedErrors[field] = error;
    } else {
      updatedErrors.remove(field);
    }
    state = state.copyWith(
      errors: updatedErrors,
      isValid: updatedErrors.isEmpty,
    );
  }

  /// Validate all fields
  void _validateAll() {
    final errors = <String, String?>{
      'name': Validators.connectionName(state.name),
      'host': Validators.host(state.host),
      'port': Validators.port(state.port),
    }..removeWhere((_, error) => error == null);

    state = state.copyWith(errors: errors, isValid: errors.isEmpty);
  }

  /// Validate all fields and return if valid
  bool validate() {
    _validateAll();
    return state.isValid;
  }

  /// Build ConnectionConfig from form state
  ConnectionConfig buildConfig({String? id}) {
    return ConnectionConfig(
      id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: state.name.trim(),
      host: state.host.trim(),
      port: int.parse(state.port.trim()),
      token: state.token?.trim().isEmpty ?? true ? null : state.token?.trim(),
      password: state.password?.trim().isEmpty ?? true
          ? null
          : state.password?.trim(),
      useTLS: state.useTLS,
      createdAt: DateTime.now(),
    );
  }

  /// Submit form - returns config if valid
  Future<ConnectionConfig?> submit() async {
    if (!validate()) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final config = buildConfig();
      state = state.copyWith(isSubmitting: false);
      return config;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }

  /// Submit form with existing ID (for editing)
  Future<ConnectionConfig?> submitEdit(String id) async {
    if (!validate()) return null;

    state = state.copyWith(isSubmitting: true);

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final config = buildConfig(id: id);
      state = state.copyWith(isSubmitting: false);
      return config;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      return null;
    }
  }

  /// Reset form to initial state
  void reset() {
    state = const ConnectionFormState();
  }
}

/// Provider for connection form state
final connectionFormProvider =
    StateNotifierProvider<ConnectionFormNotifier, ConnectionFormState>(
      (ref) => ConnectionFormNotifier(),
    );
