/// @file i_send_message_use_case.dart
/// @description Interfaz: Envía un mensaje en una conversación con soporte optimista.
/// @module Chat
/// @layer Domain
library;

import '../../../entities/message.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I SEND MESSAGE USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del use case que envía un mensaje en una conversación.
///
/// Soporta actualizaciones optimistas mediante [tempId]: el cliente asigna
/// un ID temporal antes de enviar y lo usa para reconciliar el mensaje
/// cuando llega la confirmación del servidor.
abstract interface class ISendMessageUseCase {
  /// Envía [content] en [conversationId].
  ///
  /// [param] conversationId — ID de la conversación destino.
  /// [param] content — texto del mensaje.
  /// [param] tempId — ID temporal del cliente para reconciliación optimista (opcional).
  /// [returns] [Message] confirmado (o con [MessageStatus.pending] si offline).
  /// [throws] AppError — si el envío falla por error distinto a red.
  Future<Message> execute(
    String conversationId,
    String content, {
    String? tempId,
  });
}
