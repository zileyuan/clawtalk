/// A text input entity for validating and processing user text input.
class TextInput {
  final String content;
  final int? maxLength;
  final bool validate;

  const TextInput({
    required this.content,
    this.maxLength,
    this.validate = true,
  });

  /// Returns true if the content is valid according to the constraints.
  bool get isValid {
    if (!validate) return true;
    if (content.isEmpty) return false;
    if (maxLength != null && content.length > maxLength!) return false;
    return true;
  }

  /// Returns the validation error message, or null if valid.
  String? get validationError {
    if (!validate) return null;
    if (content.isEmpty) return 'Content cannot be empty';
    if (maxLength != null && content.length > maxLength!) {
      return 'Content exceeds maximum length of $maxLength characters';
    }
    return null;
  }

  TextInput copyWith({String? content, int? maxLength, bool? validate}) {
    return TextInput(
      content: content ?? this.content,
      maxLength: maxLength ?? this.maxLength,
      validate: validate ?? this.validate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextInput &&
        other.content == content &&
        other.maxLength == maxLength &&
        other.validate == validate;
  }

  @override
  int get hashCode {
    return Object.hash(content, maxLength, validate);
  }

  @override
  String toString() {
    return 'TextInput(content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, '
        'maxLength: $maxLength, validate: $validate)';
  }
}
