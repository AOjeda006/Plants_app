/// @file i_settings_repository.dart
/// @description Interfaz del repositorio de ajustes de la app.
/// Gestiona preferencias del usuario almacenadas remotamente (backend) o localmente.
/// @module Settings
/// @layer Domain
library;

import '../entities/user.dart';
import '../dtos/user/update_preferences_request_dto.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// I SETTINGS REPOSITORY
// ═══════════════════════════════════════════════════════════════════════════════

/// Contrato del repositorio de ajustes.
///
/// Implementado por [SettingsRepositoryImpl] en la capa de datos.
abstract interface class ISettingsRepository {
  /// Obtiene las preferencias actuales del usuario autenticado.
  ///
  /// [throws] AppError.unauthorized si el token ha expirado.
  Future<UserPreferences> getPreferences();

  /// Actualiza las preferencias del usuario en el backend.
  ///
  /// [returns] las preferencias actualizadas.
  Future<UserPreferences> updatePreferences(UpdatePreferencesRequestDto dto);
}
