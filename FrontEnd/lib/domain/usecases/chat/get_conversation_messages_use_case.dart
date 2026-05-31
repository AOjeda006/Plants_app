/// @file get_conversation_messages_use_case.dart
/// @description Implementación del use case que obtiene los mensajes de una conversación.
/// @module Chat
/// @layer Domain
library;

import '../../entities/message.dart';
import '../../interfaces/usecases/chat/i_get_messages_use_case.dart';
import '../../repositories/i_chat_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET CONVERSATION MESSAGES USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene los mensajes paginados de una conversación de chat.
///
/// [implements] IGetMessagesUseCase
/// [injectable] registrar en container.dart como IGetMessagesUseCase.
/// [dependencies] IChatRepository.
class GetConversationMessagesUseCase implements IGetMessagesUseCase {
  final IChatRepository _repository;

  const GetConversationMessagesUseCase({required IChatRepository repository})
      : _repository = repository;

  /// Devuelve los mensajes de [conversationId] en orden cronológico ascendente.
  ///
  /// [param] conversationId — ID de la conversación.
  /// [param] page  — número de página (1-based). Por defecto 1.
  /// [param] limit — mensajes por página. Por defecto 30.
  /// [returns] lista de [Message].
  /// [throws] AppError — si la carga falla.
  @override
  Future<List<Message>> execute(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  }) =>
      _repository.getMessages(conversationId, page: page, limit: limit);
}
