/// @file update_preferences_request_dto.dart
/// @description DTO para actualizar las preferencias del usuario.
/// Todos los campos son opcionales — solo se envían los que cambian.
/// @module User
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// UPDATE PREFERENCES REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO de actualización de preferencias del usuario.
///
/// Todos los campos son opcionales. El backend aplica patch parcial.
///
/// El DTO no incluye el campo `language`: el idioma de la app vive solo
/// en el cliente (i18n esqueleto), no se persiste en el perfil del
/// usuario.
class UpdatePreferencesRequestDto {
  const UpdatePreferencesRequestDto({
    this.pushNotifications,
    this.profilePublic,
  });

  /// Habilita o deshabilita notificaciones push.
  final bool? pushNotifications;

  /// Hace el perfil público o privado en la comunidad.
  final bool? profilePublic;

  Map<String, dynamic> toJson() => {
    if (pushNotifications != null) 'pushNotifications': pushNotifications,
    // El backend usa isPrivate (inverso de profilePublic).
    if (profilePublic     != null) 'isPrivate':         !profilePublic!,
  };
}
