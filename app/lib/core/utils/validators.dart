class Validators {
  Validators._();

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  static String? host(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Host is required';
    }
    final trimmed = value.trim();
    if (trimmed.contains('://')) {
      return 'Host should not include protocol (http:// or https://)';
    }
    if (trimmed.contains('/')) {
      return 'Host should not include path';
    }
    return null;
  }

  static String? port(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Port is required';
    }
    final port = int.tryParse(value.trim());
    if (port == null) {
      return 'Port must be a number';
    }
    if (port < 1 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }
    return null;
  }

  static String? textContent(String? value, {int maxLength = 100000}) {
    if (value == null || value.isEmpty) {
      return 'Content cannot be empty';
    }
    if (value.length > maxLength) {
      return 'Content exceeds maximum length of $maxLength characters';
    }
    return null;
  }

  static String? connectionName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Connection name is required';
    }
    if (value.trim().length < 2) {
      return 'Connection name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Connection name must be at most 50 characters';
    }
    return null;
  }
}
