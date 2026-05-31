/// @file i_create_conversation_use_case.dart
/// @description Interfaz: Crea o recupera una conversación 1:1 con otro usuario.
/// @module Chat
/// @layer Domain
library;

import '../../../entities/conversation.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I CREATE CONVERSATION USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del use case que obtiene o crea una conversación 1:1 idempotentemente.
abstract interface class ICreateConversationUseCase {
  /// Devuelve la conversación existente con [otherUserId], o la crea si no existe.
  ///
  /// [param] otherUserId — ID del otro participante.
  /// [returns] [Conversation] existente o recién creada.
  /// [throws] AppError — si la operación falla.
  Future<Conversation> execute(String otherUserId);
}
