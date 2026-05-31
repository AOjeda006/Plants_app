/// @file notification_remote_data_source.dart
/// @description Fuente de datos remota para notificaciones in-app.
/// Encapsula todas las llamadas HTTP al módulo /notifications de la API.
/// Devuelve Maps crudos (los mappers convierten a entidades en el repositorio).
/// Lanza AppError en caso de fallo — propagado desde ApiClient.
/// @module Reminders
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para las operaciones de notificaciones in-app.
///
/// Endpoints cubiertos:
///  - GET    /notifications      → getUserNotifications
///  - PUT    /notifications/read → markAllRead
///  - DELETE /notifications      → deleteAll
///
/// [injectable] registrar en container.dart.
/// [dependencies] ApiClient.
class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  const NotificationRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Get user notifications ────────────────────────────────────────────────

  /// Devuelve las notificaciones del usuario autenticado.
  ///
  /// [returns] Lista de Maps con datos de notificación tal como los devuelve la API.
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<List<Map<String, dynamic>>> getUserNotifications() async {
    final result = await _apiClient.get<List<dynamic>>('/notifications');
    return result.cast<Map<String, dynamic>>();
  }

  // ─── Mark all read ─────────────────────────────────────────────────────────

  /// Marca notificaciones del usuario como leídas.
  /// Si se proporcionan [ids], solo marca esas; si no, marca todas.
  ///
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<void> markAllRead({List<String>? ids}) async {
    await _apiClient.put<dynamic>(
      '/notifications/read',
      data: ids != null ? {'ids': ids} : null,
    );
  }

  // ─── Delete all ────────────────────────────────────────────────────────────

  /// Elimina notificaciones del usuario.
  /// Si se proporcionan [ids], solo elimina esas; si no, elimina todas.
  ///
  /// [throws] AppError.unauthorized si el token es inválido o ha expirado.
  Future<void> deleteAll({List<String>? ids}) async {
    await _apiClient.delete<dynamic>(
      '/notifications',
      data: ids != null ? {'ids': ids} : null,
    );
  }
}
