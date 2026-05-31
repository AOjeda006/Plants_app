/// @file i_get_messages_use_case.dart
/// @description Interfaz: Obtiene los mensajes paginados de una conversación.
/// @module Chat
/// @layer Domain
library;

import '../../../entities/message.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I GET MESSAGES USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del use case que recupera mensajes de una conversación con paginación.
abstract interface class IGetMessagesUseCase {
  /// Devuelve los mensajes de [conversationId], paginados.
  ///
  /// [param] conversationId — ID de la conversación.
  /// [param] page  — número de página (1-based). Por defecto 1.
  /// [param] limit — mensajes por página. Por defecto 30.
  /// [returns] lista de [Message] en orden cronológico ascendente.
  /// [throws] AppError — si la carga falla.
  Future<List<Message>> execute(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  });
}
