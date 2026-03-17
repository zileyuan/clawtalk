import 'package:freezed_annotation/freezed_annotation.dart';

import 'acp_message.dart';
import 'content_block.dart';

part 'acp_request.freezed.dart';
part 'acp_request.g.dart';

/// ACP Request message type
/// 
/// Request messages are sent from client to server with an ID for correlation.
/// The [method] field specifies the action to perform.
/// The [params] field contains method-specific parameters.
@freezed
class AcpRequest extends AcpMessage with _$AcpRequest {
  const AcpRequest._();

  const factory AcpRequest({
    /// Unique request ID for correlation with response
    required String id,
    
    /// Method name to invoke
    required String method,
    
    /// Method-specific parameters
    required Map<String, dynamic> params,
  }) = _AcpRequest;

  @override
  AcpMessageType get messageType => AcpMessageType.request;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'req',
        'id': id,
        'method': method,
        'params': params,
      };

  factory AcpRequest.fromJson(Map<String, dynamic> json) => AcpRequest(
        id: json['id'] as String,
        method: json['method'] as String,
        params: json['params'] as Map<String, dynamic>,
      );
}

// ============================================================================
// Request-specific parameter models
// ============================================================================

/// Client information for initialize request
@freezed
class ClientInfo with _$ClientInfo {
  const factory ClientInfo({
    required String id,
    required String name,
    required String version,
    required String platform,
    @Default('client') String mode,
  }) = _ClientInfo;

  factory ClientInfo.fromJson(Map<String, dynamic> json) =>
      _$ClientInfoFromJson(json);
}

/// Initialize request parameters
@freezed
class InitializeParams with _$InitializeParams {
  const factory InitializeParams({
    @Default(3) int minProtocol,
    @Default(3) int maxProtocol,
    required ClientInfo clientInfo,
    @Default({}) Map<String, dynamic> capabilities,
  }) = _InitializeParams;

  factory InitializeParams.fromJson(Map<String, dynamic> json) =>
      _$InitializeParamsFromJson(json);
}

/// Create session request parameters
@freezed
class CreateSessionParams with _$CreateSessionParams {
  const factory CreateSessionParams({
    String? cwd,
    Map<String, dynamic>? meta,
    String? agentId,
  }) = _CreateSessionParams;

  factory CreateSessionParams.fromJson(Map<String, dynamic> json) =>
      _$CreateSessionParamsFromJson(json);
}

/// Prompt attachment for sendMessage
@freezed
class PromptAttachment with _$PromptAttachment {
  const factory PromptAttachment({
    required String type,
    required String mimeType,
    required String data,
    int? width,
    int? height,
    int? duration,
  }) = _PromptAttachment;

  factory PromptAttachment.fromJson(Map<String, dynamic> json) =>
      _$PromptAttachmentFromJson(json);

  /// Create from ContentBlock
  factory PromptAttachment.fromContentBlock(ContentBlock block) {
    return switch (block) {
      TextContentBlock(:final text) => PromptAttachment(
          type: 'text',
          mimeType: 'text/plain',
          data: text,
        ),
      ImageContentBlock(:final mimeType, :final data, :final width, :final height) =>
          PromptAttachment(
            type: 'image',
            mimeType: mimeType,
            data: data,
            width: width,
            height: height,
          ),
      AudioContentBlock(:final mimeType, :final data, :final duration) =>
          PromptAttachment(
            type: 'audio',
            mimeType: mimeType,
            data: data,
            duration: duration,
          ),
    };
  }
}

/// Prompt content for sendMessage request
@freezed
class PromptContent with _$PromptContent {
  const factory PromptContent({
    required String text,
    @Default([]) List<PromptAttachment> attachments,
  }) = _PromptContent;

  factory PromptContent.fromJson(Map<String, dynamic> json) =>
      _$PromptContentFromJson(json);
}

/// Send message (prompt) request parameters
@freezed
class SendMessageParams with _$SendMessageParams {
  const factory SendMessageParams({
    required String sessionId,
    required PromptContent prompt,
  }) = _SendMessageParams;

  factory SendMessageParams.fromJson(Map<String, dynamic> json) =>
      _$SendMessageParamsFromJson(json);
}

/// End session request parameters
@freezed
class EndSessionParams with _$EndSessionParams {
  const factory EndSessionParams({
    required String sessionId,
  }) = _EndSessionParams;

  factory EndSessionParams.fromJson(Map<String, dynamic> json) =>
      _$EndSessionParamsFromJson(json);
}

/// Cancel task request parameters
@freezed
class CancelTaskParams with _$CancelTaskParams {
  const factory CancelTaskParams({
    required String sessionId,
    String? taskId,
  }) = _CancelTaskParams;

  factory CancelTaskParams.fromJson(Map<String, dynamic> json) =>
      _$CancelTaskParamsFromJson(json);
}

/// Get agents request parameters (empty, but defined for consistency)
@freezed
class GetAgentsParams with _$GetAgentsParams {
  const factory GetAgentsParams() = _GetAgentsParams;

  factory GetAgentsParams.fromJson(Map<String, dynamic> json) =>
      _$GetAgentsParamsFromJson(json);
}

// ============================================================================
// Request factory methods
// ============================================================================

/// Factory for creating ACP requests
class AcpRequestFactory {
  AcpRequestFactory._();

  /// Generate a unique request ID
  static String generateId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Create initialize request
  static AcpRequest initialize({
    required String clientId,
    required String clientName,
    required String version,
    required String platform,
    int minProtocol = 3,
    int maxProtocol = 3,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'initialize',
      params: InitializeParams(
        minProtocol: minProtocol,
        maxProtocol: maxProtocol,
        clientInfo: ClientInfo(
          id: clientId,
          name: clientName,
          version: version,
          platform: platform,
        ),
      ).toJson(),
    );
  }

  /// Create new session request
  static AcpRequest createSession({
    String? cwd,
    Map<String, dynamic>? meta,
    String? agentId,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'newSession',
      params: CreateSessionParams(
        cwd: cwd,
        meta: meta,
        agentId: agentId,
      ).toJson(),
    );
  }

  /// Create send message (prompt) request
  static AcpRequest sendMessage({
    required String sessionId,
    required String text,
    List<PromptAttachment> attachments = const [],
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'prompt',
      params: SendMessageParams(
        sessionId: sessionId,
        prompt: PromptContent(text: text, attachments: attachments),
      ).toJson(),
    );
  }

  /// Create end session request
  static AcpRequest endSession({
    required String sessionId,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'endSession',
      params: EndSessionParams(sessionId: sessionId).toJson(),
    );
  }

  /// Create cancel task request
  static AcpRequest cancelTask({
    required String sessionId,
    String? taskId,
  }) {
    return AcpRequest(
      id: generateId(),
      method: 'cancel',
      params: CancelTaskParams(sessionId: sessionId, taskId: taskId).toJson(),
    );
  }

  /// Create get agents request
  static AcpRequest getAgents() {
    return AcpRequest(
      id: generateId(),
      method: 'listAgents',
      params: const GetAgentsParams().toJson(),
    );
  }

  /// Create list sessions request
  static AcpRequest listSessions({int? limit}) {
    return AcpRequest(
      id: generateId(),
      method: 'listSessions',
      params: {'_meta': if (limit != null) {'limit': limit}},
    );
  }
}