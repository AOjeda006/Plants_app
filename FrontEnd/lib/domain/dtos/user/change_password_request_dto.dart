/// @file change_password_request_dto.dart
/// @description DTO para cambio de contraseña del usuario.
/// @module User
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// CHANGE PASSWORD REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO de cambio de contraseña.
class ChangePasswordRequestDto {
  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'currentPassword': currentPassword,
    'newPassword':     newPassword,
  };
}
