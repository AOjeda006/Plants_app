/// @file i_user_repository.dart
/// @description Interfaz del repositorio de usuario.
/// Define el contrato que los use cases usan para acceder a datos de usuario.
/// Los use cases dependen de esta abstracción, nunca de la implementación concreta.
/// @module User
/// @layer Domain
library;

import '../entities/user.dart';
import '../dtos/user/update_profile_request_dto.dart';
import '../dtos/user/update_preferences_request_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I USER REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del repositorio de usuario.
///
/// Implementado por [UserRepositoryImpl] en la capa de datos.
abstract interface class IUserRepository {
  /// Obtiene el perfil completo del usuario autenticado.
  ///
  /// [throws] AppError.unauthorized si el token ha expirado.
  Future<User> getMyProfile();

  /// Obtiene el perfil público de un usuario por su [userId].
  ///
  /// [throws] AppError.notFound si el usuario no existe.
  Future<User> getUserById(String userId);

  /// Actualiza los datos de perfil del usuario autenticado.
  ///
  /// [returns] el usuario con los datos actualizados.
  Future<User> updateProfile(UpdateProfileRequestDto dto);

  /// Actualiza las preferencias del usuario autenticado.
  ///
  /// [returns] el usuario con las preferencias actualizadas.
  Future<User> updatePreferences(UpdatePreferencesRequestDto dto);

  /// Cambia la contraseña del usuario autenticado.
  ///
  /// [throws] AppError.validation si la contraseña actual es incorrecta.
  Future<void> changePassword(String currentPassword, String newPassword);

  /// Elimina (soft-delete) la cuenta del usuario autenticado.
  ///
  /// [param] preserveContent — si true, las publicaciones/comentarios permanecen (anónimos).
  /// [throws] AppError.validation si la contraseña es incorrecta.
  Future<void> deleteAccount(String password, {bool preserveContent = false});

  /// Exporta los datos personales del usuario (RGPD).
  ///
  /// [returns] JSON string con todos los datos del usuario.
  Future<String> exportData();

  /// Desregistra el `fcmToken` del usuario autenticado en el backend.
  /// Llamada típicamente desde el flujo de logout profundo para evitar
  /// que push asociadas a una sesión cerrada lleguen al dispositivo.
  /// Idempotente: si ya estaba vacío, el backend responde 204 igualmente.
  ///
  /// [throws] AppError.network si no hay conexión (el caller decide si
  ///                            silenciarlo — en logout sí se silencia).
  Future<void> deleteFcmToken();
}
