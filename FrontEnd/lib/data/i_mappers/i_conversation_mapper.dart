/// @file i_conversation_mapper.dart
/// @description Interfaz del mapper de conversaciones de chat. Contrato tipado Model ↔ Entity.
/// @module Chat
/// @layer Data
library;

import '../../domain/entities/conversation.dart';
import '../models/conversation_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I CONVERSATION MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato de transformación entre [ConversationModel] y [Conversation].
///
/// Las implementaciones residen en data/mappers/.
/// Los repositorios dependen de esta interfaz, nunca de la implementación concreta.
abstract interface class IConversationMapper {
  /// Convierte un modelo de serialización en una entidad de dominio.
  Conversation toEntity(ConversationModel model);

  /// Convierte una entidad de dominio en un modelo de serialización.
  ConversationModel toModel(Conversation entity);
}
