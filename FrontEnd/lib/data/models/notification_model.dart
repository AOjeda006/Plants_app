/// @file notification_model.dart
/// @description Modelo de serialización de notificación in-app para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión NotificationModel ↔ AppNotification la realiza NotificationMapper.
/// @module Reminders
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de notificación in-app. Refleja la estructura JSON de la API.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.reminderId,
    required this.plantId,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String message;
  final String? reminderId;
  final String? plantId;
  final bool   isRead;
  final String createdAt; // ISO 8601 string tal como llega del servidor.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id:         json['_id']        as String? ?? json['id'] as String,
    userId:     json['userId']     as String,
    type:       json['type']       as String,
    message:    json['message']    as String,
    reminderId: json['reminderId'] as String?,
    plantId:    json['plantId']    as String?,
    isRead:     json['isRead']     as bool? ?? false,
    createdAt:  json['createdAt']  as String,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':         id,
    'userId':     userId,
    'type':       type,
    'message':    message,
    'reminderId': reminderId,
    'plantId':    plantId,
    'isRead':     isRead,
    'createdAt':  createdAt,
  };
}
