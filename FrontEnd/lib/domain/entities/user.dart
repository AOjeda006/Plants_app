/// @file user.dart
/// @description Entidad de dominio User. Representa un usuario autenticado de la app.
/// Es un objeto puro de Dart, sin dependencias de Flutter ni de paquetes externos.
/// Los mappers se encargan de convertir UserModel ↔ User.
/// @module Core
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// USER ENTITY
// ═══════════════════════════════════════════════════════════════════════════════

/// Entidad de dominio que representa a un usuario de la aplicación.
///
/// Todos los campos son inmutables (final). Usar [copyWith] para actualizaciones.
/// Sin lógica de serialización — eso pertenece a UserModel (data layer).
class User {
  const User({
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

  /// Identificador único del usuario (MongoDB ObjectId como String).
  final String id;

  /// Nombre visible del usuario.
  final String name;

  /// Email del usuario (único en el sistema).
  final String email;

  /// Rol del usuario en el sistema: 'user' | 'admin'.
  final String role;

  /// URL de la foto de perfil (Cloudinary), o null si no tiene.
  final String? photo;

  /// URL de la imagen de banner/fondo de perfil (Cloudinary), o null si no tiene.
  final String? bannerPhoto;

  /// Biografía corta del usuario, o null si no la ha completado.
  final String? bio;

  /// Ubicación del usuario (ej. "Sevilla, España"), o null.
  final String? location;

  /// Latitud geográfica de la ubicación del usuario (capital de provincia España), o null.
  final double? locationLat;

  /// Longitud geográfica de la ubicación del usuario (capital de provincia España), o null.
  final double? locationLon;

  /// Token FCM para notificaciones push, o null si FCM no está habilitado.
  final String? fcmToken;

  /// Preferencias del usuario (unidades, notificaciones, privacidad).
  final UserPreferences? preferences;

  /// Fecha hasta la que el usuario está suspendido (null si no está baneado).
  final DateTime? bannedUntil;

  /// Fecha de creación de la cuenta.
  final DateTime createdAt;

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  /// true si el usuario tiene rol de administrador.
  bool get isAdmin => role == 'admin';

  /// true si el usuario puede recibir notificaciones push.
  bool get canReceiveNotifications =>
      fcmToken != null && fcmToken!.isNotEmpty;

  /// true si el perfil está considerado "completo" (tiene foto y bio).
  bool get hasCompleteProfile => photo != null && bio != null;

  /// true si el usuario está actualmente baneado.
  bool get isBanned => bannedUntil != null && bannedUntil!.isAfter(DateTime.now());

  // ─── copyWith ────────────────────────────────────────────────────────────────

  /// Devuelve una copia del usuario con los campos indicados modificados.
  User copyWith({
    String?           id,
    String?           name,
    String?           email,
    String?           role,
    String?           photo,
    String?           bannerPhoto,
    String?           bio,
    String?           location,
    double?           locationLat,
    double?           locationLon,
    String?           fcmToken,
    UserPreferences?  preferences,
    DateTime?         bannedUntil,
    DateTime?         createdAt,
  }) {
    return User(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      email:       email       ?? this.email,
      role:        role        ?? this.role,
      photo:       photo       ?? this.photo,
      bannerPhoto: bannerPhoto ?? this.bannerPhoto,
      bio:         bio         ?? this.bio,
      location:    location    ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLon: locationLon ?? this.locationLon,
      fcmToken:    fcmToken    ?? this.fcmToken,
      preferences: preferences ?? this.preferences,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      createdAt:   createdAt   ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER PREFERENCES
// ═══════════════════════════════════════════════════════════════════════════════

/// Preferencias personalizables del usuario.
class UserPreferences {
  const UserPreferences({
    this.pushNotifications   = true,
    this.profilePublic       = true,
    this.language            = 'es',
  });

  /// true si el usuario acepta notificaciones push.
  final bool pushNotifications;

  /// true si el perfil es visible para otros usuarios (comunidad).
  final bool profilePublic;

  /// Código de idioma preferido: 'es', 'en', etc.
  final String language;

  UserPreferences copyWith({
    bool?   pushNotifications,
    bool?   profilePublic,
    String? language,
  }) {
    return UserPreferences(
      pushNotifications:    pushNotifications    ?? this.pushNotifications,
      profilePublic:        profilePublic        ?? this.profilePublic,
      language:             language             ?? this.language,
    );
  }
}
