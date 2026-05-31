/// @file logout_use_case.dart
/// @description Caso de uso de cierre de sesión profundo.
///
/// Ejecuta en orden tolerante a fallos:
///  1. Desregistrar `fcmToken` en el backend (`DELETE /users/me/fcm-token`).
///  2. Desconectar el socket Socket.IO.
///  3. Limpiar la caché Hive `cache`.
///  4. Limpiar tokens JWT de secure_storage.
///
/// El `FirebaseMessaging.deleteToken()` local NO se invoca a propósito:
/// provocaría que la siguiente sesión encontrase `getToken()==null` y se
/// quedara sin push durante varios segundos hasta que Firebase regenere
/// el token. La desasociación del token en el dispositivo respecto a la
/// cuenta cerrada ya la cubre el backend.
/// @module Core
/// @layer Domain
library;

import 'package:flutter/foundation.dart';

import '../../../core/network/socket_client.dart';
import '../../../core/storage/cache_local_data_source.dart';
import '../../interfaces/usecases/auth/i_logout_use_case.dart';
import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_user_repository.dart';

/// [implements] ILogoutUseCase
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] IAuthRepository, IUserRepository, SocketClient,
///                CacheLocalDataSource.
///
/// El logout profundo deja la app en un estado equivalente al primer
/// arranque tras instalación: sin tokens JWT, sin caché de plantas/posts
/// y sin sesión socket. El `fcmToken` local de Firebase se conserva
/// intacto para que la siguiente sesión pueda registrarlo de inmediato.
/// Cada paso está en su propio try/catch — un fallo en uno NO debe
/// impedir los siguientes (p.ej. si no hay red, los pasos remotos
/// fallan pero los locales sí limpian el estado).
class LogoutUseCase implements ILogoutUseCase {
  final IAuthRepository       _authRepo;
  final IUserRepository       _userRepo;
  final SocketClient          _socket;
  final CacheLocalDataSource  _cache;

  const LogoutUseCase({
    required IAuthRepository      authRepository,
    required IUserRepository      userRepository,
    required SocketClient         socketClient,
    required CacheLocalDataSource cache,
  })  : _authRepo  = authRepository,
        _userRepo  = userRepository,
        _socket    = socketClient,
        _cache     = cache;

  @override
  Future<void> execute() async {
    // 1. Desregistrar fcmToken en el backend (tolerante a fallo).
    try {
      await _userRepo.deleteFcmToken();
      debugPrint('[LogoutUseCase] DELETE /users/me/fcm-token ok');
    } catch (e) {
      debugPrint('[LogoutUseCase] DELETE fcm-token failed (silencioso): $e');
    }

    // 2. Desconectar socket: el JWT actual quedará invalidado y mantener
    //    la conexión generaría reconexiones inútiles con backoff.
    try {
      _socket.disconnect();
      debugPrint('[LogoutUseCase] SocketClient.disconnect ok');
    } catch (e) {
      debugPrint('[LogoutUseCase] socket.disconnect failed (silencioso): $e');
    }

    // 3. Limpiar caja Hive `cache` (plantas, posts, etc.). Si en el
    //    futuro se añaden más cajas, ampliar este paso.
    try {
      await _cache.clearAll();
      debugPrint('[LogoutUseCase] CacheLocalDataSource.clearAll ok');
    } catch (e) {
      debugPrint('[LogoutUseCase] cache.clearAll failed (silencioso): $e');
    }

    // 4. Limpiar tokens JWT de secure_storage (vía repositorio de auth).
    try {
      await _authRepo.logout();
      debugPrint('[LogoutUseCase] AuthRepository.logout (secure_storage) ok');
    } catch (e) {
      debugPrint('[LogoutUseCase] authRepo.logout failed: $e');
      rethrow;
    }
  }
}
