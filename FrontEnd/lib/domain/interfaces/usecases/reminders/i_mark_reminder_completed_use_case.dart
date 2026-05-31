/// @file i_mark_reminder_completed_use_case.dart
/// @description Interfaz del caso de uso para marcar un recordatorio como completado.
/// @module Reminders
/// @layer Domain
library;
abstract interface class IMarkReminderCompletedUseCase {
  /// Marca el recordatorio [reminderId] como completado.
  Future<void> execute(String reminderId);
}
