/// @file auth_local_data_source.dart
/// @description Fuente de datos local para tokens de autenticación.
/// Usa flutter_secure_storage para persistir el access token de forma cifrada.
/// Es la única pieza que conoce SecureStorage; el resto de la app accede
/// al token a través del tokenProvider inyectado en ApiClient y SocketClient.
/// @module Core
/// @layer Core
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CLAVES DE ALMACENAMIENTO
// ═══════════════════════════════════════════════════════════════════════════════

/// Claves utilizadas en SecureStorage. Centralizar aquí evita typos dispersos.
abstract final class _Keys {
  static const String accessToken  = 'auth_access_token';
  static const String refreshToken = 'auth_refresh_token';
  static const String userId       = 'auth_user_id';
}

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH LOCAL DATA SOURCE
// ═══════════════════════════════════════════════════════════════════════════════

/// Gestiona la persistencia local de la sesión del usuario.
///
/// Almacena de forma cifrada:
///  - Access token JWT.
///  - Refresh token JWT (reservado para futura renovación silenciosa).
///  - ID del usuario autenticado.
///
/// TFG: incluye caché en memoria para compensar el bug de flutter_secure_storage
/// en Chrome Web (OperationError al descifrar con Web Crypto API). El caché
/// garantiza que el token esté disponible en la sesión actual aunque el storage
/// cifrado falle al leer.
///
/// [injectable] registrar en container.dart como singleton.
class AuthLocalDataSource {
  final FlutterSecureStorage _storage;

  // TFG: caché en memoria — workaround para flutter_secure_storage web
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedUserId;

  AuthLocalDataSource({
    FlutterSecureStorage? storage,
  }) : _storage = storage ??
           const FlutterSecureStorage(
             aOptions: AndroidOptions(encryptedSharedPreferences: true),
           );

  // ─── Guardar sesión ───────────────────────────────────────────────────────────

  /// Persiste los tokens y el userId tras un login o register exitoso.
  /// Actualiza el caché en memoria antes de intentar escribir en storage.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    // Actualizar caché primero — garantiza disponibilidad inmediata en web
    _cachedAccessToken  = accessToken;
    _cachedRefreshToken = refreshToken ?? _cachedRefreshToken;
    _cachedUserId       = userId       ?? _cachedUserId;

    try {
      await Future.wait([
        _storage.write(key: _Keys.accessToken,  value: accessToken),
        if (refreshToken != null)
          _storage.write(key: _Keys.refreshToken, value: refreshToken),
        if (userId != null)
          _storage.write(key: _Keys.userId,      value: userId),
      ]);
    } catch (_) {
      // TFG: en web el write puede fallar; el caché en memoria es suficiente
    }
  }

  // ─── Leer tokens ──────────────────────────────────────────────────────────────

  /// Devuelve el access token guardado, o null si no hay sesión activa.
  ///
  /// Prioridad: caché en memoria → flutter_secure_storage.
  ///
  /// Si la lectura falla (bug Web Crypto en Chrome, KeyStore aún no
  /// listo en Android tras arranque frío, ROMs custom Samsung/MIUI con
  /// race conditions), devuelve null sin destruir el storage.
  ///
  /// Importante: NUNCA llamar a `_storage.deleteAll()` en el catch — si
  /// el cifrado tropieza con una excepción transitoria y borramos los
  /// tokens, perdemos la sesión hasta el siguiente login. Mantener los
  /// datos en disco permite que un retry posterior los recupere cuando
  /// el KeyStore vuelve a estar disponible.
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;
    try {
      final value = await _storage.read(key: _Keys.accessToken);
      _cachedAccessToken = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el refresh token guardado, o null si no se persistió.
  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null) return _cachedRefreshToken;
    try {
      final value = await _storage.read(key: _Keys.refreshToken);
      _cachedRefreshToken = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el ID del usuario autenticado, o null si no hay sesión.
  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    try {
      final value = await _storage.read(key: _Keys.userId);
      _cachedUserId = value;
      return value;
    } catch (_) {
      return null;
    }
  }

  /// true si existe un access token en almacenamiento (no valida expiración).
  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ─── Eliminar sesión ──────────────────────────────────────────────────────────

  /// Borra todos los tokens y datos de sesión (logout o re-auth forzado).
  Future<void> clear() async {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    _cachedUserId       = null;
    try {
      await Future.wait([
        _storage.delete(key: _Keys.accessToken),
        _storage.delete(key: _Keys.refreshToken),
        _storage.delete(key: _Keys.userId),
      ]);
    } catch (_) {
      // TFG: si el storage ya está corrupto, ignorar el error de delete
    }
  }
}
