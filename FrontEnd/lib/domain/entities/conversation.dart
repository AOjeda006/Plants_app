/// @file conversation.dart
/// @description Entidad de dominio que representa una conversación privada 1:1.
/// Contiene los datos del otro participante aplanados para facilitar la UI.
/// @module Chat
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio de una conversación privada entre dos usuarios.
///
/// Los datos del otro participante (nombre, foto) se incluyen aplanados
/// desde el backend (enriquecimiento N+1 aceptado para TFG).
class Conversation {
  /// Identificador único de la conversación.
  final String   id;

  /// ID del otro usuario participante.
  final String   participantId;

  /// Nombre del otro usuario participante.
  final String   participantName;

  /// URL de la foto de perfil del otro usuario (opcional).
  final String?  participantPhoto;

  /// Texto del último mensaje enviado en la conversación (opcional).
  final String?  lastMessageText;

  /// Marca de tiempo del último mensaje (opcional).
  final DateTime? lastMessageAt;

  /// Número de mensajes no leídos por el usuario actual.
  final int      unreadCount;

  /// Fecha de creación de la conversación.
  final DateTime createdAt;

  /// true cuando el otro participante ha eliminado su cuenta.
  /// La conversación es de solo lectura: se pueden leer mensajes pero no enviar nuevos.
  final bool isParticipantDeleted;

  const Conversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    this.participantPhoto,
    this.lastMessageText,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
    this.isParticipantDeleted = false,
  });

  // ─── Computed ─────────────────────────────────────────────────────────────

  /// true si hay mensajes no leídos en esta conversación.
  bool get hasUnread => unreadCount > 0;

  /// true si existe preview de último mensaje.
  bool get hasLastMessage => lastMessageText != null && lastMessageText!.isNotEmpty;

  /// true si el otro participante tiene foto de perfil.
  bool get hasParticipantPhoto => participantPhoto != null;

  // ─── copyWith ─────────────────────────────────────────────────────────────

  /// Devuelve una copia con los campos indicados modificados.
  ///
  /// Útil para actualizar el contador de no leídos o el último mensaje
  /// tras recibir un evento de socket sin recargar desde la API.
  Conversation copyWith({
    String?   participantName,
    String?   participantPhoto,
    String?   lastMessageText,
    DateTime? lastMessageAt,
    int?      unreadCount,
  }) =>
      Conversation(
        id:                   id,
        participantId:        participantId,
        participantName:      participantName  ?? this.participantName,
        participantPhoto:     participantPhoto ?? this.participantPhoto,
        lastMessageText:      lastMessageText  ?? this.lastMessageText,
        lastMessageAt:        lastMessageAt    ?? this.lastMessageAt,
        unreadCount:          unreadCount      ?? this.unreadCount,
        createdAt:            createdAt,
        isParticipantDeleted: isParticipantDeleted,
      );
}
