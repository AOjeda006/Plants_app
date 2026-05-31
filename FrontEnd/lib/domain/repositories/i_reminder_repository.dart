/// @file i_reminder_repository.dart
/// @description Interfaz del repositorio de recordatorios de cuidado de plantas.
/// Define el contrato que los use cases usan para acceder a los datos.
/// La implementación concreta (ReminderRepositoryImpl) vive en data/.
/// @module Reminders
/// @layer Domain
library;

import '../entities/reminder.dart';

/// Contrato del repositorio de recordatorios.
///
/// Los use cases dependen de esta interfaz, nunca de la implementación concreta.
abstract interface class IReminderRepository {
  // ─── Reminders ────────────────────────────────────────────────────────────────

  /// Devuelve los recordatorios activos (no completados ni suspendidos) del usuario.
  ///
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<List<Reminder>> getActiveReminders();

  /// Marca el recordatorio con [reminderId] como completado.
  ///
  /// [throws] AppError.notFound si el recordatorio no existe o no pertenece al usuario.
  Future<void> markCompleted(String reminderId);
}
