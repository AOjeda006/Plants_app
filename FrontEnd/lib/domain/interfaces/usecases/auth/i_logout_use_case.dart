/// @file i_logout_use_case.dart
/// @description Interfaz del caso de uso de cierre de sesión.
/// @module Core
/// @layer Domain
library;

/// Contrato del caso de uso de logout.
abstract interface class ILogoutUseCase {
  /// Cierra la sesión local: borra tokens del almacenamiento seguro.
  Future<void> execute();
}
