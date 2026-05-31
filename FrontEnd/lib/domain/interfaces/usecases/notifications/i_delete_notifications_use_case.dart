/// @file i_delete_notifications_use_case.dart
/// @description Interfaz del caso de uso para eliminar todas las notificaciones del usuario.
/// @module Reminders
/// @layer Domain
library;

/// Contrato del caso de uso para eliminar notificaciones.
abstract interface class IDeleteNotificationsUseCase {
  /// Elimina notificaciones del usuario autenticado.
  /// Si se proporcionan [ids], solo elimina esas; si no, elimina todas.
  ///
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<void> execute({List<String>? ids});
}
