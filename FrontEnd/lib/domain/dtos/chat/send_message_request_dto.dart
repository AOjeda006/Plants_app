/// @file send_message_request_dto.dart
/// @description DTO de envío de mensaje en una conversación de chat.
/// El conversationId va en la ruta URL, no en el body.
/// @module Chat
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// SEND MESSAGE REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO que representa el body de una petición de envío de mensaje.
class SendMessageRequestDto {
  /// Contenido textual del mensaje.
  final String  content;

  /// ID temporal del cliente para reconciliación optimista (opcional).
  final String? tempId;

  const SendMessageRequestDto({required this.content, this.tempId});

  /// Serializa el DTO a JSON para la petición HTTP.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'text':   content,
    'tempId': tempId,
  }..removeWhere((_, v) => v == null);
}
