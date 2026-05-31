/// @file conversation_mapper.dart
/// @description Implementación del mapper que transforma ConversationModel ↔ Conversation.
/// @module Chat
/// @layer Data
library;

import '../../domain/entities/conversation.dart';
import '../i_mappers/i_conversation_mapper.dart';
import '../models/conversation_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Convierte entre [ConversationModel] (serialización JSON) y [Conversation] (entidad de dominio).
///
/// [implements] IConversationMapper
/// [injectable] registrar en container.dart como IConversationMapper.
class ConversationMapper implements IConversationMapper {
  const ConversationMapper();

  /// Convierte un [ConversationModel] deserializado del JSON de backend en [Conversation].
  ///
  /// [param] model — modelo de serialización de la conversación.
  /// [returns] entidad de dominio limpia.
  @override
  Conversation toEntity(ConversationModel model) {
    return Conversation(
      id:                   model.id,
      participantId:        model.participantId,
      participantName:      model.participantName,
      participantPhoto:     model.participantPhoto,
      lastMessageText:      model.lastMessageText,
      lastMessageAt:        model.lastMessageAt != null
          ? DateTime.parse(model.lastMessageAt!).toUtc()
          : null,
      unreadCount:          model.unreadCount,
      createdAt:            DateTime.parse(model.createdAt).toUtc(),
      isParticipantDeleted: model.isParticipantDeleted,
    );
  }

  /// Convierte una [Conversation] de dominio en [ConversationModel] (para caché local).
  ///
  /// [param] entity — entidad de dominio de la conversación.
  /// [returns] modelo de serialización para Hive/SharedPreferences.
  @override
  ConversationModel toModel(Conversation entity) {
    return ConversationModel(
      id:                   entity.id,
      participantId:        entity.participantId,
      participantName:      entity.participantName,
      participantPhoto:     entity.participantPhoto,
      lastMessageText:      entity.lastMessageText,
      lastMessageAt:        entity.lastMessageAt?.toIso8601String(),
      unreadCount:          entity.unreadCount,
      createdAt:            entity.createdAt.toIso8601String(),
      isParticipantDeleted: entity.isParticipantDeleted,
    );
  }
}
