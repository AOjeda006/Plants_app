/// @file mark_messages_as_read_use_case.dart
/// @description Implementación del use case que marca los mensajes como leídos.
/// @module Chat
/// @layer Domain
library;

import '../../interfaces/usecases/chat/i_mark_messages_as_read_use_case.dart';
import '../../repositories/i_chat_repository.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARK MESSAGES AS READ USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Marca todos los mensajes no leídos de una conversación como leídos.
///
/// [implements] IMarkMessagesAsReadUseCase
/// [injectable] registrar en container.dart como IMarkMessagesAsReadUseCase.
/// [dependencies] IChatRepository.
class MarkMessagesAsReadUseCase implements IMarkMessagesAsReadUseCase {
  final IChatRepository _repository;

  const MarkMessagesAsReadUseCase({required IChatRepository repository})
      : _repository = repository;

  /// Marca como leídos todos los mensajes no leídos de [conversationId].
  ///
  /// Fire-and-forget: si falla por red, el repositorio encola el reintento.
  ///
  /// [param] conversationId — ID de la conversación.
  /// [throws] AppError — si falla por error distinto a red.
  @override
  Future<void> execute(String conversationId) =>
      _repository.markMessagesAsRead(conversationId);
}
