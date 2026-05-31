/// @file reminder_remote_data_source.dart
/// @description Fuente de datos remota para recordatorios de cuidado.
/// Encapsula todas las llamadas HTTP al módulo /reminders de la API.
/// Devuelve Maps crudos (los mappers convierten a entidades en el repositorio).
/// Lanza AppError en caso de fallo — propagado desde ApiClient.
/// @module Reminders
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// REMINDER REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para las operaciones de recordatorios.
///
/// Endpoints cubiertos:
///  - GET  /reminders               → getActiveReminders
///  - POST /reminders/:id/complete  → markCompleted
///
/// [injectable] registrar en container.dart.
/// [dependencies] ApiClient.
class ReminderRemoteDataSource {
  final ApiClient _apiClient;

  const ReminderRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Get active reminders ─────────────────────────────────────────────────────

  /// Devuelve los recordatorios activos del usuario autenticado.
  ///
  /// [returns] Lista de Maps con datos de recordatorio tal como los devuelve la API.
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    final result = await _apiClient.get<List<dynamic>>('/reminders');
    return result.cast<Map<String, dynamic>>();
  }

  // ─── Mark completed ───────────────────────────────────────────────────────────

  /// Marca el recordatorio con [reminderId] como completado.
  ///
  /// [throws] AppError.notFound si el recordatorio no existe o no pertenece al usuario.
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<void> markCompleted(String reminderId) async {
    await _apiClient.post<dynamic>('/reminders/$reminderId/complete');
  }
}
