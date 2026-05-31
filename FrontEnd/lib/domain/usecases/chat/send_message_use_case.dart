/// @file send_message_use_case.dart
/// @description Implementación del use case que envía un mensaje en una conversación.
/// @module Chat
/// @layer Domain
library;

import '../../entities/message.dart';
import '../../interfaces/usecases/chat/i_send_message_use_case.dart';
import '../../repositories/i_chat_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SEND MESSAGE USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Envía un mensaje de texto en una conversación con soporte para tempId optimista.
///
/// [implements] ISendMessageUseCase
/// [injectable] registrar en container.dart como ISendMessageUseCase.
/// [dependencies] IChatRepository.
class SendMessageUseCase implements ISendMessageUseCase {
  final IChatRepository _repository;

  const SendMessageUseCase({required IChatRepository repository})
      : _repository = repository;

  /// Envía [content] en [conversationId].
  ///
  /// El [tempId] permite al ViewModel reconciliar el mensaje optimista
  /// con la respuesta real del servidor.
  ///
  /// [param] conversationId — ID de la conversación destino.
  /// [param] content — texto del mensaje.
  /// [param] tempId — ID temporal del cliente (opcional).
  /// [returns] [Message] confirmado (o con [MessageStatus.pending] si offline).
  /// [throws] AppError — si el envío falla por error distinto a red.
  @override
  Future<Message> execute(
    String conversationId,
    String content, {
    String? tempId,
  }) =>
      _repository.sendMessage(conversationId, content, tempId: tempId);
}
