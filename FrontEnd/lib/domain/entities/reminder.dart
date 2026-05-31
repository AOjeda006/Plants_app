/// @file reminder.dart
/// @description Entidad de dominio Reminder. Representa un recordatorio de cuidado de planta.
/// Objeto puro de Dart, sin dependencias de Flutter ni paquetes externos.
/// Los mappers convierten ReminderModel ↔ Reminder.
/// @module Reminders
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// REMINDER ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa un recordatorio de cuidado de planta.
///
/// Todos los campos son inmutables (final). Usar [copyWith] para actualizaciones.
class Reminder {
  const Reminder({
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

  /// Identificador único del recordatorio (MongoDB ObjectId como String).
  final String id;

  /// ID de la planta asociada al recordatorio.
  final String plantId;

  /// ID del usuario propietario.
  final String userId;

  /// Tipo de recordatorio: 'watering', 'fertilizing', 'pruning', 'repotting', 'other'.
  final String type;

  /// Fecha y hora programada para el recordatorio (UTC).
  final DateTime scheduledDate;

  /// Mensaje descriptivo del recordatorio (p.ej. "Regar la planta").
  final String message;

  /// true si el recordatorio ha sido completado por el usuario.
  final bool isCompleted;

  /// true si el recordatorio está suspendido (p.ej. por el ajuste climático).
  final bool suspended;

  /// Número de intentos de procesamiento realizados por el cron job.
  final int attempts;

  /// Fecha de creación del recordatorio.
  final DateTime createdAt;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si el recordatorio está pendiente de procesar (no completado ni suspendido).
  bool get isPending => !isCompleted && !suspended;

  /// true si el recordatorio es de tipo riego.
  bool get isWatering => type == 'watering';

  /// true si el recordatorio está vencido (scheduledDate en el pasado y aún pendiente).
  bool get isOverdue =>
      isPending && scheduledDate.isBefore(DateTime.now().toUtc());

  // ─── copyWith ────────────────────────────────────────────────────────────────

  Reminder copyWith({
    String?   id,
    String?   plantId,
    String?   userId,
    String?   type,
    DateTime? scheduledDate,
    String?   message,
    bool?     isCompleted,
    bool?     suspended,
    int?      attempts,
    DateTime? createdAt,
  }) {
    return Reminder(
      id:            id            ?? this.id,
      plantId:       plantId       ?? this.plantId,
      userId:        userId        ?? this.userId,
      type:          type          ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      message:       message       ?? this.message,
      isCompleted:   isCompleted   ?? this.isCompleted,
      suspended:     suspended     ?? this.suspended,
      attempts:      attempts      ?? this.attempts,
      createdAt:     createdAt     ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Reminder && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Reminder(id: $id, type: $type, plantId: $plantId, isPending: $isPending)';
}
