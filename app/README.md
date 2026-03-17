# ClawTalk

**ClawTalk** is a cross-platform client for OpenClaw, built with Flutter and designed to provide a seamless experience across macOS, Windows, Android, and iOS.

## Features

- 🌐 **Multi-platform**: macOS, Windows, Android, iOS
- 💬 **ACP Protocol**: Full WebSocket-based Agent Client Protocol support
- 📝 **Text Input**: Multi-line text with validation and formatting
- 📷 **Image Input**: Camera capture, gallery selection, drag & drop
- 🎤 **Voice Input**: Audio recording with waveform visualization
- 🔌 **Connection Management**: Manage multiple OpenClaw Gateway connections
- 🎨 **Cupertino Design**: iOS-style UI with dark mode support
- 🌍 **Internationalization**: English and Chinese support

## Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.41 (Puro) |
| State Management | Riverpod |
| UI Style | Cupertino (iOS-style) |
| Protocol | ACP over WebSocket |
| Architecture | Clean Architecture |

## Getting Started

### Prerequisites

- [Puro](https://puro.dev/) Flutter version manager
- Flutter SDK 3.41.0

### Installation

```bash
# Install Puro (if not already installed)
dart pub global activate puro

# Create Flutter environment
puro create flutter341 3.41.0

# Clone the repository
git clone <repository-url>
cd client/app

# Install dependencies
puro flutter pub get

# Run the app
puro flutter run
```

### Platform Setup

#### macOS
```bash
puro flutter run -d macos
```

#### Windows
```bash
puro flutter run -d windows
```

#### Android
```bash
puro flutter run -d android
```

#### iOS
```bash
puro flutter run -d ios
```

## Project Structure

```
lib/
├── core/               # Core functionality
│   ├── constants/      # App constants
│   ├── errors/         # Error handling
│   ├── themes/         # Theme configuration
│   ├── l10n/           # Localization
│   └── utils/          # Utilities
├── acp/                # ACP Protocol layer
│   ├── client/         # WebSocket client
│   ├── models/         # Protocol models
│   ├── services/       # Protocol services
│   └── exceptions/     # Protocol exceptions
├── features/           # Feature modules
│   ├── connection/     # Connection management
│   ├── messaging/      # Chat functionality
│   ├── input/          # Input handling
│   ├── agents/         # Agent management
│   └── settings/       # App settings
├── platform/           # Platform-specific code
│   ├── macos/
│   ├── windows/
│   ├── android/
│   └── ios/
└── main.dart           # Entry point
```

## Architecture

ClawTalk follows Clean Architecture principles:

- **Presentation Layer**: UI components, screens, and state management
- **Domain Layer**: Business logic, entities, and use cases
- **Data Layer**: Repository implementations and data sources
- **Platform Layer**: Platform-specific services

## Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
DEFAULT_GATEWAY_HOST=localhost
DEFAULT_GATEWAY_PORT=18789
LOG_LEVEL=debug
```

### Connection Settings

Default connection settings can be configured in `lib/core/constants/api_constants.dart`.

## Testing

```bash
# Run all tests
puro flutter test

# Run with coverage
puro flutter test --coverage

# Run integration tests
puro flutter test integration_test/
```

## Documentation

- [Product Requirements](../docs/product-requirements.md)
- [Technical Architecture](../docs/technical-architecture.md)
- [API Design](../docs/design/01-api-design.md)
- [Implementation Plan](../IMPLEMENTATION_PLAN.md)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- OpenClaw Team
- Flutter Team
- Riverpod Contributors