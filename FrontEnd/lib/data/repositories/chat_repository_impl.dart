/// @file chat_repository_impl.dart
/// @description Implementación del repositorio de chat. Coordina
/// ChatRemoteDataSource (API) y CacheLocalDataSource (caché breve de
/// conversaciones). Los errores de red propagan al ViewModel/UI — no
/// se encolan acciones offline.
/// @module Chat
/// @layer Data
library;

import '../../core/errors/app_error.dart';
import '../../core/storage/cache_local_data_source.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/i_chat_repository.dart';
import '../datasources/remote/chat_remote_data_source.dart';
import '../i_mappers/i_conversation_mapper.dart';
import '../i_mappers/i_message_mapper.dart';
import '../models/conversation_model.dart';

// ─── Constantes de caché ──────────────────────────────────────────────────────

const String   _kConversationsKey = 'chat_conversations';
const Duration _kConversationsTtl = Duration(minutes: 1);

// ═══════════════════════════════════════════════════════════════════════════════
// CHAT REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de [IChatRepository].
///
/// Estrategia de caché:
///  - Conversaciones: cache-first con TTL muy corto (1 min) para reducir latencia.
///  - Mensajes: sin caché — siempre frescos.
///  - sendMessage / markMessagesAsRead: propagan AppError de red; el
///    caller (ViewModel/UI) lo muestra al usuario.
///
/// [implements] IChatRepository
/// [injectable] registrar en container.dart.
/// [dependencies] ChatRemoteDataSource, CacheLocalDataSource,
///               IConversationMapper, IMessageMapper.
class ChatRepositoryImpl implements IChatRepository {
  final ChatRemoteDataSource _remote;
  final CacheLocalDataSource _cache;
  final IConversationMapper  _conversationMapper;
  final IMessageMapper       _messageMapper;

  const ChatRepositoryImpl({
    required ChatRemoteDataSource remote,
    required CacheLocalDataSource cache,
    required IConversationMapper  conversationMapper,
    required IMessageMapper       messageMapper,
  })  : _remote             = remote,
        _cache              = cache,
        _conversationMapper = conversationMapper,
        _messageMapper      = messageMapper;

  // ─── Get conversations ────────────────────────────────────────────────────────

  @override
  Future<List<Conversation>> getConversations({bool forceRefresh = false}) async {
    // Cache-first (TTL 1 min) salvo que el caller fuerce un refresh —
    // típicamente al recibir `message:received` por socket.
    if (!forceRefresh) {
      final cached = await _cache.get<List<dynamic>>(_kConversationsKey);
      if (cached != null) {
        return cached
            .cast<Map<String, dynamic>>()
            .map((json) => _conversationMapper.toEntity(ConversationModel.fromJson(json)))
            .toList();
      }
    }

    final models = await _remote.getConversations();
    await _cache.set(
      _kConversationsKey,
      models.map((m) => m.toJson()).toList(),
      ttl: _kConversationsTtl,
    );
    return models.map(_conversationMapper.toEntity).toList();
  }

  // ─── Get or create conversation ───────────────────────────────────────────────

  @override
  Future<Conversation> getOrCreateConversation(String otherUserId) async {
    final model = await _remote.getOrCreateConversation(otherUserId);
    // Invalidar caché de conversaciones para reflejar la nueva.
    await _cache.invalidate(_kConversationsKey);
    return _conversationMapper.toEntity(model);
  }

  // ─── Get messages ─────────────────────────────────────────────────────────────

  @override
  Future<List<Message>> getMessages(
    String conversationId, {
    int page  = 1,
    int limit = 30,
  }) async {
    // Los mensajes no se cachean: deben estar siempre actualizados.
    final models = await _remote.getMessages(
      conversationId,
      page:  page,
      limit: limit,
    );
    return models.map(_messageMapper.toEntity).toList();
  }

  // ─── Send message ─────────────────────────────────────────────────────────────

  @override
  Future<Message> sendMessage(
    String conversationId,
    String text, {
    String? tempId,
  }) async {
    // Si falla la red, el AppError se propaga al ChatViewModel — éste
    // muestra el "no se pudo enviar" en la UI y el usuario puede
    // reintentar manualmente.
    final model = await _remote.sendMessage(conversationId, text, tempId: tempId);
    return _messageMapper.toEntity(model);
  }

  // ─── Mark messages as read ────────────────────────────────────────────────────

  @override
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _remote.markMessagesAsRead(conversationId);
      // Invalidar caché de conversaciones para reflejar unreadCount = 0.
      await _cache.invalidate(_kConversationsKey);
    } on AppError {
      // Marcar como leído no es crítico: tolerar errores de red silenciosamente.
      // El siguiente fetch frescode `getConversations` propagará el estado real.
    }
  }
}
