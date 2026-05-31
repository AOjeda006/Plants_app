/// @file user_mapper.dart
/// @description Implementación del mapper de usuario.
/// Convierte UserModel ↔ User normalizando tipos y valores por defecto.
/// Toda la lógica de transformación vive aquí, nunca en el Model ni en la entidad.
/// @module Core
/// @layer Data
library;

import '../../core/utils/date_utils.dart';
import '../../domain/entities/user.dart';
import '../i_mappers/i_user_mapper.dart';
import '../models/user_model.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// USER MAPPER
// ═══════════════════════════════════════════════════════════════════════════════

/// Implementación de [IUserMapper].
///
/// [implements] IUserMapper
/// [injectable] registrar en container.dart como singleton.
class UserMapper implements IUserMapper {

  // ─── UserModel → User ─────────────────────────────────────────────────────────

  @override
  User toEntity(UserModel model) {
    return User(
      id:          model.id,
      name:        model.name,
      email:       model.email,
      role:        model.role,
      photo:       model.photo,
      bannerPhoto: model.bannerPhoto,
      bio:         model.bio,
      location:    model.location,
      locationLat: model.locationLat,
      locationLon: model.locationLon,
      fcmToken:    model.fcmToken,
      bannedUntil: model.bannedUntil != null
          ? PlantDateUtils.parseUtc(model.bannedUntil!)
          : null,
      createdAt:   PlantDateUtils.parseUtc(model.createdAt) ?? DateTime.now().toUtc(),
      preferences: model.preferences != null
          ? _toPreferences(model.preferences!)
          : null,
    );
  }

  // ─── User → UserModel ─────────────────────────────────────────────────────────

  @override
  UserModel toModel(User entity) {
    return UserModel(
      id:          entity.id,
      name:        entity.name,
      email:       entity.email,
      role:        entity.role,
      photo:       entity.photo,
      bannerPhoto: entity.bannerPhoto,
      bio:         entity.bio,
      location:    entity.location,
      locationLat: entity.locationLat,
      locationLon: entity.locationLon,
      fcmToken:    entity.fcmToken,
      bannedUntil: entity.bannedUntil != null
          ? PlantDateUtils.toIso8601(entity.bannedUntil!)
          : null,
      createdAt:   PlantDateUtils.toIso8601(entity.createdAt),
      preferences: entity.preferences != null
          ? _toPreferencesModel(entity.preferences!)
          : null,
    );
  }

  // ─── Helpers de preferencias ──────────────────────────────────────────────────

  UserPreferences _toPreferences(UserPreferencesModel model) {
    return UserPreferences(
      pushNotifications:    model.pushNotifications    ?? true,
      profilePublic:        model.profilePublic        ?? true,
      language:             model.language             ?? 'es',
    );
  }

  UserPreferencesModel _toPreferencesModel(UserPreferences prefs) {
    return UserPreferencesModel(
      pushNotifications:    prefs.pushNotifications,
      profilePublic:        prefs.profilePublic,
      language:             prefs.language,
    );
  }
}
