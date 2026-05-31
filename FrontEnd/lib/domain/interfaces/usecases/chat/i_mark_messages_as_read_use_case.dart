/// @file i_mark_messages_as_read_use_case.dart
/// @description Interfaz: Marca como leídos todos los mensajes de una conversación.
/// @module Chat
/// @layer Domain
library;
abstract interface class IMarkMessagesAsReadUseCase {
  /// Marca como leídos todos los mensajes de una conversación.
  Future<void> execute(String conversationId);
}
