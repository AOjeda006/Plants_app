/// @file user_model.dart
/// @description Modelo de serialización del usuario para la capa de datos.
/// Solo responsable de fromJson/toJson. SIN lógica de negocio ni mapeo a entidad.
/// La conversión UserModel ↔ User la realiza UserMapper.
/// @module Core
/// @layer Data
library;

// ═══════════════════════════════════════════════════════════════════════════════
// USER MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización del usuario. Refleja la estructura JSON de la API.
///
/// Regla estricta: NO contiene lógica de negocio, validaciones ni referencias
/// a entidades de dominio. Solo fromJson y toJson.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.photo,
    this.bannerPhoto,
    this.bio,
    this.location,
    this.locationLat,
    this.locationLon,
    this.fcmToken,
    this.preferences,
    this.bannedUntil,
  });

  final String  id;
  final String  name;
  final String  email;
  final String  role;
  final String? photo;
  final String? bannerPhoto;
  final String? bio;
  final String? location;
  final double? locationLat;
  final double? locationLon;
  final String? fcmToken;
  final UserPreferencesModel? preferences;
  final String? bannedUntil; // ISO 8601 string, null si no está baneado.
  final String  createdAt; // ISO 8601 string tal como llega del servidor.

  // ─── Deserialización ─────────────────────────────────────────────────────────

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:          json['_id']       as String? ?? json['id'] as String,
    name:        json['name']      as String,
    email:       json['email']     as String,
    role:        json['role']      as String? ?? 'user',
    photo:       json['photo']       as String?,
    bannerPhoto: json['bannerPhoto'] as String?,
    bio:         json['bio']         as String?,
    location:    json['location']    as String?,
    locationLat: (json['locationLat'] as num?)?.toDouble(),
    locationLon: (json['locationLon'] as num?)?.toDouble(),
    fcmToken:    json['fcmToken']    as String?,
    bannedUntil: json['bannedUntil'] as String?,
    createdAt:   json['createdAt'] as String,
    preferences: json['preferences'] != null
        ? UserPreferencesModel.fromJson(
            json['preferences'] as Map<String, dynamic>,
          )
        : null,
  );

  // ─── Serialización ────────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'id':          id,
    'name':        name,
    'email':       email,
    'role':        role,
    if (photo       != null) 'photo':       photo,
    if (bannerPhoto != null) 'bannerPhoto': bannerPhoto,
    if (bio         != null) 'bio':         bio,
    if (location    != null) 'location':    location,
    if (locationLat != null) 'locationLat': locationLat,
    if (locationLon != null) 'locationLon': locationLon,
    if (fcmToken    != null) 'fcmToken':    fcmToken,
    if (preferences != null) 'preferences': preferences!.toJson(),
    if (bannedUntil != null) 'bannedUntil': bannedUntil,
    'createdAt':   createdAt,
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER PREFERENCES MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/// Modelo de serialización de las preferencias del usuario.
class UserPreferencesModel {
  const UserPreferencesModel({
    this.pushNotifications,
    this.profilePublic,
    this.language,
  });

  final bool?   pushNotifications;
  final bool?   profilePublic;
  final String? language;

  factory UserPreferencesModel.fromJson(Map<String, dynamic> json) =>
      UserPreferencesModel(
        pushNotifications:    json['pushNotifications']    as bool?,
        // El backend usa isPrivate (true=privado); el frontend usa profilePublic (true=público).
        profilePublic:        json['profilePublic']        as bool?
                           ?? !(json['isPrivate']          as bool? ?? false),
        language:             json['language']             as String?,
      );

  Map<String, dynamic> toJson() => {
    if (pushNotifications    != null) 'pushNotifications':    pushNotifications,
    if (profilePublic        != null) 'profilePublic':        profilePublic,
    if (language             != null) 'language':             language,
  };
}
