/// @file conversation_model.dart
/// @description Modelo de serialización de una conversación de chat.
/// Espeja ConversationResponseDTO del backend: aplanamiento de participant,
/// lastMessage y lastMessageAt. SIN lógica de negocio.
/// @module Chat
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CONVERSATION MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización que espeja [ConversationResponseDTO] del backend.
///
/// El campo [participantId/Name/Photo] se extrae del objeto anidado `participant`
/// y se aplana aquí para simplificar el mapeo posterior a la entidad.
class ConversationModel {
  final String   id;
  final String   participantId;
  final String   participantName;
  final String?  participantPhoto;

  /// Texto del último mensaje (extraído de lastMessage.text si existe).
  final String?  lastMessageText;

  /// Timestamp ISO-8601 del último mensaje.
  final String?  lastMessageAt;

  final int      unreadCount;
  final String   createdAt;

  /// true cuando el otro participante ha eliminado su cuenta.
  final bool     isParticipantDeleted;

  const ConversationModel({
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

  /// Deserializa desde JSON (ConversationResponseDTO del backend).
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    // Extraer datos del participante anidado.
    final participantMap = json['participant'] as Map<String, dynamic>? ?? {};

    // Extraer texto del último mensaje si existe.
    final lastMsgMap    = json['lastMessage'] as Map<String, dynamic>?;
    final lastMsgText   = lastMsgMap?['text'] as String?;

    return ConversationModel(
      id:              json['id']            as String? ?? '',
      participantId:   participantMap['id']  as String? ?? '',
      participantName: participantMap['name'] as String? ?? '',
      participantPhoto: participantMap['photo'] as String?,
      lastMessageText: lastMsgText,
      lastMessageAt:   json['lastMessageAt'] as String?,
      unreadCount:          json['unreadCount']          as int?  ?? 0,
      createdAt:            json['createdAt']            as String? ?? '',
      isParticipantDeleted: json['isParticipantDeleted'] as bool? ?? false,
    );
  }

  /// Serializa a JSON (para caché local).
  Map<String, dynamic> toJson() => {
    'id':          id,
    'participant': {
      'id':    participantId,
      'name':  participantName,
      if (participantPhoto != null) 'photo': participantPhoto,
    },
    if (lastMessageText != null) 'lastMessage': {'text': lastMessageText},
    if (lastMessageAt   != null) 'lastMessageAt': lastMessageAt,
    'unreadCount':          unreadCount,
    'createdAt':            createdAt,
    'isParticipantDeleted': isParticipantDeleted,
  };
}
