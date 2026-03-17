class ApiConstants {
  ApiConstants._();

  static const String defaultHost = 'localhost';
  static const int defaultPort = 18789;
  static const String wsPath = '/ws';
  static const String apiVersion = 'v1';

  static Uri buildWebSocketUri({
    required String host,
    required int port,
    String path = wsPath,
  }) {
    return Uri.parse('ws://$host:$port$path');
  }

  static Uri buildHttpUri({
    required String host,
    required int port,
    required String path,
  }) {
    return Uri.parse('http://$host:$port$path');
  }
}
