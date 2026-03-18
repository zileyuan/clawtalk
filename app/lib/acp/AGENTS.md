# ACP Protocol Layer

WebSocket-based Agent Client Protocol implementation for OpenClaw Gateway communication.

## STRUCTURE

```
acp/
├── client/        # AcpClient interface + implementation
├── models/        # Protocol models (freezed)
├── protocol/      # Message definitions
├── services/      # Connection, Message, Heartbeat, Reconnection
└── exceptions/    # AcpException types
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add new message type | `protocol/acp_message.dart` |
| Modify connection logic | `client/acp_client_impl.dart` |
| Add service | `services/` — inject via ServiceLocator |
| Handle errors | `exceptions/acp_exceptions.dart` |

## CONVENTIONS

- **AcpClient**: Abstract interface in `client/`, impl in `acp_client_impl.dart`
- **Messages**: Use Freezed for immutable models
- **Services**: StreamController.broadcast() — MUST call `close()` in dispose
- **Error handling**: Throw `AcpException` subclasses

## ANTI-PATTERNS

- **NO** direct WebSocket access — use `AcpClient` interface
- **NO** blocking calls — all operations are async
- **NO** state mutation — emit new state via streams

## KEY INTERFACES

```dart
AcpClient.connect(config)      // Establish connection
AcpClient.sendRequest<T>()     // Request-response pattern
AcpClient.sendNotification()   // Fire-and-forget
AcpClient.events               // Stream<AcpEvent> from server
```