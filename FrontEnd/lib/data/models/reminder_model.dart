/// @file reminder_model.dart
/// @description Modelo de serialización de recordatorio para la capa de datos.
/// Solo fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión ReminderModel ↔ Reminder la realiza ReminderMapper.
/// @module Reminders
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// REMINDER MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de recordatorio. Refleja la estructura JSON de la API.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.plantId,
    required this.userId,
    required this.type,
    required this.scheduledDate,
    required this.message,
    required this.isCompleted,
    required this.suspended,
    required this.attempts,
    required this.createdAt,
  });

  final String  id;
  final String  plantId;
  final String  userId;
  final String  type;
  final String  scheduledDate; // ISO 8601 string tal como llega del servidor.
  final String  message;
  final bool    isCompleted;
  final bool    suspended;
  final int     attempts;
  final String  createdAt;     // ISO 8601 string.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id:            json['_id']           as String? ?? json['id'] as String,
    plantId:       json['plantId']       as String,
    userId:        json['userId']        as String,
    type:          json['type']          as String,
    scheduledDate: json['scheduledDate'] as String,
    message:       json['message']       as String,
    isCompleted:   json['isCompleted']   as bool? ?? false,
    suspended:     json['suspended']     as bool? ?? false,
    attempts:      json['attempts']      as int?  ?? 0,
    createdAt:     json['createdAt']     as String,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':            id,
    'plantId':       plantId,
    'userId':        userId,
    'type':          type,
    'scheduledDate': scheduledDate,
    'message':       message,
    'isCompleted':   isCompleted,
    'suspended':     suspended,
    'attempts':      attempts,
    'createdAt':     createdAt,
  };
}
