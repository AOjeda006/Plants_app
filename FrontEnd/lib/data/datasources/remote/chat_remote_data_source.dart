/// @file chat_remote_data_source.dart
/// @description DataSource remoto del módulo de chat. Encapsula las llamadas
/// HTTP a los endpoints /chat del backend (conversaciones y mensajes).
/// @module Chat
/// @layer Data
library;

import '../../../core/network/api_client.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Acceso a la API REST del chat: conversaciones y mensajes.
///
/// Todas las llamadas propagan [AppError] en caso de fallo; el repositorio
/// decide si encolar offline o relanzar el error.
///
/// [injectable] registrar en container.dart como ChatRemoteDataSource.
/// [dependencies] ApiClient.
class ChatRemoteDataSource {
  final ApiClient _api;

  const ChatRemoteDataSource({required ApiClient apiClient}) : _api = apiClient;

  // ─── Conversaciones ────────────────────────────────────────────────────────

  /// Obtiene todas las conversaciones activas del usuario autenticado.
  ///
  /// GET /chat
  ///
  /// [returns] lista de [ConversationModel] enriquecidas con datos de participante.
  /// [throws] AppError — si la petición falla.
  Future<List<ConversationModel>> getConversations() async {
    final response = await _api.get<List<dynamic>>('/chat');
    return response
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Obtiene o crea una conversación 1:1 con el usuario indicado.
  ///
  /// POST /chat  {participantId}
  ///
  /// [param] participantId — ID del otro usuario con quien iniciar la conversación.
  /// [returns] [ConversationModel] de la conversación existente o recién creada.
  /// [throws] AppError — si la petición falla.
  Future<ConversationModel> getOrCreateConversation(String participantId) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/chat',
      data: {'participantId': participantId},
    );
    return ConversationModel.fromJson(response);
  }

  // ─── Mensajes ──────────────────────────────────────────────────────────────

  /// Obtiene los mensajes paginados de una conversación.
  ///
  /// GET /chat/:conversationId/messages?page=X&limit=Y
  ///
  /// [param] conversationId — ID de la conversación.
  /// [param] page — número de página (1-based). Por defecto 1.
  /// [param] limit — mensajes por página. Por defecto 30.
  /// [returns] lista de [MessageModel] en orden cronológico ascendente.
  /// [throws] AppError — si la petición falla.
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  }) async {
    final response = await _api.get<List<dynamic>>(
      '/chat/$conversationId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );
    return response
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Envía un mensaje de texto en una conversación.
  ///
  /// POST /chat/:conversationId/messages  {text, tempId?}
  ///
  /// [param] conversationId — ID de la conversación destino.
  /// [param] text — contenido textual del mensaje.
  /// [param] tempId — ID temporal para reconciliación optimista (opcional).
  /// [returns] [MessageModel] con el ID real asignado por el backend.
  /// [throws] AppError — si la petición falla.
  Future<MessageModel> sendMessage(
    String conversationId,
    String text, {
    String? tempId,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/chat/$conversationId/messages',
      data: <String, dynamic>{
        'text':   text,
        'tempId': tempId,
      }..removeWhere((_, v) => v == null),
    );
    return MessageModel.fromJson(response);
  }

  /// Marca todos los mensajes no leídos de la conversación como leídos.
  ///
  /// POST /chat/:conversationId/read
  ///
  /// [param] conversationId — ID de la conversación a marcar.
  /// [throws] AppError — si la petición falla.
  Future<void> markMessagesAsRead(String conversationId) async {
    await _api.post<void>('/chat/$conversationId/read');
  }
}
