/// @file user_remote_data_source.dart
/// @description Fuente de datos remota para el módulo de usuario.
/// Encapsula todas las llamadas HTTP al backend relacionadas con el perfil,
/// preferencias, contraseña, exportación y eliminación de cuenta.
/// Devuelve Maps crudos — el repositorio delega en UserMapper para las entidades.
/// @module User
/// @layer Data
library;

import '../../../core/network/api_client.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER REMOTE DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Datasource remoto para operaciones de usuario.
///
/// Endpoints cubiertos:
///  - GET /users/me                   → getMyProfile
///  - GET /users/:id                  → getUserById
///  - PUT /users/me                   → updateProfile
///  - PUT /users/me/preferences       → updatePreferences
///  - PUT /users/me/password          → changePassword
///  - DELETE /users/me                → deleteAccount
///  - GET /users/me/export            → exportData
///
/// [injectable] registrar en container.dart como singleton.
/// [dependencies] ApiClient.
class UserRemoteDataSource {
  final ApiClient _apiClient;

  const UserRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Perfil propio ────────────────────────────────────────────────────────────

  /// Obtiene el perfil completo del usuario autenticado.
  ///
  /// [returns]  — Map con los datos del usuario (estructura UserModel).
  /// [throws]   AppError.unauthorized si el token ha expirado.
  Future<Map<String, dynamic>> getMyProfile() async {
    return _apiClient.get<Map<String, dynamic>>('/users/me');
  }

  /// Obtiene el perfil público de un usuario por su [userId].
  ///
  /// [userId]   — MongoDB ObjectId del usuario.
  /// [returns]  — Map con los datos públicos del usuario.
  /// [throws]   AppError.notFound si el usuario no existe.
  Future<Map<String, dynamic>> getUserById(String userId) async {
    return _apiClient.get<Map<String, dynamic>>('/users/$userId');
  }

  // ─── Actualización de perfil ─────────────────────────────────────────────────

  /// Actualiza los datos de perfil del usuario autenticado.
  ///
  /// [body]     — Map con los campos a actualizar (name, bio, location, photo?).
  /// [returns]  — Map con el usuario actualizado.
  /// [throws]   AppError.validation si los datos no pasan validación del backend.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    return _apiClient.put<Map<String, dynamic>>('/users/me', data: body);
  }

  /// Actualiza las preferencias del usuario autenticado.
  ///
  /// [body]     — Map con las preferencias a actualizar.
  /// [returns]  — Map con el usuario actualizado.
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> body,
  ) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/users/me/preferences',
      data: body,
    );
  }

  // ─── Contraseña ───────────────────────────────────────────────────────────────

  /// Cambia la contraseña del usuario autenticado.
  ///
  /// [body]     — Map con {currentPassword, newPassword}.
  /// [throws]   AppError.validation si la contraseña actual es incorrecta.
  Future<void> changePassword(Map<String, dynamic> body) async {
    // NOTE: 204 No Content — <dynamic> evita TypeError al castear null a Map.
    await _apiClient.put<dynamic>('/users/me/password', data: body);
  }

  // ─── Cuenta ───────────────────────────────────────────────────────────────────

  /// Elimina (soft-delete) la cuenta del usuario autenticado.
  ///
  /// [body]     — Map con {password} para confirmar la eliminación.
  /// [throws]   AppError.validation si la contraseña es incorrecta.
  Future<void> deleteAccount(Map<String, dynamic> body) async {
    await _apiClient.delete<void>('/users/me', data: body);
  }

  /// Exporta los datos personales del usuario en formato JSON (RGPD).
  ///
  /// [returns]  — String con el JSON exportado.
  Future<String> exportData() async {
    final result = await _apiClient.get<Map<String, dynamic>>('/users/me/export');
    return result.toString();
  }

  // ─── FCM token ───────────────────────────────────────────────────────────────

  /// Desregistra el `fcmToken` del usuario autenticado en el backend.
  /// Llamado por LogoutUseCase durante el flujo de cierre profundo. El
  /// backend responde 204 No Content; `<dynamic>` evita el cast a Map.
  Future<void> deleteFcmToken() async {
    await _apiClient.delete<dynamic>('/users/me/fcm-token');
  }

  // ─── Búsqueda pública ────────────────────────────────────────────────────────

  /// Busca usuarios por nombre para el buscador público de Comunidad.
  /// El backend excluye privados para roles no admin y oculta al propio
  /// solicitante. Devuelve máx. 20 resultados con { id, name, photo }.
  ///
  /// [query]   — Texto a buscar (nombre).
  /// [returns] — Lista de mapas con los usuarios coincidentes.
  Future<List<dynamic>> searchUsers(String query) async {
    return _apiClient.get<List<dynamic>>(
      '/users/search?q=${Uri.encodeQueryComponent(query)}',
    );
  }
}
