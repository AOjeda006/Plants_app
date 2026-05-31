/// @file get_user_conversations_use_case.dart
/// @description Implementación del use case que obtiene las conversaciones del usuario.
/// @module Chat
/// @layer Domain
library;

import '../../entities/conversation.dart';
import '../../interfaces/usecases/chat/i_get_conversations_use_case.dart';
import '../../repositories/i_chat_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GET USER CONVERSATIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Obtiene la lista de conversaciones activas del usuario autenticado.
///
/// [implements] IGetConversationsUseCase
/// [injectable] registrar en container.dart como IGetConversationsUseCase.
/// [dependencies] IChatRepository.
class GetUserConversationsUseCase implements IGetConversationsUseCase {
  final IChatRepository _repository;

  const GetUserConversationsUseCase({required IChatRepository repository})
      : _repository = repository;

  /// Devuelve las conversaciones activas, ordenadas por último mensaje.
  ///
  /// [param] forceRefresh — propagado al repositorio para saltar la caché
  ///         tras recibir `message:received` por socket.
  /// [returns] lista de [Conversation].
  /// [throws] AppError — si la carga falla.
  @override
  Future<List<Conversation>> execute({bool forceRefresh = false}) =>
      _repository.getConversations(forceRefresh: forceRefresh);
}
