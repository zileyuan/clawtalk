import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/text_input.dart';
import '../../../../core/constants/content_limits.dart';

/// State class for text input
class TextInputState {
  /// The current text input
  final TextInput input;

  /// Whether the input is currently focused
  final bool isFocused;

  /// Whether there is an error
  final bool hasError;

  /// Error message if any
  final String? errorMessage;

  /// Current line count
  final int lineCount;

  const TextInputState({
    required this.input,
    this.isFocused = false,
    this.hasError = false,
    this.errorMessage,
    this.lineCount = 1,
  });

  /// Factory constructor for empty state
  factory TextInputState.empty({int? maxLength}) {
    return TextInputState(
      input: TextInput(
        content: '',
        maxLength: maxLength ?? ContentLimits.maxTextLength,
      ),
    );
  }

  /// Returns true if the text is not empty
  bool get hasContent => input.content.isNotEmpty;

  /// Returns the current text content
  String get text => input.content;

  /// Returns the character count
  int get characterCount => input.content.length;

  /// Returns true if at max length
  bool get isAtMaxLength =>
      input.maxLength != null && characterCount >= input.maxLength!;

  /// Returns remaining characters
  int get remainingCharacters =>
      input.maxLength != null ? input.maxLength! - characterCount : -1;

  TextInputState copyWith({
    TextInput? input,
    bool? isFocused,
    bool? hasError,
    String? errorMessage,
    int? lineCount,
  }) {
    return TextInputState(
      input: input ?? this.input,
      isFocused: isFocused ?? this.isFocused,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      lineCount: lineCount ?? this.lineCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextInputState &&
        other.input == input &&
        other.isFocused == isFocused &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage &&
        other.lineCount == lineCount;
  }

  @override
  int get hashCode {
    return Object.hash(input, isFocused, hasError, errorMessage, lineCount);
  }
}

/// Notifier for text input state management
class TextInputNotifier extends StateNotifier<TextInputState> {
  TextInputNotifier({int? maxLength})
    : super(TextInputState.empty(maxLength: maxLength));

  /// Update the text content
  void updateText(String text) {
    final lineCount = text.isEmpty ? 1 : '\n'.allMatches(text).length + 1;
    final input = state.input.copyWith(content: text);

    // Validate
    String? errorMessage;
    bool hasError = false;

    if (input.maxLength != null && text.length > input.maxLength!) {
      errorMessage = 'Maximum ${input.maxLength} characters allowed';
      hasError = true;
    } else if (lineCount > ContentLimits.maxTextLines) {
      errorMessage = 'Maximum ${ContentLimits.maxTextLines} lines allowed';
      hasError = true;
    }

    state = state.copyWith(
      input: input,
      lineCount: lineCount > ContentLimits.maxTextLines
          ? ContentLimits.maxTextLines
          : lineCount,
      hasError: hasError,
      errorMessage: errorMessage,
    );
  }

  /// Clear the text input
  void clear() {
    state = state.copyWith(
      input: state.input.copyWith(content: ''),
      lineCount: 1,
      hasError: false,
      errorMessage: null,
    );
  }

  /// Set focus state
  void setFocus(bool focused) {
    state = state.copyWith(isFocused: focused);
  }

  /// Set maximum length
  void setMaxLength(int? maxLength) {
    state = state.copyWith(input: state.input.copyWith(maxLength: maxLength));
  }

  /// Validate the current input
  bool validate() {
    final isValid = state.input.isValid;
    state = state.copyWith(
      hasError: !isValid,
      errorMessage: state.input.validationError,
    );
    return isValid;
  }

  /// Get the current text
  String get text => state.text;

  /// Check if content is valid
  bool get isValid => state.input.isValid && !state.hasError;
}

/// Provider for text input state
final textInputProvider =
    StateNotifierProvider.family<TextInputNotifier, TextInputState, int?>(
      (ref, maxLength) => TextInputNotifier(maxLength: maxLength),
    );

/// Provider for text content (for simpler access)
final textContentProvider = Provider.family<String, int?>((ref, maxLength) {
  return ref.watch(textInputProvider(maxLength)).text;
});

/// Provider for text validation status
final textValidationProvider = Provider.family<bool, int?>((ref, maxLength) {
  return ref.watch(textInputProvider(maxLength)).isValid;
});

/// Provider for character count
final textCharacterCountProvider = Provider.family<int, int?>((ref, maxLength) {
  return ref.watch(textInputProvider(maxLength)).characterCount;
});
