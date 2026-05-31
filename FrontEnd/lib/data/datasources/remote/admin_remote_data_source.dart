/// @file admin_remote_data_source.dart
/// @description Fuente de datos remota para el módulo de administración.
/// Encapsula las llamadas HTTP a los endpoints /admin/* del backend.
/// Solo accesible para usuarios con rol 'admin'.
/// @module Admin
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// ADMIN REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para operaciones de administración.
///
/// Endpoints cubiertos:
///  - GET  /admin/reports          → getReports
///  - GET  /admin/deleted-items    → getDeletedItems
///  - POST /admin/restore/:type/:id → restoreItem
///  - GET  /admin/diagnostics      → getDiagnostics
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] ApiClient.
class AdminRemoteDataSource {
  final ApiClient _apiClient;

  const AdminRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Búsqueda de usuarios ─────────────────────────────────────────────────

  /// Busca usuarios por nombre o email (solo admin).
  ///
  /// [query] — Texto de búsqueda (regex case-insensitive en backend).
  /// [returns] Lista de mapas con id, name, email, photo.
  Future<List<dynamic>> searchUsers(String query) async {
    return _apiClient.get<List<dynamic>>('/admin/users/search?q=${Uri.encodeQueryComponent(query)}');
  }

  // ─── Ban y avisos ────────────────────────────────────────────────────────

  /// Banea temporalmente a un usuario (solo admin).
  ///
  /// [userId]   — ID del usuario a banear.
  /// [duration] — Duración del baneo en días.
  Future<void> banUser(String userId, int duration) async {
    await _apiClient.put<dynamic>(
      '/admin/users/$userId/ban',
      data: { 'duration': duration },
    );
  }

  /// Envía un aviso/notificación a un usuario (solo admin).
  ///
  /// [userId]  — ID del usuario.
  /// [message] — Texto del aviso.
  Future<void> warnUser(String userId, String message) async {
    await _apiClient.put<dynamic>(
      '/admin/users/$userId/warn',
      data: { 'message': message },
    );
  }

  // ─── Reportes ─────────────────────────────────────────────────────────────

  /// Obtiene los reportes de la plataforma (usuarios, plantas, posts).
  ///
  /// [returns] Map con estadísticas agregadas.
  /// [throws]  AppError.unauthorized si el usuario no es admin.
  Future<Map<String, dynamic>> getReports() async {
    return _apiClient.get<Map<String, dynamic>>('/admin/reports');
  }

  // ─── Elementos eliminados ─────────────────────────────────────────────────

  /// Obtiene la lista de elementos eliminados (soft-delete).
  ///
  /// [returns] Map con listas de usuarios, plantas y posts eliminados.
  Future<Map<String, dynamic>> getDeletedItems() async {
    return _apiClient.get<Map<String, dynamic>>('/admin/deleted-items');
  }

  /// Restaura un elemento eliminado.
  ///
  /// [type]   — tipo de entidad: 'user' | 'plant' | 'post'.
  /// [itemId] — ID del elemento a restaurar.
  Future<void> restoreItem(String type, String itemId) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/admin/restore/$type/$itemId',
    );
  }

  // ─── Diagnóstico ──────────────────────────────────────────────────────────

  /// Obtiene el diagnóstico del sistema (uptime, memoria, DB status, etc.).
  ///
  /// [returns] Map con datos de diagnóstico del servidor.
  Future<Map<String, dynamic>> getDiagnostics() async {
    return _apiClient.get<Map<String, dynamic>>('/admin/diagnostics');
  }

  // ─── Reportes de incidencias ──────────────────────────────────────────────

  /// Obtiene la lista de reportes de incidencias (solo admin).
  /// Soporta filtros opcionales por ticketNumber, status y rango de fechas.
  ///
  /// [ticketNumber] — Filtrar por número de ticket exacto.
  /// [status]       — 'pending' | 'resolved' | 'dismissed'.
  /// [from]         — Fecha inicio (ISO 8601).
  /// [to]           — Fecha fin (ISO 8601).
  /// [returns] Lista de reportes serializados.
  Future<List<dynamic>> getIncidentReports({
    int?    ticketNumber,
    String? status,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (ticketNumber != null) params['ticketNumber'] = '$ticketNumber';
    if (status != null)       params['status']       = status;
    if (from != null)         params['from']         = from;
    if (to != null)           params['to']           = to;

    final query = params.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    final path = query.isEmpty
        ? '/admin/incident-reports'
        : '/admin/incident-reports?$query';

    return _apiClient.get<List<dynamic>>(path);
  }

  /// Actualiza el estado de un reporte (solo admin).
  /// Acepta 'resolved', 'dismissed' o 'pending' (reabrir).
  ///
  /// [reportId] — ID del reporte.
  /// [status]   — 'resolved' | 'dismissed' | 'pending'.
  Future<void> resolveReport(String reportId, String status) async {
    await _apiClient.put<dynamic>(
      '/admin/incident-reports/$reportId',
      data: { 'status': status },
    );
  }

  /// Elimina un post por admin (soft-delete + notificación al propietario).
  ///
  /// [postId] — ID del post a eliminar.
  Future<void> deletePost(String postId) async {
    await _apiClient.delete<dynamic>('/admin/posts/$postId');
  }

  /// Elimina un comentario por admin (soft-delete + decrementa commentsCount + notificación).
  ///
  /// [commentId] — ID del comentario a eliminar.
  Future<void> deleteComment(String commentId) async {
    await _apiClient.delete<dynamic>('/admin/comments/$commentId');
  }

  // ─── Cron ─────────────────────────────────────────────────────────────────

  /// Ejecuta el procesamiento completo de recordatorios bajo demanda.
  ///
  /// [returns] Map con message, startedAt, finishedAt, durationMs.
  /// [throws]  AppError.unauthorized si el usuario no es admin.
  Future<Map<String, dynamic>> runCron() async {
    return _apiClient.post<Map<String, dynamic>>('/admin/run-cron');
  }

  /// Simula lluvia para todas las plantas activas, generando notificaciones de riego.
  ///
  /// [returns] Map con message, triggeredAt, count, notifications.
  Future<Map<String, dynamic>> simulateRain() async {
    return _apiClient.post<Map<String, dynamic>>('/admin/simulate-rain');
  }

  /// Simula tormenta para todas las plantas activas, generando alertas de protección.
  ///
  /// [returns] Map con message, triggeredAt, count, notifications.
  Future<Map<String, dynamic>> simulateStorm() async {
    return _apiClient.post<Map<String, dynamic>>('/admin/simulate-storm');
  }

  /// Crea un reporte de incidencia (cualquier usuario autenticado).
  ///
  /// [text]     — Descripción de la incidencia.
  /// [type]     — 'general' | 'post' | 'comment'.
  /// [imageUrl] — URL de imagen adjunta (opcional).
  Future<void> createReport({
    required String text,
    String  type     = 'general',
    String? targetId,
    String? imageUrl,
  }) async {
    await _apiClient.post<Map<String, dynamic>>(
      '/reports',
      data: {
        'type': type,
        'text': text,
        'targetId': ?targetId,
        'imageUrl': ?imageUrl,
      },
    );
  }
}
