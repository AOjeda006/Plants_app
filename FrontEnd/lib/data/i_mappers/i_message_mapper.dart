/// @file i_message_mapper.dart
/// @description Interfaz del mapper de mensajes de chat. Contrato tipado Model ↔ Entity.
/// @module Chat
/// @layer Data
library;

import '../../domain/entities/message.dart';
import '../models/message_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I MESSAGE MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato de transformación entre [MessageModel] y [Message].
///
/// Las implementaciones residen en data/mappers/.
/// Los repositorios dependen de esta interfaz, nunca de la implementación concreta.
abstract interface class IMessageMapper {
  /// Convierte un modelo de serialización en una entidad de dominio.
  Message toEntity(MessageModel model);

  /// Convierte una entidad de dominio en un modelo de serialización.
  MessageModel toModel(Message entity);
}
