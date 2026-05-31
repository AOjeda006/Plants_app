/// @file i_mark_notifications_read_use_case.dart
/// @description Interfaz del caso de uso para marcar todas las notificaciones como leídas.
/// @module Reminders
/// @layer Domain
library;

/// Contrato del caso de uso para marcar notificaciones como leídas.
abstract interface class IMarkNotificationsReadUseCase {
  /// Marca notificaciones como leídas.
  /// Si se proporcionan [ids], solo marca esas; si no, marca todas.
  ///
  /// [throws] AppError si hay error de red o el token es inválido.
  Future<void> execute({List<String>? ids});
}
