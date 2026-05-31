/// @file user_repository_impl.dart
/// @description Implementación del repositorio de usuario.
/// Orquesta UserRemoteDataSource y UserMapper para devolver entidades de dominio.
/// @module User
/// @layer Data
library;

import '../../domain/dtos/user/update_preferences_request_dto.dart';
import '../../domain/dtos/user/update_profile_request_dto.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../datasources/remote/user_remote_data_source.dart';
import '../i_mappers/i_user_mapper.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER REPOSITORY IMPL
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IUserRepository].
///
/// [implements] IUserRepository
/// [injectable] registrar en container.dart como lazySingleton.
/// [dependencies] UserRemoteDataSource, IUserMapper.
class UserRepositoryImpl implements IUserRepository {
  final UserRemoteDataSource _dataSource;
  final IUserMapper          _mapper;

  const UserRepositoryImpl({
    required UserRemoteDataSource dataSource,
    required IUserMapper          mapper,
  })  : _dataSource = dataSource,
        _mapper     = mapper;

  // ─── Perfil ───────────────────────────────────────────────────────────────────

  @override
  Future<User> getMyProfile() async {
    final json = await _dataSource.getMyProfile();
    return _mapper.toEntity(UserModel.fromJson(json));
  }

  @override
  Future<User> getUserById(String userId) async {
    final json = await _dataSource.getUserById(userId);
    return _mapper.toEntity(UserModel.fromJson(json));
  }

  @override
  Future<User> updateProfile(UpdateProfileRequestDto dto) async {
    final json = await _dataSource.updateProfile(dto.toJson());
    return _mapper.toEntity(UserModel.fromJson(json));
  }

  @override
  Future<User> updatePreferences(UpdatePreferencesRequestDto dto) async {
    final json = await _dataSource.updatePreferences(dto.toJson());
    return _mapper.toEntity(UserModel.fromJson(json));
  }

  // ─── Contraseña ───────────────────────────────────────────────────────────────

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dataSource.changePassword({
      'currentPassword': currentPassword,
      'newPassword':     newPassword,
    });
  }

  // ─── Cuenta ───────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteAccount(String password, {bool preserveContent = false}) async {
    await _dataSource.deleteAccount({
      'password':        password,
      'preserveContent': preserveContent,
    });
  }

  @override
  Future<String> exportData() async {
    return _dataSource.exportData();
  }

  // ─── FCM token ────────────────────────────────────────────────────────────────

  @override
  Future<void> deleteFcmToken() => _dataSource.deleteFcmToken();
}
