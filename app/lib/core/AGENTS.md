# Core Infrastructure

Shared utilities, DI, themes, navigation, and common widgets.

## STRUCTURE

```
core/
├── constants/     # App constants, API endpoints
├── data/          # Local data sources (storage services)
├── di/            # ServiceLocator, provider registrations
├── errors/        # Failure types, exceptions
├── l10n/          # Locale provider
├── navigation/    # AppRoutes, AppRouter, NavigationService
├── providers/     # Global providers (theme, connection, app)
├── themes/        # AppTheme, AppColors
├── utils/         # Formatters, validators, extensions
└── widgets/       # Shared widgets (buttons, dialogs, inputs, cards)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add global provider | `providers/` + export in `providers.dart` |
| Add shared widget | `widgets/{category}/` |
| Change theme | `themes/app_theme.dart` |
| Add route | `navigation/app_routes.dart` + `app_router.dart` |
| Add storage service | `di/providers.dart` + ServiceLocator |
| Add error type | `errors/failures.dart` |

## CONVENTIONS

- **Providers**: Use `providers.dart` barrel file for exports
- **Widgets**: Organize by category (buttons, inputs, dialogs)
- **Navigation**: Use `NavigationService` methods, not direct `Navigator`
- **DI**: Register in ServiceLocator, expose via Riverpod provider

## ANTI-PATTERNS

- **NO** hardcoded colors — use `AppColors` or `Theme.of(context)`
- **NO** direct SharedPreferences — use `PreferencesService`
- **NO** direct Navigator — use `NavigationService` or `AppRouter`