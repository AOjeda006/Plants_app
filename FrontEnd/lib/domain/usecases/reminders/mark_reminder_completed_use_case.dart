/// @file mark_reminder_completed_use_case.dart
/// @description Implementación del caso de uso para marcar un recordatorio como completado.
/// @module Reminders
/// @layer Domain
library;

import '../../interfaces/usecases/reminders/i_mark_reminder_completed_use_case.dart';
import '../../repositories/i_reminder_repository.dart';

/// [implements] IMarkReminderCompletedUseCase
/// [dependencies] IReminderRepository
class MarkReminderCompletedUseCase implements IMarkReminderCompletedUseCase {
  final IReminderRepository _repository;
  const MarkReminderCompletedUseCase({required IReminderRepository repository})
      : _repository = repository;

  @override
  Future<void> execute(String reminderId) =>
      _repository.markCompleted(reminderId);
}
