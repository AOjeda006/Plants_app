/// @file message.dart
/// @description Entidad de dominio que representa un mensaje de chat.
/// Incluye soporte para actualizaciones optimistas mediante tempId.
/// @module Chat
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE STATUS
// ═══════════════════════════════════════════════════════════════════════════════

/// Estado de entrega de un mensaje a lo largo de su ciclo de vida.
enum MessageStatus {
  /// Enviado localmente, pendiente de confirmación del servidor.
  pending,

  /// Recibido por el servidor (persistido en BD, POST → 201).
  sent,

  /// Entregado al destinatario (recibido vía Socket).
  delivered,

  /// Leído por el destinatario (PUT /chat/:id/read).
  read,
}

// ═══════════════════════════════════════════════════════════════════════════════
// MESSAGE
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio de un mensaje de chat.
///
/// El campo [tempId] se asigna en el cliente antes de enviar el mensaje y
/// permite reconciliar actualizaciones optimistas cuando llega la confirmación
/// del servidor (real [id] + estado [delivered]).
class Message {
  /// Identificador único del mensaje (puede ser el tempId mientras es [pending]).
  final String        id;

  /// ID de la conversación a la que pertenece este mensaje.
  final String        conversationId;

  /// ID del usuario que envió el mensaje.
  final String        senderId;

  /// Nombre del usuario que envió el mensaje (enriquecido por el backend).
  final String        senderName;

  /// Contenido textual del mensaje (null en mensajes solo-media).
  final String?       text;

  /// Estado de entrega del mensaje.
  final MessageStatus status;

  /// ID temporal asignado por el cliente para actualizaciones optimistas.
  /// Presente hasta que el servidor confirma el mensaje con su ID real.
  final String?       tempId;

  /// Marca de tiempo de creación del mensaje.
  final DateTime      createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.text,
    required this.status,
    this.tempId,
    required this.createdAt,
  });

  // ─── Computed ─────────────────────────────────────────────────────────────

  /// true si el mensaje está pendiente de confirmación del servidor.
  bool get isPending   => status == MessageStatus.pending;

  /// true si el mensaje ha sido recibido por el servidor.
  bool get isSent      => status == MessageStatus.sent;

  /// true si el mensaje ha sido entregado al destinatario.
  bool get isDelivered => status == MessageStatus.delivered;

  /// true si el mensaje ha sido leído por el destinatario.
  bool get isRead      => status == MessageStatus.read;

  /// true si el mensaje tiene contenido de texto.
  bool get hasText     => text != null && text!.isNotEmpty;

  // ─── copyWith ─────────────────────────────────────────────────────────────

  /// Devuelve una copia con los campos indicados modificados.
  ///
  /// Usado principalmente para reconciliar el tempId con el ID real
  /// y actualizar el estado cuando llega el ack del servidor.
  Message copyWith({
    String?        id,
    MessageStatus? status,
    String?        text,
  }) =>
      Message(
        id:             id             ?? this.id,
        conversationId: conversationId,
        senderId:       senderId,
        senderName:     senderName,
        text:           text           ?? this.text,
        status:         status         ?? this.status,
        tempId:         tempId,
        createdAt:      createdAt,
      );
}
