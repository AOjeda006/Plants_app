/// @file reminder_mapper.dart
/// @description Implementación del mapper de recordatorios.
/// Convierte ReminderModel ↔ Reminder normalizando tipos y fechas.
/// @module Reminders
/// @layer Data
library;

import '../../core/utils/date_utils.dart';
import '../../domain/entities/reminder.dart';
import '../i_mappers/i_reminder_mapper.dart';
import '../models/reminder_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REMINDER MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IReminderMapper].
///
/// [implements] IReminderMapper
/// [injectable] registrar en container.dart como singleton.
class ReminderMapper implements IReminderMapper {

  // ─── ReminderModel → Reminder ─────────────────────────────────────────────────

  @override
  Reminder toEntity(ReminderModel model) {
    return Reminder(
      id:            model.id,
      plantId:       model.plantId,
      userId:        model.userId,
      type:          model.type,
      scheduledDate: PlantDateUtils.parseUtc(model.scheduledDate) ?? DateTime.now().toUtc(),
      message:       model.message,
      isCompleted:   model.isCompleted,
      suspended:     model.suspended,
      attempts:      model.attempts,
      createdAt:     PlantDateUtils.parseUtc(model.createdAt) ?? DateTime.now().toUtc(),
    );
  }

  // ─── Reminder → ReminderModel ─────────────────────────────────────────────────

  @override
  ReminderModel toModel(Reminder entity) {
    return ReminderModel(
      id:            entity.id,
      plantId:       entity.plantId,
      userId:        entity.userId,
      type:          entity.type,
      scheduledDate: PlantDateUtils.toIso8601(entity.scheduledDate),
      message:       entity.message,
      isCompleted:   entity.isCompleted,
      suspended:     entity.suspended,
      attempts:      entity.attempts,
      createdAt:     PlantDateUtils.toIso8601(entity.createdAt),
    );
  }
}
