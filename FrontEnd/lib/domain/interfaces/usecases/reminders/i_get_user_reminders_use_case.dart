/// @file i_get_user_reminders_use_case.dart
/// @description Interfaz del caso de uso para obtener los recordatorios del usuario.
/// @module Reminders
/// @layer Domain
library;

import '../../../entities/reminder.dart';

abstract interface class IGetUserRemindersUseCase {
  /// Devuelve los recordatorios activos del usuario autenticado.
  Future<List<Reminder>> execute();
}
