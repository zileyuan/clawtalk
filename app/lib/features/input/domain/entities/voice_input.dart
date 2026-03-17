/// A voice input entity for handling audio recordings.
class VoiceInput {
  final String id;
  final String path;
  final int sizeBytes;
  final Duration duration;
  final String format;
  final String? waveform;

  const VoiceInput({
    required this.id,
    required this.path,
    required this.sizeBytes,
    required this.duration,
    required this.format,
    this.waveform,
  });

  /// Returns true if the duration is within typical limits (5 minutes).
  bool get hasValidDuration {
    return duration.inSeconds > 0 && duration.inSeconds <= 300;
  }

  /// Returns true if the file size is within typical limits (25MB).
  bool get hasValidSize {
    return sizeBytes > 0 && sizeBytes <= 25 * 1024 * 1024;
  }

  /// Returns the duration in a human-readable format.
  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns true if the voice input is short (under 30 seconds).
  bool get isShort => duration.inSeconds < 30;

  /// Returns true if the voice input is medium length (30 seconds to 2 minutes).
  bool get isMedium => duration.inSeconds >= 30 && duration.inSeconds < 120;

  /// Returns true if the voice input is long (2 minutes or more).
  bool get isLong => duration.inSeconds >= 120;

  VoiceInput copyWith({
    String? id,
    String? path,
    int? sizeBytes,
    Duration? duration,
    String? format,
    String? waveform,
  }) {
    return VoiceInput(
      id: id ?? this.id,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      duration: duration ?? this.duration,
      format: format ?? this.format,
      waveform: waveform ?? this.waveform,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VoiceInput &&
        other.id == id &&
        other.path == path &&
        other.sizeBytes == sizeBytes &&
        other.duration == duration &&
        other.format == format &&
        other.waveform == waveform;
  }

  @override
  int get hashCode {
    return Object.hash(id, path, sizeBytes, duration, format, waveform);
  }

  @override
  String toString() {
    return 'VoiceInput(id: $id, path: $path, sizeBytes: $sizeBytes, '
        'duration: $duration, format: $format, hasWaveform: ${waveform != null})';
  }
}
