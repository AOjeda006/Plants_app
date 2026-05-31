/// @file register_request_dto.dart
/// @description DTO de entrada para el caso de uso de registro de usuario.
/// Encapsula y valida los datos del formulario antes de pasarlos al use case.
/// @module Core
/// @layer Domain
library;

// ═══════════════════════════════════════════════════════════════════════════════
// REGISTER REQUEST DTO
// ═══════════════════════════════════════════════════════════════════════════════

/// DTO de registro de usuario. Usado por el ViewModel y el use case de registro.
class RegisterRequestDto {
  const RegisterRequestDto({
    required this.name,
    required this.email,
    required this.password,
  });

  /// Nombre visible del nuevo usuario.
  final String name;

  /// Email del nuevo usuario (debe ser único en el sistema).
  final String email;

  /// Contraseña en texto plano (el backend la hashea con bcrypt).
  final String password;
}
