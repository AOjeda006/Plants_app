/// @file update_profile_request_dto.dart
/// @description DTO para actualizar el perfil del usuario.
/// Todos los campos son opcionales — solo se envían los que cambian.
/// @module User
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE PROFILE REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO de actualización de perfil del usuario.
class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({
    this.name,
    this.bio,
    this.location,
    this.locationLat,
    this.locationLon,
    this.photo,
    this.bannerPhoto,
  });

  final String? name;
  final String? bio;
  final String? location;

  /// Latitud de la capital de provincia seleccionada.
  final double? locationLat;

  /// Longitud de la capital de provincia seleccionada.
  final double? locationLon;

  /// URL Cloudinary de la nueva foto de perfil, o null si no cambia.
  final String? photo;

  /// URL Cloudinary del banner/fondo de perfil, o null si no cambia.
  final String? bannerPhoto;

  Map<String, dynamic> toJson() => {
    if (name        != null) 'name':        name,
    if (bio         != null) 'bio':         bio,
    if (location    != null) 'location':    location,
    if (locationLat != null) 'locationLat': locationLat,
    if (locationLon != null) 'locationLon': locationLon,
    if (photo       != null) 'photo':       photo,
    if (bannerPhoto != null) 'bannerPhoto': bannerPhoto,
  };
}
