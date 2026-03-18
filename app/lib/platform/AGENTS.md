# Platform Services

Platform-specific implementations for macOS, iOS, Android, Windows.

## STRUCTURE

```
platform/
├── macos/     # macOSAudioService, etc.
├── ios/       # iOSAudioService, etc.
├── android/   # AndroidAudioService, etc.
└── windows/   # WindowsAudioService, etc.
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add platform service | Create in `{platform}/` + implement `PlatformInterface` |
| Modify audio handling | `{platform}/{platform}_audio_service.dart` |

## CONVENTIONS

- Each platform has identical interface via `PlatformInterface`
- Services are registered in `ServiceLocator` based on `Platform.is*`
- Use `StreamController.broadcast()` — MUST dispose properly

## ANTI-PATTERNS

- **NO** conditional platform checks in features — use injected service
- **NO** direct platform channel calls — wrap in service