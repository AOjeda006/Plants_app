/// @file get_user_reminders_use_case.dart
/// @description Implementación del caso de uso para obtener los recordatorios del usuario.
/// @module Reminders
/// @layer Domain
library;

import '../../entities/reminder.dart';
import '../../interfaces/usecases/reminders/i_get_user_reminders_use_case.dart';
import '../../repositories/i_reminder_repository.dart';

/// [implements] IGetUserRemindersUseCase
/// [dependencies] IReminderRepository
class GetUserRemindersUseCase implements IGetUserRemindersUseCase {
  final IReminderRepository _repository;
  const GetUserRemindersUseCase({required IReminderRepository repository})
      : _repository = repository;

  @override
  Future<List<Reminder>> execute() => _repository.getActiveReminders();
}
