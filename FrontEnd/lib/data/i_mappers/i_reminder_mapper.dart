/// @file i_reminder_mapper.dart
/// @description Interfaz del mapper de recordatorios. Contrato ReminderModel ↔ Reminder.
/// @module Reminders
/// @layer Data
library;

import '../../domain/entities/reminder.dart';
import '../models/reminder_model.dart';

/// Contrato de conversión entre el modelo de serialización y la entidad de dominio.
///
/// [injectable] registrar en container.dart como singleton.
abstract interface class IReminderMapper {
  /// Convierte un modelo de serialización a entidad de dominio.
  Reminder toEntity(ReminderModel model);

  /// Convierte una entidad de dominio a modelo de serialización.
  ReminderModel toModel(Reminder entity);
}
