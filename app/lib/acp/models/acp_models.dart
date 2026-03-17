/// ACP Protocol Models
///
/// This library exports all ACP (Agent Client Protocol) models
/// for the ClawTalk Flutter application.
///
/// ## Message Types
/// - [AcpMessage]: Base sealed class for all messages
/// - [AcpRequest]: Client-to-server requests
/// - [AcpResponse]: Server-to-client responses
/// - [AcpEvent]: Server-pushed events
///
/// ## Content Blocks
/// - [ContentBlock]: Sealed class for content polymorphism
/// - [TextContentBlock]: Text content
/// - [ImageContentBlock]: Image content with Base64 data
/// - [AudioContentBlock]: Audio content with Base64 data
///
/// ## Information Models
/// - [SessionInfo]: Session state and metadata
/// - [AgentInfo]: Agent capabilities and status
/// - [TaskInfo]: Task progress and status
///
/// ## Converters
/// - [MessageConverter]: JSON serialization for messages
/// - [ContentConverter]: JSON serialization for content blocks

// Core message types
export 'acp_message.dart';
export 'acp_request.dart';
export 'acp_response.dart';
export 'acp_event.dart';

// Content blocks
export 'content_block.dart';

// Information models
export 'session_info.dart';
export 'agent_info.dart';
export 'task_info.dart';

// Converters
export 'converters/message_converter.dart';
export 'converters/content_converter.dart';
