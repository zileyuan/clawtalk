/// Connection configuration entity for storing server connection details.
class ConnectionConfig {
  final String id;
  final String name;
  final String host;
  final int port;
  final String? token;
  final String? password;
  final bool useTLS;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const ConnectionConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.token,
    this.password,
    this.useTLS = false,
    required this.createdAt,
    this.lastUsed,
  });

  ConnectionConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? token,
    String? password,
    bool? useTLS,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return ConnectionConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      token: token ?? this.token,
      password: password ?? this.password,
      useTLS: useTLS ?? this.useTLS,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionConfig &&
        other.id == id &&
        other.name == name &&
        other.host == host &&
        other.port == port &&
        other.token == token &&
        other.password == password &&
        other.useTLS == useTLS &&
        other.createdAt == createdAt &&
        other.lastUsed == lastUsed;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      host,
      port,
      token,
      password,
      useTLS,
      createdAt,
      lastUsed,
    );
  }

  @override
  String toString() {
    return 'ConnectionConfig(id: $id, name: $name, host: $host, port: $port, '
        'useTLS: $useTLS, createdAt: $createdAt, lastUsed: $lastUsed)';
  }
}
