/// @file i_get_user_notifications_use_case.dart
/// @description Interfaz del caso de uso para obtener las notificaciones in-app del usuario.
/// @module Reminders
/// @layer Domain
library;

import '../../../entities/notification.dart';

/// Contrato del caso de uso para obtener notificaciones.
abstract interface class IGetUserNotificationsUseCase {
  /// Devuelve las notificaciones del usuario autenticado.
  ///
  /// [returns] Lista de AppNotification ordenada por fecha descendente.
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<List<AppNotification>> execute();
}
