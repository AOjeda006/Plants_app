/// @file message_mapper.dart
/// @description Implementación del mapper que transforma MessageModel ↔ Message.
/// @module Chat
/// @layer Data
library;

import '../../domain/entities/message.dart';
import '../i_mappers/i_message_mapper.dart';
import '../models/message_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Convierte entre [MessageModel] (serialización JSON) y [Message] (entidad de dominio).
///
/// [implements] IMessageMapper
/// [injectable] registrar en container.dart como IMessageMapper.
class MessageMapper implements IMessageMapper {
  const MessageMapper();

  /// Convierte un [MessageModel] deserializado del JSON de backend en [Message].
  ///
  /// El campo status se mapea del String ('pending'|'delivered'|'read') al enum [MessageStatus].
  ///
  /// [param] model — modelo de serialización del mensaje.
  /// [returns] entidad de dominio limpia.
  @override
  Message toEntity(MessageModel model) {
    return Message(
      id:             model.id,
      conversationId: model.conversationId,
      senderId:       model.senderId,
      senderName:     model.senderName,
      text:           model.text,
      status:         _parseStatus(model.status),
      tempId:         model.tempId,
      createdAt:      DateTime.parse(model.createdAt).toUtc(),
    );
  }

  /// Convierte una [Message] de dominio en [MessageModel] (para caché o cola offline).
  ///
  /// [param] entity — entidad de dominio del mensaje.
  /// [returns] modelo de serialización.
  @override
  MessageModel toModel(Message entity) {
    return MessageModel(
      id:             entity.id,
      conversationId: entity.conversationId,
      senderId:       entity.senderId,
      senderName:     entity.senderName,
      text:           entity.text,
      status:         entity.status.name,
      tempId:         entity.tempId,
      createdAt:      entity.createdAt.toIso8601String(),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Convierte un String de estado en el enum [MessageStatus].
  ///
  /// [param] raw — String del backend ('pending', 'sent', 'delivered', 'read').
  /// [returns] enum correspondiente; 'sent' por defecto si es desconocido.
  MessageStatus _parseStatus(String raw) {
    switch (raw) {
      case 'pending':
        return MessageStatus.pending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
}
