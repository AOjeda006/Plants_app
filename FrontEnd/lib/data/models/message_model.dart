/// @file message_model.dart
/// @description Modelo de serialización de un mensaje de chat.
/// Espeja MessageResponseDTO del backend. SIN lógica de negocio.
/// @module Chat
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización que espeja [MessageResponseDTO] del backend.
///
/// El status se almacena como String ('pending'|'delivered'|'read') para
/// evitar dependencias de la capa Data hacia enums del dominio.
class MessageModel {
  final String  id;
  final String  conversationId;
  final String  senderId;
  final String  senderName;
  final String? text;

  /// Estado de entrega: 'pending' | 'delivered' | 'read'.
  final String  status;

  /// ID temporal para reconciliación optimista (puede ser null).
  final String? tempId;

  final String  createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.text,
    required this.status,
    this.tempId,
    required this.createdAt,
  });

  /// Deserializa desde JSON (MessageResponseDTO del backend).
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id:             json['id']             as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId:       json['senderId']       as String? ?? '',
      senderName:     json['senderName']     as String? ?? '',
      text:           json['text']           as String?,
      status:         json['status']         as String? ?? 'delivered',
      tempId:         json['tempId']         as String?,
      createdAt:      json['createdAt']      as String? ?? '',
    );
  }

  /// Serializa a JSON (para caché local o cola offline).
  Map<String, dynamic> toJson() => {
    'id':             id,
    'conversationId': conversationId,
    'senderId':       senderId,
    'senderName':     senderName,
    if (text     != null) 'text':   text,
    'status':         status,
    if (tempId   != null) 'tempId': tempId,
    'createdAt':      createdAt,
  };
}
