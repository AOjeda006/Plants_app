/// @file i_chat_repository.dart
/// @description Interfaz del repositorio de chat. Define el contrato de acceso
/// a conversaciones y mensajes sin acoplar a la implementación concreta.
/// @module Chat
/// @layer Domain
library;

import '../entities/conversation.dart';
import '../entities/message.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I CHAT REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato de acceso a datos del módulo de chat.
///
/// La implementación concreta [ChatRepositoryImpl] en data/ aplica:
///  - Cache-first para conversaciones (TTL corto).
///  - Sin caché para mensajes (siempre frescos).
///  - Cola offline para mutaciones cuando no hay red.
abstract interface class IChatRepository {
  /// Obtiene todas las conversaciones activas del usuario autenticado.
  ///
  /// [param] forceRefresh — si true, salta la caché local (TTL 1 min) y
  ///         consulta directamente la API. Útil cuando recibimos un evento
  ///         `message:received` por socket y necesitamos reflejarlo en la
  ///         lista de inmediato.
  /// [returns] lista de [Conversation] ordenadas por último mensaje (más reciente primero).
  /// [throws] AppError — si la petición falla y no hay caché disponible.
  Future<List<Conversation>> getConversations({bool forceRefresh = false});

  /// Obtiene o crea una conversación 1:1 con el usuario indicado.
  ///
  /// [param] otherUserId — ID del usuario con quien iniciar la conversación.
  /// [returns] [Conversation] existente o recién creada.
  /// [throws] AppError — si la petición falla.
  Future<Conversation> getOrCreateConversation(String otherUserId);

  /// Obtiene los mensajes paginados de una conversación.
  ///
  /// [param] conversationId — ID de la conversación.
  /// [param] page  — número de página (1-based). Por defecto 1.
  /// [param] limit — mensajes por página. Por defecto 30.
  /// [returns] lista de [Message] en orden cronológico ascendente.
  /// [throws] AppError — si la petición falla.
  Future<List<Message>> getMessages(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  });

  /// Envía un mensaje de texto en una conversación.
  ///
  /// Si no hay conexión, encola la acción en [OfflineActionsStore] y devuelve
  /// un [Message] optimista con estado [MessageStatus.pending].
  ///
  /// [param] conversationId — ID de la conversación destino.
  /// [param] text  — contenido textual del mensaje.
  /// [param] tempId — ID temporal del cliente para reconciliación optimista.
  /// [returns] [Message] con el ID real asignado por el backend (o con tempId si offline).
  /// [throws] AppError — si la petición falla por error distinto a red.
  Future<Message> sendMessage(
    String conversationId,
    String text, {
    String? tempId,
  });

  /// Marca todos los mensajes no leídos de la conversación como leídos.
  ///
  /// Operación fire-and-forget: si falla, se encola para reintentar.
  ///
  /// [param] conversationId — ID de la conversación a marcar.
  /// [throws] AppError — si la petición falla por error distinto a red.
  Future<void> markMessagesAsRead(String conversationId);
}
