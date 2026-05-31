/// @file login_request_dto.dart
/// @description DTO de entrada para el caso de uso de login.
/// @module Core
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// LOGIN REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO de login. Usado por el ViewModel y el use case de autenticación.
class LoginRequestDto {
  const LoginRequestDto({
    required this.email,
    required this.password,
  });

  /// Email del usuario.
  final String email;

  /// Contraseña en texto plano.
  final String password;
}
