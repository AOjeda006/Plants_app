/// @file i_change_password_use_case.dart
/// @description Interfaz: Cambia la contraseña del usuario.
/// @module User
/// @layer Domain
library;
abstract interface class IChangePasswordUseCase {
  /// Cambia la contraseña del usuario.
  Future<void> execute(String currentPassword, String newPassword);
}
