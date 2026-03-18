# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-18
**Commit:** 59dbc95
**Branch:** main

## OVERVIEW

ClawTalk — Cross-platform Flutter client for OpenClaw Gateway using ACP (Agent Client Protocol) over WebSocket. Cupertino-style UI with Riverpod state management.

## STRUCTURE

```
lib/
├── main.dart              # Entry: Riverpod + EasyLocalization bootstrap
├── app.dart               # CupertinoApp root widget
├── acp/                   # ACP Protocol layer (WebSocket client, services)
├── core/                  # Shared infrastructure (DI, themes, navigation, widgets)
├── features/              # Feature modules (clean architecture)
│   ├── connection/        # Connection management (complete)
│   ├── messaging/         # Chat sessions (complete)
│   ├── settings/          # App settings (complete)
│   ├── agents/            # Agent list (domain/presentation only)
│   └── input/             # Input handlers (domain/presentation only)
├── platform/              # Platform-specific services (macos, ios, android, windows)
└── l10n/                  # EMPTY - remove or populate
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add new screen | `lib/features/{feature}/presentation/screens/` | Register route in `core/navigation/app_routes.dart` |
| Add new provider | `lib/features/{feature}/presentation/providers/` | Use StateNotifier pattern with `copyWith()` state |
| Add repository | `lib/features/{feature}/domain/repositories/` + `data/repositories/` | Interface in domain, impl in data |
| Add shared widget | `lib/core/widgets/` | Buttons, dialogs, inputs, sheets, cards |
| Add platform service | `lib/platform/{platform}/` | Implement PlatformInterface |
| Modify ACP protocol | `lib/acp/` | Client, services, models |
| Change theme | `lib/core/themes/` | AppTheme, AppColors |
| Add translation | `assets/translations/{locale}.json` | en, zh, zh_TW supported |

## CONVENTIONS

- **Imports**: Always use `package:clawtalk/...` (never relative)
- **Quotes**: Single quotes for strings
- **Line length**: Max 80 chars
- **State**: Immutable with `copyWith()`, use Freezed for models
- **Error handling**: Repository returns `({Failure? failure, T? data})` records
- **Trailing commas**: Required in all parameter lists
- **Docs**: `///` for public API docs

## ANTI-PATTERNS (THIS PROJECT)

- **NO** hardcoded colors — use `Theme.of(context)` or `AppColors`
- **NO** `print()` — use `serviceLocator.logger`
- **NO** dynamic calls — strict types enforced
- **NO** editing `*.g.dart`, `*.freezed.dart` — regenerate with `build_runner`
- **StreamController.broadcast()** must have `close()` in `dispose()`

## UNIQUE STYLES

- **Cupertino-first**: iOS-style widgets, no Material except fallback
- **ACP Protocol**: WebSocket-based Agent Client Protocol (not REST)
- **Two-tier DI**: ServiceLocator (global) + Riverpod (widget tree)
- **No use_cases layer**: Business logic in StateNotifiers

## COMMANDS

```bash
# Development
flutter pub get
flutter run -d macos

# Code generation
flutter pub run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze

# Build
flutter build macos --debug
```

## NOTES

- `lib/l10n/` is empty — translations are JSON in `assets/translations/`
- 26 TODOs exist (mostly API stub implementations)
- 21 StreamController.broadcast() need dispose audit
- Features `agents/` and `input/` missing data layer (intentional?)