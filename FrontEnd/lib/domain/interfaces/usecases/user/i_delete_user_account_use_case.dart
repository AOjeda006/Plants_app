/// @file i_delete_user_account_use_case.dart
/// @description Interfaz: Elimina la cuenta del usuario (soft-delete).
/// @module User
/// @layer Domain
library;
abstract interface class IDeleteUserAccountUseCase {
  /// Elimina la cuenta del usuario (soft-delete).
  ///
  /// [param] password        — contraseña actual para confirmar la eliminación.
  /// [param] preserveContent — si true, las publicaciones y comentarios del usuario
  ///                           permanecen (anónimos); si false (default), se eliminan.
  Future<void> execute(String password, {bool preserveContent = false});
}
