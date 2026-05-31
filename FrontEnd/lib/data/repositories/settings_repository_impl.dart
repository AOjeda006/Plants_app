/// @file settings_repository_impl.dart
/// @description Implementación del repositorio de ajustes.
/// Delega en UserRemoteDataSource para persistir preferencias en el backend.
/// Extrae las preferencias del objeto User devuelto por el endpoint.
/// @module Settings
/// @layer Data
library;

import '../../domain/dtos/user/update_preferences_request_dto.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_settings_repository.dart';
import '../datasources/remote/user_remote_data_source.dart';
import '../i_mappers/i_user_mapper.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SETTINGS REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [ISettingsRepository].
///
/// Reutiliza [UserRemoteDataSource] — las preferencias se gestionan a través
/// del mismo endpoint de perfil (/users/me/preferences).
///
/// [implements] ISettingsRepository
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] UserRemoteDataSource, IUserMapper.
class SettingsRepositoryImpl implements ISettingsRepository {
  final UserRemoteDataSource _dataSource;
  final IUserMapper          _mapper;

  const SettingsRepositoryImpl({
    required UserRemoteDataSource dataSource,
    required IUserMapper          mapper,
  })  : _dataSource = dataSource,
        _mapper     = mapper;

  // ─── Preferencias ────────────────────────────────────────────────────────────

  @override
  Future<UserPreferences> getPreferences() async {
    final json = await _dataSource.getMyProfile();
    final user = _mapper.toEntity(UserModel.fromJson(json));
    // Si el backend devuelve preferencias nulas, usamos los valores por defecto.
    return user.preferences ?? const UserPreferences();
  }

  @override
  Future<UserPreferences> updatePreferences(UpdatePreferencesRequestDto dto) async {
    final json = await _dataSource.updatePreferences(dto.toJson());
    final user = _mapper.toEntity(UserModel.fromJson(json));
    return user.preferences ?? const UserPreferences();
  }
}
