/// Represents supported languages in the app
enum AppLanguage {
  english('en', 'English'),
  chinese('zh', '中文'),
  japanese('ja', '日本語'),
  korean('ko', '한국어'),
  spanish('es', 'Español'),
  french('fr', 'Français'),
  german('de', 'Deutsch');

  final String code;
  final String displayName;

  const AppLanguage(this.code, this.displayName);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Represents theme mode options
enum AppThemeMode {
  system('System', 'Follows system setting'),
  light('Light', 'Always light mode'),
  dark('Dark', 'Always dark mode');

  final String displayName;
  final String description;

  const AppThemeMode(this.displayName, this.description);

  static AppThemeMode fromName(String name) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.displayName.toLowerCase() == name.toLowerCase(),
      orElse: () => AppThemeMode.system,
    );
  }
}

/// App settings entity
class AppSettings {
  final String? id;
  final AppLanguage language;
  final AppThemeMode themeMode;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool hapticEnabled;
  final bool analyticsEnabled;
  final DateTime? lastSyncedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppSettings({
    this.id,
    this.language = AppLanguage.english,
    this.themeMode = AppThemeMode.system,
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.hapticEnabled = true,
    this.analyticsEnabled = true,
    this.lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  AppSettings copyWith({
    String? id,
    AppLanguage? language,
    AppThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? hapticEnabled,
    bool? analyticsEnabled,
    DateTime? lastSyncedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      id: id ?? this.id,
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticEnabled: hapticEnabled ?? this.hapticEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language': language.code,
      'themeMode': themeMode.displayName,
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'hapticEnabled': hapticEnabled,
      'analyticsEnabled': analyticsEnabled,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] as String?,
      language: AppLanguage.fromCode(json['language'] as String? ?? 'en'),
      themeMode: AppThemeMode.fromName(
        json['themeMode'] as String? ?? 'System',
      ),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
      hapticEnabled: json['hapticEnabled'] as bool? ?? true,
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.parse(json['lastSyncedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
