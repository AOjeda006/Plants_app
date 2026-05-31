/// @file create_conversation_use_case.dart
/// @description Implementación del use case que crea o recupera una conversación 1:1.
/// @module Chat
/// @layer Domain
library;

import '../../entities/conversation.dart';
import '../../interfaces/usecases/chat/i_create_conversation_use_case.dart';
import '../../repositories/i_chat_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CREATE CONVERSATION USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene o crea idempotentemente una conversación 1:1 con otro usuario.
///
/// [implements] ICreateConversationUseCase
/// [injectable] registrar en container.dart como ICreateConversationUseCase.
/// [dependencies] IChatRepository.
class CreateConversationUseCase implements ICreateConversationUseCase {
  final IChatRepository _repository;

  const CreateConversationUseCase({required IChatRepository repository})
      : _repository = repository;

  /// Devuelve la conversación existente con [otherUserId], o la crea si no existe.
  ///
  /// [param] otherUserId — ID del otro participante.
  /// [returns] [Conversation] existente o recién creada.
  /// [throws] AppError — si la operación falla.
  @override
  Future<Conversation> execute(String otherUserId) =>
      _repository.getOrCreateConversation(otherUserId);
}
