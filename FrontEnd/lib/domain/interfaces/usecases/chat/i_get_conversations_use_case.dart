/// @file i_get_conversations_use_case.dart
/// @description Interfaz: Obtiene las conversaciones del usuario autenticado.
/// @module Chat
/// @layer Domain
library;

import '../../../entities/conversation.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I GET CONVERSATIONS USE CASE
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del use case que recupera la lista de conversaciones activas.
abstract interface class IGetConversationsUseCase {
  /// Devuelve las conversaciones activas del usuario, ordenadas por último mensaje.
  ///
  /// [param] forceRefresh — si true, salta la caché local (TTL 1 min) y
  ///         consulta directamente la API. Usado al recibir `message:received`
  ///         por socket para reflejar el nuevo unreadCount al instante.
  /// [returns] lista de [Conversation].
  /// [throws] AppError — si la carga falla.
  Future<List<Conversation>> execute({bool forceRefresh = false});
}
